#!/usr/bin/env python3
"""Applies a theme preset to other apps. Reads JSON on stdin: {"palette": {...}, "look": {...}, "apps": {...}, "only": [...]}.

look: font, wallpaper, cursorTheme, cursorSize, hypr (option name to value), curves, animations.
only: when set, just these targets; a change to one Hyprland option should not rebuild the GTK theme.

Files from before the first run are kept in ~/.local/share/quickshell/theme-backup.
"""
import json
import re
import os
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "hyprland"))
from luagen import animation_call, config_calls, curve_call  # noqa: E402

HOME = os.environ["HOME"]
CONFIG = os.path.join(HOME, ".config")
BACKUP = os.path.join(HOME, ".local/share/quickshell/theme-backup")
MARK = "Written by Quickshell's theme settings."


OLD_MARK = "Written by Quickshell's theme panel."


def write(path, text):
    """Writes a file, keeping one backup of anything this script did not write itself."""
    if os.path.exists(path):
        with open(path, errors="replace") as f:
            head = f.read(400)
            if MARK not in head and OLD_MARK not in head:
                os.makedirs(BACKUP, exist_ok=True)
                target = os.path.join(BACKUP, os.path.relpath(path, CONFIG).replace("/", "__"))
                if not os.path.exists(target):
                    shutil.copy2(path, target)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    # Written beside and renamed over, so apps never read half a file, and folder watchers (qt6ct) notice.
    temp = path + ".quickshell-new"
    with open(temp, "w") as f:
        f.write(text)
    os.replace(temp, path)


def is_monospace(family):
    out = subprocess.run(["fc-match", "-f", "%{family}|%{spacing}", family], capture_output=True, text=True).stdout
    found, _, spacing = out.partition("|")
    return spacing == "100" and family.lower() in found.lower()


def kitty(p, look):
    ansi = [p["surfaceRaised"], p["error"], p["success"], p["warning"], p["accentAlt"], p["special"], p["info"], p["foreground"],
            p["border"], p["error"], p["success"], p["warning"], p["accent"], p["special"], p["info"], p["foregroundStrong"]]
    lines = [f"# {MARK}",
             f"foreground {p['foreground']}", f"background {p['surface']}",
             f"selection_foreground {p['onAccent']}", f"selection_background {p['accent']}",
             f"cursor {p['foregroundStrong']}", f"cursor_text_color {p['surface']}", f"url_color {p['accent']}",
             f"active_border_color {p['accent']}", f"inactive_border_color {p['border']}", f"bell_border_color {p['warning']}",
             f"active_tab_foreground {p['onAccent']}", f"active_tab_background {p['accent']}",
             f"inactive_tab_foreground {p['foreground']}", f"inactive_tab_background {p['surfaceRaised']}",
             f"tab_bar_background {p['surface']}"]
    lines += [f"color{i} {c}" for i, c in enumerate(ansi)]
    # A proportional font would break the terminal grid, so kitty keeps its own then.
    mono = look.get("fontMono") or look.get("font")
    if mono and is_monospace(mono):
        lines.append(f"font_family {mono}")
    text = "\n".join(lines) + "\n"
    # Kitty prefers the .auto files over current-theme when they exist.
    for name in ("current-theme.conf", "dark-theme.auto.conf", "light-theme.auto.conf", "no-preference-theme.auto.conf"):
        write(os.path.join(CONFIG, "kitty", name), text)
    subprocess.run(["pkill", "-USR1", "-x", "kitty"])


def gsetting(key, value):
    """Sets a GNOME interface setting, keeping the value from before the first change."""
    schema = "org.gnome.desktop.interface"
    saved = os.path.join(BACKUP, f"gsettings-{key}")
    if not os.path.exists(saved):
        old = subprocess.run(["gsettings", "get", schema, key], capture_output=True, text=True).stdout.strip()
        if old:
            os.makedirs(BACKUP, exist_ok=True)
            with open(saved, "w") as f:
                f.write(old + "\n")
    subprocess.run(["gsettings", "set", schema, key, value], stderr=subprocess.DEVNULL)


# --- GTK

