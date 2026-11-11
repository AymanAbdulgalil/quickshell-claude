#!/usr/bin/env python3
"""Writes ~/.config/hypr/hyprland.lua from Settings > Hyprland. Reads the model as JSON on stdin (hyprland.json).

The new file is checked with `Hyprland --verify-config` before it replaces the live one, so a bad value cannot break
the next login. Prints what is wrong on stderr and exits 1 when the check fails. Your own Lua goes in user.lua.
"""
import json
import os
import shutil
import subprocess
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
from luagen import config_calls, lua  # noqa: E402

HYPR = os.path.join(os.environ["HOME"], ".config/hypr")
TARGET = os.path.join(HYPR, "hyprland.lua")
BACKUP = TARGET + ".pre-gui"
MARK = "Written by Quickshell's Settings > Hyprland."

# How each kind of keybind action is written. {} is the argument.
ACTIONS = {
    "exec": lambda a: f"hl.dsp.exec_cmd({lua(a)})",
    "global": lambda a: f"hl.dsp.global({lua(a)})",
    # A Quickshell panel holding the keyboard catches the close key; otherwise it closes the window (2026-11-10).
    "close": lambda a: "quickshell_close",
    # Window controls do nothing while a panel is open (2026-11-11): quickshell_guard wraps them.
    "float": lambda a: guard('hl.dsp.window.float({ action = "toggle" })'),
    "pseudo": lambda a: guard("hl.dsp.window.pseudo()"),
    "split": lambda a: guard('hl.dsp.layout("togglesplit")'),
    "exit": lambda a: "hl.dsp.exit()",
    "focusDirection": lambda a: guard(f"hl.dsp.focus({{ direction = {lua(a)} }})"),
    "focusWorkspace": lambda a: f"hl.dsp.focus({{ workspace = {workspace(a)} }})",
    "moveToWorkspace": lambda a: guard(f"hl.dsp.window.move({{ workspace = {workspace(a)} }})"),
    "special": lambda a: f"hl.dsp.workspace.toggle_special({lua(a)})",
    "drag": lambda a: "hl.dsp.window.drag()",
    "resize": lambda a: "hl.dsp.window.resize()",
    "lua": lambda a: a,
}


def guard(dispatcher):
    return f"quickshell_guard({dispatcher})"


def workspace(a):
    text = str(a)
    return text if text.lstrip("-").isdigit() else lua(text)


def bind(b):
    flags = {k: True for k in ("locked", "repeating", "release", "mouse") if b.get(k)}
    action = ACTIONS[b["kind"]](b.get("arg", ""))
    extra = f", {lua(flags)}" if flags else ""
    return f"hl.bind({lua(b['keys'])}, {action}{extra})"


def rule(function, r):
    match = {k: v for k, v in r.get("match", {}).items() if v}
    effects = r.get("effects", "").strip()
    body = f"name = {lua(r['name'])}, match = {lua(match)}" + (f", {effects}" if effects else "")
    return f"{function}({{ {body} }})"


