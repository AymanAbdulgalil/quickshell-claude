# After a Hyprland update

Hyprland's Lua config is new and changes between releases. Written for Hyprland 0.57.1, hyprlock 0.9.7, Quickshell 0.3.2 (2026-11-08).
When any of these update, go down this list instead of rediscovering it. Start with **Quick check**.

## Quick check

```bash
python3 ~/.config/quickshell/hyprland/generate.py --no-reload < ~/.config/quickshell/hyprland.json; echo $?
```
```bash
hyprctl configerrors
```
```bash
hyprctl descriptions -j | head -c 300
```

Exit 0 and no errors means the config still parses. Then open Settings > All options and search for an option you know.

## What depends on Hyprland, and where

| What | Where | What to look for |
|---|---|---|
| Config calls: `hl.config`, `hl.monitor`, `hl.env`, `hl.on("hyprland.start")`, `hl.exec_cmd`, `hl.gesture`, `hl.device`, `hl.window_rule`, `hl.layer_rule`, `hl.curve`, `hl.animation` | `hyprland/generate.py`, `hyprland/luagen.py` | Renamed calls or fields |
| Dispatchers: `hl.dsp.exec_cmd`, `global`, `window.close/float/pseudo/drag/resize/move`, `focus`, `layout("togglesplit")`, `workspace.toggle_special`, `exit`, `dpms` | `ACTIONS` in `generate.py`; `Workspaces.qml`, `PowerPanel.qml`, `Notifications.qml`, `hypridle.conf` | Renames; `dpms` treats an unknown action as a toggle |
| Nested option writing: `a:b.c` becomes `{ a = { b = { c = x } } }`; colors `rgba(rrggbbaa)`; gradients `{ colors, angle }` | `luagen.py` | The value formats Lua accepts |
| `Hyprland --verify-config -c FILE` printing "config ok" (exit code is always 0) | `generate.py` | If the text changes, **every save is refused** |
| `hyprctl eval` taking several lines, and its non-zero exit on error | `themes/apply.py`, `ThemeManager.qml`, `NightMode.qml` | |
| `hyprctl descriptions -j` fields: `name`, `description`, `default`, `current`, `min`, `max`, `map` | `hyprland/schema.js`, `OptionsPage.qml` | New field names or value kinds |
| Which options are hidden or visual | `hiddenPrefixes`, `visualPrefixes` in `schema.js` | **New options that animate continuously or need damage tracking off must be hidden** |
| Options set by name | `ThemePresets.defaults.hypr`, `WindowsPage.qml`, `hyprland.json` | Moved or renamed options |
| Animation leaf names and styles (`popin 87%`, `fade`) | `ThemePresets.defaults.animations` | Compare with `hyprctl animations -j` |
| Window rule effect names | `knownEffects` in `RulesPage.qml` | New or renamed effects |
| Layer rule `no_anim` for `^quickshell.*` | `generate.py` | |
| Screen shader: `decoration:screen_shader`, GLSL `#version 300 es`, `v_texcoord`, `tex` | `power/NightMode.qml` | Never use the `time` uniform |
| Socket events: `activelayout`, `configreloaded`, `openwindow` | `bar/Language.qml`, `ThemeManager.qml`, `Panels.qml` | Data field order |
| `hyprctl switchxkblayout`, `setcursor`, `devices -j`, `monitors all -j`, `getoption`, `seterror` | various | JSON field names (`active_keymap`, `main`, `availableModes`) |
| Global shortcut names `quickshell:launcher`, `clipboard`, `notes`, `settings`, `themes`, `closePanel` | `hyprland.json`, `GlobalShortcut`s | |
| `misc:background_color` | `apply.py` | Black, so the session starts on the color the login screen faded to |
| The close key as a Lua function: `hl.bind` taking a function, `hl.dispatch`, `hl.get_layers()` with `namespace` and `keyboard_interactivity` | `quickshell_close` in `generate.py` | If these change, Super+Q stops closing panels, or windows. Test: open a panel, press Super+Q; the window behind stays |
| Window controls behind a guard: a dispatcher made once (`hl.dsp.window.float(...)`) and dispatched later from a function, any number of times | `quickshell_guard` in `generate.py` | If a dispatcher can only run once, or binds stop taking functions, Super+F, J, P, arrows and Shift+number stop working. Test: with no panel open each works; with one open, nothing happens |
| After a workspace switch with a panel open: `hl.get_active_workspace().last_window` and `hl.dsp.focus({ window = "address:..." })` | `Panels.qml` (`refocuser`) | Test: open the launcher, Super+2, Esc; you should stay on 2. Also an empty workspace |

## Other programs

| Program | What is relied on | Where |
|---|---|---|
| hyprlock | `$LAYOUT[EN,AR]`, label `onclick`, input-field options | `~/.config/hypr/hyprlock.conf` |
| hypridle | `source =`, listener format, honoring logind's idle inhibit | `hypridle.conf` |
| Qt | `TextEdit.cursorSelection` (font and color of a selection), which Notes styling depends on | `notes/NoteEditor.qml` |
| Quickshell | `ScriptModel`, `LazyLoader`, `HyprlandFocusGrab`, `Pipewire.preferredDefaultAudioSink`, `//@ pragma NativeTextRendering` | across the config |
| awww | `clear RRGGBB`, `img --transition-type fade` | `generate.py`, `ThemeManager.qml` |
| start-hyprland | Safe mode after a crash, using a generated recovery config | Log out from it to return |