CACHE = os.path.join(HOME, ".cache/quickshell")
THEMES = os.path.join(HOME, ".local/share/themes")
# Two names for the same generated theme. Switching the name is what makes running GTK 3 apps reload it.
GTK_NAMES = ("Quickshell-A", "Quickshell-B")


def hex_rgb(color):
    color = color.lstrip("#")
    if len(color) == 3:
        color = "".join(c * 2 for c in color)
    return tuple(int(color[i:i + 2], 16) / 255 for i in (0, 2, 4))


def rgb_hex(rgb):
    return "#" + "".join(f"{round(max(0, min(1, c)) * 255):02x}" for c in rgb)


def mix(a, b, t):
    return tuple(x + (y - x) * t for x, y in zip(a, b))


def adwaita_css(dark):
    """GTK 3's built-in Adwaita stylesheet, taken from the library once and kept in the cache."""
    name = "gtk-contained-dark.css" if dark else "gtk-contained.css"
    cached = os.path.join(CACHE, "adwaita-" + name)
    if not os.path.exists(cached):
        lib = next((l for l in ("/usr/lib/libgtk-3.so.0", "/usr/lib64/libgtk-3.so.0") if os.path.exists(l)), None)
        if not lib:
            return None
        out = subprocess.run(["gresource", "extract", lib, "/org/gtk/libgtk/theme/Adwaita/" + name], capture_output=True, text=True)
        if out.returncode != 0 or not out.stdout:
            return None
        os.makedirs(CACHE, exist_ok=True)
        with open(cached, "w") as f:
            f.write(out.stdout)
    with open(cached) as f:
        return f.read()


def recolor(css, p, dark):
    """Maps every color in Adwaita onto the palette. Greys follow a ramp from the palette's background to its text;
    blues become the accent, reds the error color and so on, keeping how much lighter or darker each shade was."""
    import colorsys
    c = {k: hex_rgb(v) for k, v in p.items() if isinstance(v, str) and v.startswith("#")}
    black, white = (0, 0, 0), (1, 1, 1)
    if dark:
        ramp = [(0.0, mix(c["surface"], black, 0.6)), (0.208, c["surface"]), (0.932, c["foreground"]), (1.0, mix(c["foreground"], white, 0.5))]
    else:
        ramp = [(0.0, mix(c["foreground"], black, 0.6)), (0.196, c["foreground"]), (0.96, c["surface"]), (1.0, mix(c["surface"], white, 0.6))]

    def grey(level):
        for (l0, c0), (l1, c1) in zip(ramp, ramp[1:]):
            if level <= l1:
                return mix(c0, c1, (level - l0) / (l1 - l0) if l1 > l0 else 0)
        return ramp[-1][1]

    def family(h):
        h *= 360
        if h < 15 or h >= 330:
            return "error"
        if h < 45:
            return "caution"
        if h < 70:
            return "warning"
        if h < 170:
            return "success"
        if h < 260:
            return "accent"
        return "special"

    def hls(rgb):
        return colorsys.rgb_to_hls(*rgb)

    # Each family's main shade in Adwaita: the one used most often.
    counts = {}
    for m in re.finditer(r"#[0-9a-fA-F]{6}\b", css):
        rgb = hex_rgb(m.group(0))
        h, l, s = hls(rgb)
        if s > 0.25 and 0.08 < l < 0.92:
            counts.setdefault(family(h), {}).setdefault(m.group(0).lower(), 0)
            counts[family(h)][m.group(0).lower()] += 1
    refs = {f: hls(hex_rgb(max(v, key=v.get))) for f, v in counts.items()}

    def convert(rgb):
        h, l, s = hls(rgb)
        if s <= 0.25 or l <= 0.08 or l >= 0.92:
            return grey(l)
        f = family(h)
        target = hls(c[f])
        ref = refs.get(f, (h, l, s))
        return colorsys.hls_to_rgb(target[0], max(0, min(1, target[1] + l - ref[1])), max(0, min(1, target[2] * s / max(ref[2], 0.01))))

    def on_hex(m):
        text = m.group(0)
        # In Adwaita's dark style, #ffffff is text on the accent; named white is ordinary text.
        if dark and text.lower() in ("#ffffff", "#fff"):
            return p["onAccent"]
        return rgb_hex(convert(hex_rgb(text)))

    def on_rgb(m):
        parts = [x.strip() for x in m.group(2).split(",")]
        rgb = tuple(float(x) / 255 for x in parts[:3])
        # Pure black and white with transparency are shadows and sheen; they stay.
        if rgb in (black, white) and len(parts) == 4:
            return m.group(0)
        new = [str(round(x * 255)) for x in convert(rgb)]
        return f"{m.group(1)}({', '.join(new + parts[3:])})"

    css = re.sub(r"#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{3}\b", on_hex, css)
    css = re.sub(r"\b(rgba?)\(([^)]*)\)", on_rgb, css)
    if dark:
        css = re.sub(r"(?<![-\w])white\b", p["foregroundStrong"], css)
    return css.replace('url("assets/', 'url("resource:///org/gtk/libgtk/theme/Adwaita/assets/')