def render(m):
    out = [f"-- {MARK}", "-- Change it there. Lua of your own goes in user.lua, in this folder, which is read last.", ""]
    for mon in m.get("monitors", []):
        out.append(f"hl.monitor({lua(mon)})")
    for name, value in m.get("env", []):
        out.append(f"hl.env({lua(name)}, {lua(value)})")

    out += ["", 'hl.on("hyprland.start", function()',
            '    hl.exec_cmd("systemctl --user start hyprpolkitagent")',
            "    -- The active preset's wallpaper, from theme.lua.",
            '    local wallpaper = quickshell_wallpaper or (os.getenv("HOME") .. "/.local/share/backgrounds/arctic_mountains.jpg")',
            '    local background = quickshell_background or "000000"',
            '''    -- Starts on the color the login screen faded to, then the wallpaper fades in.''',
            '''    hl.exec_cmd("awww-daemon & until awww query >/dev/null 2>&1; do sleep 0.1; done; awww clear " .. background .. "; awww img --transition-type fade --transition-duration 0.8 --transition-fps 60 '" .. wallpaper:gsub("'", "'\\\\''") .. "'")''',
            '    hl.exec_cmd("quickshell")']
    for command in m.get("autostart", []):
        out.append(f"    hl.exec_cmd({lua(command)})")
    out += ["end)", ""]

    out += config_calls(m.get("options", {}))
    for g in m.get("gestures", []):
        out.append(f"hl.gesture({lua(g)})")
    for d in m.get("devices", []):
        out.append(f"hl.device({lua(d)})")
    out += ["",
            "-- Panels take the keyboard but not binds. Open panels are the shell's layers asking for the keyboard;",
            "-- closed ones have no surface.",
            "local function quickshell_panel_open()",
            "    for _, layer in ipairs(hl.get_layers()) do",
            '        if layer.namespace:match("^quickshell") and layer.keyboard_interactivity ~= 0 then',
            "            return true",
            "        end",
            "    end",
            "    return false",
            "end",
            "",
            "-- The window-close key closes an open panel instead of the window behind it.",
            "local function quickshell_close()",
            "    if quickshell_panel_open() then",
            '        return hl.dispatch(hl.dsp.global("quickshell:closePanel"))',
            "    end",
            "    hl.dispatch(hl.dsp.window.close())",
            "end",
            "",
            "-- Other window controls (float, layout, focus, moving a window) do nothing while a panel is open.",
            "local function quickshell_guard(dispatcher)",
            "    return function()",
            "        if not quickshell_panel_open() then",
            "            hl.dispatch(dispatcher)",
            "        end",
            "    end",
            "end",
            ""]
    for b in m.get("binds", []):
        out.append(bind(b))
    w = m.get("workspaceBinds", {})
    if w.get("enabled", True):
        out += ["for i = 1, 10 do", "    local key = i % 10",
                f'    hl.bind({lua(w.get("focusMod", "SUPER"))} .. " + " .. key, hl.dsp.focus({{ workspace = i }}))',
                f'    hl.bind({lua(w.get("moveMod", "SUPER + SHIFT"))} .. " + " .. key, quickshell_guard(hl.dsp.window.move({{ workspace = i }})))', "end"]
    out.append("")
    for r in m.get("windowRules", []):
        out.append(rule("hl.window_rule", r))
    out += ["-- Quickshell's panels move by themselves; the compositor's layer fade only made opening feel slow.",
            'hl.layer_rule({ name = "quickshell-no-anim", match = { namespace = "^quickshell.*" }, no_anim = true })', "",
            "-- Look from the active theme preset, then anything of your own.",
            'pcall(dofile, os.getenv("HOME") .. "/.config/hypr/theme.lua")',
            'local own = os.getenv("HOME") .. "/.config/hypr/user.lua"',
            'local file = io.open(own)',
            "if file then file:close() dofile(own) end", ""]
    return "\n".join(out)


def main():
    model = json.load(sys.stdin)
    text = render(model)
    candidate = os.path.join(HYPR, ".hyprland.candidate.lua")
    with open(candidate, "w") as f:
        f.write(text)
    check = subprocess.run(["Hyprland", "--verify-config", "-c", candidate], capture_output=True, text=True, timeout=20)
    if "config ok" not in check.stdout:
        os.remove(candidate)
        result = check.stdout.split("Config parsing result:")[-1].strip().replace(candidate, "line")
        print(result or "Hyprland rejected the configuration.", file=sys.stderr)
        sys.exit(1)
    if not os.path.exists(BACKUP) and os.path.exists(TARGET) and MARK not in open(TARGET).read(400):
        shutil.copy2(TARGET, BACKUP)
    os.replace(candidate, TARGET)
    if "--no-reload" not in sys.argv:
        subprocess.run(["hyprctl", "reload"], stdout=subprocess.DEVNULL)


if __name__ == "__main__":
    main()