def nearest_accent(color):
    """libadwaita apps only take one of GNOME's named accents, live; this picks the closest."""
    import colorsys
    named = {"blue": "#3584e4", "teal": "#2190a4", "green": "#3a944a", "yellow": "#c88800", "orange": "#ed5b00",
             "red": "#e62d42", "pink": "#d56199", "purple": "#9141ac", "slate": "#6f8396"}
    h, l, s = colorsys.rgb_to_hls(*hex_rgb(color))
    if s < 0.2:
        return "slate"

    def distance(item):
        nh, nl, ns = colorsys.rgb_to_hls(*hex_rgb(item[1]))
        d = abs(nh - h)
        return min(d, 1 - d) + (0.5 if ns < 0.2 else 0)
    return min(named.items(), key=distance)[0]


def gtk(p, look):
    shared = f"""/* {MARK} */
@define-color accent_color {p['accent']};
@define-color accent_bg_color {p['accent']};
@define-color accent_fg_color {p['onAccent']};
@define-color destructive_color {p['error']};
@define-color destructive_bg_color {p['error']};
@define-color success_color {p['success']};
@define-color warning_color {p['warning']};
@define-color error_color {p['error']};
@define-color window_bg_color {p['surface']};
@define-color window_fg_color {p['foreground']};
@define-color view_bg_color {p['surface']};
@define-color view_fg_color {p['foreground']};
@define-color headerbar_bg_color {p['surfaceRaised']};
@define-color headerbar_fg_color {p['foreground']};
@define-color sidebar_bg_color {p['surfaceRaised']};
@define-color sidebar_fg_color {p['foreground']};
@define-color card_bg_color {p['surfaceRaised']};
@define-color card_fg_color {p['foreground']};
@define-color popover_bg_color {p['surfaceRaised']};
@define-color popover_fg_color {p['foreground']};
@define-color dialog_bg_color {p['surfaceRaised']};
@define-color dialog_fg_color {p['foreground']};
"""
    # GTK 4 and libadwaita: these names, read when an app starts.
    write(os.path.join(CONFIG, "gtk-4.0/gtk.css"), shared)
    # GTK 3 reads its user file only at start and it would override the theme, so it stays empty.
    write(os.path.join(CONFIG, "gtk-3.0/gtk.css"), f"/* {MARK} The colors are in ~/.local/share/themes/Quickshell-A. */\n")

    css = adwaita_css(p["dark"])
    if css:
        css = f"/* {MARK} Adwaita, recolored. */\n" + recolor(css, p, p["dark"])
        for name in GTK_NAMES:
            write(os.path.join(THEMES, name, "index.theme"), f"[Desktop Entry]\nType=X-GNOME-Metatheme\nName={name}\nComment={MARK}\n")
            write(os.path.join(THEMES, name, "gtk-3.0/gtk.css"), css)
        current = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", "gtk-theme"], capture_output=True, text=True).stdout.strip().strip("'")
        gsetting("gtk-theme", f"'{GTK_NAMES[1] if current == GTK_NAMES[0] else GTK_NAMES[0]}'")

    # Live in every GTK app: light or dark, the font, and libadwaita's accent.
    gsetting("color-scheme", "'prefer-dark'" if p["dark"] else "'default'")
    gsetting("accent-color", f"'{nearest_accent(p['accent'])}'")
    if look.get("font"):
        gsetting("font-name", f"'{look['font']} 11'")


# --- Icons: a monochrome icon theme for files, folders and devices, made from Adwaita's symbolic icons and
# painted in the palette's colors. Two copies, like the GTK theme, so switching names makes running apps reload.
ICONS = os.path.join(HOME, ".local/share/icons")
ICON_NAMES = ["Quickshell-Icons-A", "Quickshell-Icons-B"]
ADWAITA = "/usr/share/icons/Adwaita"
ICON_CONTEXTS = ("mimetypes", "places", "devices")
icon_theme_name = None


def icon_source(name, symbolic):
    """The symbolic icon that stands for a colored icon name."""
    if name in symbolic:
        return symbolic[name]
    n = name.lower()
    rules = [
        (("folder", "inode-directory", "user-home", "user-desktop"), "folder"),
        (("-template",), None),
        (("image-",), "image-x-generic"), (("audio-",), "audio-x-generic"), (("video-",), "video-x-generic"),
        (("font-",), "font-x-generic"),
        (("zip", "tar", "archive", "compressed", "rar", "7z", "x-deb", "rpm", "package", "repository", "x-xz", "gzip", "bzip"),
         "package-x-generic"),
        (("spreadsheet", "excel", "calc", "csv"), "x-office-spreadsheet"),
        (("presentation", "powerpoint", "impress"), "x-office-presentation"),
        (("drawing", "draw", "model"), "x-office-drawing"),
        (("pdf", "document", "msword", "writer", "opendocument", "rtf", "epub"), "x-office-document"),
        (("executable", "x-sharedlib", "appimage", "x-ms-dos"), "application-x-executable"),
        (("certificate", "pgp", "key"), "application-certificate"),
        (("addon", "plugin", "extension"), "application-x-addon"),
    ]
    for keys, target in rules:
        if any(k in n for k in keys):
            if target is None:
                return icon_source(re.sub(r"-template$", "", name), symbolic)
            if target in symbolic:
                return symbolic[target]
    return symbolic.get("text-x-generic")


def icons(p, look):
    global icon_theme_name
    # The slowest step by far: only redone when its colors change.
    stamp = os.path.join(CACHE, "icons-stamp")
    wanted_stamp = p["accent"] + p["foreground"]
    current = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", "icon-theme"], capture_output=True, text=True).stdout.strip().strip("'")
    try:
        with open(stamp) as f:
            if f.read() == wanted_stamp and current in ICON_NAMES:
                icon_theme_name = current
                return
    except OSError:
        pass
    symbolic = {}
    for root, _, files in os.walk(os.path.join(ADWAITA, "symbolic")):
        for f in files:
            if f.endswith("-symbolic.svg"):
                symbolic[f[:-len("-symbolic.svg")]] = os.path.join(root, f)
    if not symbolic:
        return
    # Every colored name a file manager could find in Adwaita, its legacy set, or apps' own icons, per context.
    wanted = {c: set() for c in ICON_CONTEXTS}
    for base in (ADWAITA, "/usr/share/icons/AdwaitaLegacy", "/usr/share/icons/hicolor"):
        for root, _, files in os.walk(base):
            context = os.path.basename(root)
            if context in wanted:
                for f in files:
                    name = os.path.splitext(f)[0]
                    if not name.endswith("-symbolic"):
                        wanted[context].add(name)
    for context in ICON_CONTEXTS:
        sym_dir = os.path.join(ADWAITA, "symbolic", context)
        if os.path.isdir(sym_dir):
            wanted[context] |= {f[:-len("-symbolic.svg")] for f in os.listdir(sym_dir) if f.endswith("-symbolic.svg")}
    wanted["places"] |= {"folder", "folder-open", "inode-directory"}

    name = ICON_NAMES[1] if current == ICON_NAMES[0] else ICON_NAMES[0]
    target = os.path.join(ICONS, name)
    if os.path.isdir(target):
        shutil.rmtree(target)
    cache = {}
    for context, names in wanted.items():
        folder = os.path.join(target, "scalable", context)
        os.makedirs(folder, exist_ok=True)
        for icon in names:
            source = icon_source(icon, symbolic)
            if not source:
                continue
            color = p["accent"] if context == "places" and ("folder" in icon or icon in ("inode-directory", "user-home", "user-desktop")) else p["foreground"]
            key = (source, color)
            if key not in cache:
                with open(source) as f:
                    svg = f.read()
                svg = re.sub(r"#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{3}\b", color, svg)
                svg = re.sub(r"fill:\s*(black|currentColor)", f"fill:{color}", svg)
                cache[key] = svg
            with open(os.path.join(folder, icon + ".svg"), "w") as f:
                f.write(cache[key])
    dirs = ",".join(f"scalable/{c}" for c in ICON_CONTEXTS)
    sections = "".join(f"\n[scalable/{c}]\nContext={c.capitalize()}\nSize=64\nMinSize=8\nMaxSize=512\nType=Scalable\n" for c in ICON_CONTEXTS)
    with open(os.path.join(target, "index.theme"), "w") as f:
        f.write(f"[Icon Theme]\nName={name}\nComment={MARK}\nInherits=Adwaita,AdwaitaLegacy,hicolor\nDirectories={dirs}\n{sections}")
    icon_theme_name = name
    gsetting("icon-theme", f"'{name}'")
    os.makedirs(CACHE, exist_ok=True)
    with open(stamp, "w") as f:
        f.write(wanted_stamp)


def qt(p, look):
    # WindowText, Button, Light, Midlight, Dark, Mid, Text, BrightText, ButtonText, Base, Window, Shadow,
    # Highlight, HighlightedText, Link, LinkVisited, AlternateBase, NoRole, ToolTipBase, ToolTipText, PlaceholderText
    def row(fg, bg):
        return ", ".join([fg, p["surfaceRaised"], p["surfaceHover"], p["surfaceRaised"], p["border"], p["surfaceHover"], fg,
                          p["foregroundStrong"], fg, bg, bg, p["surface"], p["accent"], p["onAccent"], p["accent"], p["special"],
                          p["surfaceRaised"], bg, p["surfaceRaised"], p["foreground"], p["muted"]])
    scheme = f"""# {MARK}
[ColorScheme]
active_colors={row(p['foreground'], p['surface'])}
inactive_colors={row(p['foreground'], p['surface'])}
disabled_colors={row(p['muted'], p['surface'])}
"""
    for tool in ("qt6ct", "qt5ct"):
        colors = os.path.join(CONFIG, tool, "colors/quickshell.conf")
        write(colors, scheme)
        conf = os.path.join(CONFIG, tool, f"{tool}.conf")
        fonts = ""
        if look.get("font"):
            fonts = f'[Fonts]\ngeneral="{look["font"]},10,-1,5,50,0,0,0,0,0"\nfixed="{look.get("fontMono") or look["font"]},10,-1,5,50,0,0,0,0,0"\n'
        write(conf, f"""# {MARK}
[Appearance]
color_scheme_path={colors}
custom_palette=true
style=Fusion
""" + (f"icon_theme={icon_theme_name}\n" if icon_theme_name else "") + fonts)
    write(os.path.join(CONFIG, "kdeglobals"), f"""# {MARK}
[Colors:Window]
BackgroundNormal={p['surface']}
ForegroundNormal={p['foreground']}
[Colors:View]
BackgroundNormal={p['surface']}
ForegroundNormal={p['foreground']}
[Colors:Button]
BackgroundNormal={p['surfaceRaised']}
ForegroundNormal={p['foreground']}
[Colors:Selection]
BackgroundNormal={p['accent']}
ForegroundNormal={p['onAccent']}
""")


def hypr_rgba(color, alpha="ee"):
    return f"rgba({color[1:]}{alpha})"


def lua_string(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def hyprland(p, look):
    # Borders and background follow the palette unless the preset sets its own.
    options = {"general:col.active_border": {"colors": [hypr_rgba(p["accent"]), hypr_rgba(p["accentAlt"])], "angle": 45},
               "general:col.inactive_border": hypr_rgba(p["surface"]),
               # Shown before the wallpaper draws at login: the login screen goes to the theme's background, not black.
               "misc:background_color": "rgb(" + p["surface"][1:] + ")"}
    options.update(look.get("hypr", {}))
    calls = config_calls(options)
    calls += [curve_call(c) for c in look.get("curves", [])]
    calls += [animation_call(leaf, a) for leaf, a in look.get("animations", {}).items()]
    size, cursor = str(look.get("cursorSize", 16)), look.get("cursorTheme", "")
    env = [f'hl.env("XCURSOR_SIZE", "{size}")', f'hl.env("HYPRCURSOR_SIZE", "{size}")']
    if cursor:
        env += [f'hl.env("XCURSOR_THEME", {lua_string(cursor)})', f'hl.env("HYPRCURSOR_THEME", {lua_string(cursor)})']
    lines = [f"-- {MARK}", "-- hyprland.lua reads this, and its autostart uses the wallpaper."]
    if look.get("wallpaper"):
        lines.append(f"quickshell_wallpaper = {lua_string(look['wallpaper'])}")
    lines.append(f'quickshell_background = "{p["surface"][1:]}"')
    # One eval: spawning hyprctl per option is what made sliders lag. theme.lua is only replaced when Hyprland took it,
    # because a bad value in it would show Hyprland's error banner at every reload.
    live = calls if not look.get("live") else config_calls({**options, **look["live"]}) + calls[len(config_calls(options)):]
    result = subprocess.run(["hyprctl", "eval", "\n".join(live)], capture_output=True, text=True)
    if result.returncode != 0:
        print(result.stdout.strip() or result.stderr.strip(), file=sys.stderr)
        return
    write(os.path.join(CONFIG, "hypr/theme.lua"), "\n".join(lines + env + calls) + "\n")
    if cursor:
        subprocess.run(["hyprctl", "setcursor", cursor, size], stdout=subprocess.DEVNULL)
        gsetting("cursor-theme", f"'{cursor}'")
    gsetting("cursor-size", size)


def hyprlock(p, look):
    names = {"muted": "b3", "surface": "ff", "surfaceRaised": "eb", "foreground": "e6", "foregroundStrong": "f2", "accent": "d9", "info": "d9", "error": "ff"}
    lines = [f"# {MARK}"] + [f"$theme_{k} = {hypr_rgba(p[k], a)}" for k, a in names.items()]
    write(os.path.join(CONFIG, "hypr/hyprlock-colors.conf"), "\n".join(lines) + "\n")


def btop(p, look):
    """btop: a theme file from the palette, picked in btop.conf, then SIGUSR2 so a running btop reloads it."""
    a, b, strong = p["accent"], p["accentAlt"], p["foregroundStrong"]
    warm = (p["success"], p["warning"], p["error"])
    colors = {
        "main_bg": p["surface"], "main_fg": p["foreground"], "title": strong, "hi_fg": a,
        "selected_bg": p["surfaceHover"], "selected_fg": strong, "inactive_fg": p["inactive"],
        "graph_text": p["muted"], "meter_bg": p["surfaceRaised"], "proc_misc": a,
        "cpu_box": p["border"], "mem_box": p["border"], "net_box": p["border"], "proc_box": p["border"],
        "div_line": p["border"],
    }
    gradients = {"temp": warm, "cpu": (b, a, strong), "free": (b, a, strong), "cached": (b, a, strong),
                 "available": (b, a, strong), "used": warm, "download": (b, a, strong), "upload": (p["special"], p["info"], strong),
                 "process": (a, p["info"], p["error"])}
    for name, (start, mid, end) in gradients.items():
        colors[f"{name}_start"], colors[f"{name}_mid"], colors[f"{name}_end"] = start, mid, end
    text = f"# {MARK}\n" + "".join(f'theme[{k}]="{v}"\n' for k, v in colors.items())
    write(os.path.join(CONFIG, "btop/themes/quickshell.theme"), text)
    conf = os.path.join(CONFIG, "btop/btop.conf")
    try:
        with open(conf) as f:
            current = f.read()
    except OSError:
        current = ""
    wanted = 'color_theme = "quickshell"'
    if wanted not in current:
        if re.search(r"^color_theme\s*=.*$", current, flags=re.M):
            updated = re.sub(r"^color_theme\s*=.*$", wanted, current, flags=re.M)
        else:
            updated = current + wanted + "\n"
        # btop.conf is btop's own file (it rewrites it on exit), so it is edited in place, not marked.
        os.makedirs(BACKUP, exist_ok=True)
        if current and not os.path.exists(os.path.join(BACKUP, "btop__btop.conf")):
            shutil.copy2(conf, os.path.join(BACKUP, "btop__btop.conf"))
        temp = conf + ".quickshell-new"
        with open(temp, "w") as f:
            f.write(updated)
        os.replace(temp, conf)
    subprocess.run(["pkill", "-USR2", "-x", "btop"], stderr=subprocess.DEVNULL)


# --- Login screen (SDDM). The greeter cannot read the home folder, so its theme lives in /var/lib/quickshell-sddm,
# a folder owned by this user that /usr/share/sddm/themes/quickshell points to (made once by sddm/install.sh).
SDDM_DIR = os.environ.get("QUICKSHELL_SDDM_DIR", "/var/lib/quickshell-sddm")
SDDM_SOURCE = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "sddm")


def sddm(p, look):
    if not os.access(SDDM_DIR, os.W_OK):
        return
    for name in ("Main.qml", "metadata.desktop"):
        shutil.copyfile(os.path.join(SDDM_SOURCE, name), os.path.join(SDDM_DIR, name))
    background = ""
    wallpaper = look.get("wallpaper")
    if wallpaper and os.path.isfile(wallpaper):
        ext = os.path.splitext(wallpaper)[1].lower() or ".jpg"
        background = os.path.join(SDDM_DIR, "background" + ext)
        for old in os.listdir(SDDM_DIR):
            if old.startswith("background.") and old != os.path.basename(background):
                os.remove(os.path.join(SDDM_DIR, old))
        source = os.stat(wallpaper)
        if not (os.path.exists(background) and os.stat(background).st_size == source.st_size
                and int(os.stat(background).st_mtime) == int(source.st_mtime)):
            temp = background + ".new"
            shutil.copy2(wallpaper, temp)
            os.chmod(temp, 0o644)
            os.replace(temp, background)
    values = {k: p[k] for k in ("surface", "surfaceRaised", "foreground", "foregroundStrong", "muted", "accent", "error")}
    values["font"] = look.get("font") or "monospace"
    values["background"] = background
    text = f"# {MARK}\n[General]\n" + "".join(f'{k}="{v}"\n' for k, v in values.items())
    temp = os.path.join(SDDM_DIR, "theme.conf.new")
    with open(temp, "w") as f:
        f.write(text)
    os.chmod(temp, 0o644)
    os.replace(temp, os.path.join(SDDM_DIR, "theme.conf"))


def icons_then_qt(p, look):
    """Qt's settings name the icon theme, so icons go first."""
    icons(p, look)
    qt(p, look)


TARGETS = {"hyprland": hyprland, "kitty": kitty, "gtk": gtk, "icons": icons, "qt": qt, "btop": btop, "hyprlock": hyprlock, "sddm": sddm}


def run(name, fn, p, look):
    try:
        fn(p, look)
    except OSError as e:
        print(f"{name}: {e}", file=sys.stderr)


def main():
    data = json.load(sys.stdin)
    p, apps, look, only = data["palette"], data["apps"], data.get("look", {}), data.get("only")
    look["live"] = data.get("live", {})
    wanted = [n for n in TARGETS if apps.get(n, True) and (only is None or n in only)]
    # What shows soonest goes first; the rest wait on other programs, so they run side by side.
    if "hyprland" in wanted:
        wanted.remove("hyprland")
        run("hyprland", hyprland, p, look)
    if "icons" in wanted and "qt" in wanted:
        wanted.remove("qt")
        wanted[wanted.index("icons")] = "iconsQt"
    jobs = [(n, icons_then_qt if n == "iconsQt" else TARGETS[n]) for n in wanted]
    with ThreadPoolExecutor(max_workers=6) as pool:
        for name, fn in jobs:
            pool.submit(run, name, fn, p, look)


if __name__ == "__main__":
    main()
