pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "themes/palettes.js" as Palettes

// Theme presets, saved in presets.json beside this file. A preset holds everything that changes how the desktop
// looks; see DESIGN.md. Settings.themePreset names the active one. Presets only store what differs from `defaults`.
Singleton {
    id: root

    readonly property var defaults: ({
            name: "Untitled",
            wallpaper: "",
            colors: "palette",      // "palette", "wallpaper" or "custom"
            palette: "nord",        // for "palette": an id from themes/palettes.js
            dark: true,             // for "wallpaper"
            custom: ({}),           // for "custom": a full palette
            font: "JetBrains Mono",
            fontTitle: "",          // "" uses `font`
            fontMono: "",           // "" uses `font`
            fontSmall: 11,          // the rest of the type scale follows it
            fontBar: 13,
            fontDisplay: 30,
            fontWeight: 500,
            widgetRadius: 14,       // panels; the bar and controls are scaled from it
            panelBorder: 1,
            density: 1,             // 0.9 compact, 1 regular, 1.15 roomy
            barHeight: 32,
            barPosition: "top",     // or "bottom", "left", "right"
            panelBarGap: 6,         // between the bar and its panels
            barGap: 10,             // around the bar
            barPadding: 10,
            barItemSpacing: 10,
            barGroupSpacing: 18,
            motionScale: 1,         // 0 turns the shell's animations off
            panelSpeed: 160,
            fadeFocused: 0.55,      // application windows while a panel is open
            fadeUnfocused: 0.4,
            analogClock: "clock/Analog",
            cursorTheme: "",        // "" leaves the system's cursor alone
            cursorSize: 16,
            // Visual Hyprland options by name, as `hyprctl descriptions` lists them.
            hypr: ({
                    "general:gaps_in": 5,
                    "general:gaps_out": 10,
                    "general:border_size": 1,
                    "general:layout": "dwindle",
                    "general:resize_on_border": true,
                    "general:allow_tearing": false,
                    "decoration:rounding": 16,
                    "decoration:rounding_power": 2,
                    "decoration:active_opacity": 1,
                    "decoration:inactive_opacity": 0.75,
                    "decoration:dim_inactive": false,
                    "decoration:dim_strength": 0.2,
                    "decoration:shadow:enabled": false,
                    "decoration:shadow:range": 12,
                    "decoration:blur:enabled": false,
                    "decoration:blur:size": 6,
                    "decoration:blur:passes": 2,
                    "animations:enabled": true,
                    "dwindle:preserve_split": true,
                    "master:new_status": "master",
                    "misc:disable_hyprland_logo": true,
                    "misc:disable_splash_rendering": true,
                    "misc:force_default_wallpaper": 0
                }),
            curves: ([
                    { name: "easeOutQuint", x1: 0.23, y1: 1, x2: 0.32, y2: 1 },
                    { name: "easeInOutCubic", x1: 0.65, y1: 0.05, x2: 0.36, y2: 1 },
                    { name: "linear", x1: 0, y1: 0, x2: 1, y2: 1 },
                    { name: "almostLinear", x1: 0.5, y1: 0.5, x2: 0.75, y2: 1 },
                    { name: "quick", x1: 0.15, y1: 0, x2: 0.1, y2: 1 }
                ]),
            animations: ({
                    global: { enabled: true, speed: 10, curve: "default", style: "" },
                    border: { enabled: true, speed: 5.39, curve: "easeOutQuint", style: "" },
                    windows: { enabled: true, speed: 4.79, curve: "easeOutQuint", style: "" },
                    windowsIn: { enabled: true, speed: 4.1, curve: "easeOutQuint", style: "popin 87%" },
                    windowsOut: { enabled: true, speed: 1.49, curve: "linear", style: "popin 87%" },
                    fadeIn: { enabled: true, speed: 1.73, curve: "almostLinear", style: "" },
                    fadeOut: { enabled: true, speed: 1.46, curve: "almostLinear", style: "" },
                    fade: { enabled: true, speed: 3.03, curve: "quick", style: "" },
                    layers: { enabled: true, speed: 3.81, curve: "easeOutQuint", style: "" },
                    layersIn: { enabled: true, speed: 4, curve: "easeOutQuint", style: "fade" },
                    layersOut: { enabled: true, speed: 1.5, curve: "linear", style: "fade" },
                    fadeLayersIn: { enabled: true, speed: 1.79, curve: "almostLinear", style: "" },
                    fadeLayersOut: { enabled: true, speed: 1.39, curve: "almostLinear", style: "" },
                    workspaces: { enabled: true, speed: 1.94, curve: "almostLinear", style: "fade" },
                    workspacesIn: { enabled: true, speed: 1.21, curve: "almostLinear", style: "fade" },
                    workspacesOut: { enabled: true, speed: 1.94, curve: "almostLinear", style: "fade" },
                    zoomFactor: { enabled: true, speed: 7, curve: "quick", style: "" }
                })
        })

    property alias list: data.presets
    // Options some preset has set beyond `defaults.hypr`, with Hyprland's default, so switching away resets them.
    property alias baseline: data.baseline
    readonly property var all: list.map(p => withDefaults(p))
    readonly property var active: all.find(p => p.id === Settings.themePreset) ?? all[0] ?? withDefaults({ id: "fallback" })

    function withDefaults(p) {
        const merged = Object.assign({}, defaults, p);
        merged.hypr = Object.assign({}, defaults.hypr, p.hypr ?? {});
        const leaves = {};
        for (const leaf in defaults.animations)
            leaves[leaf] = Object.assign({}, defaults.animations[leaf], p.animations?.[leaf] ?? {});
        merged.animations = leaves;
        return merged;
    }

    function find(id) {
        return all.find(p => p.id === id) ?? null;
    }

    // Wallpaper colors are worked out once per wallpaper and style, and kept in Settings.
    function wallpaperKey(p) {
        return p.wallpaper + "|" + (p.dark ? "dark" : "light");
    }

    function paletteOf(p) {
        if (p.colors === "wallpaper" && Settings.wallpaperPalettes[wallpaperKey(p)])
            return Settings.wallpaperPalettes[wallpaperKey(p)];
        if (p.colors === "custom" && p.custom?.surface)
            return p.custom;
        return Palettes.find(p.palette).palette;
    }

    function update(id, changes) {
        list = list.map(p => p.id === id ? Object.assign({}, p, changes) : p);
    }

    function add(preset) {
        list = list.concat([preset]);
    }

    function remove(id) {
        list = list.filter(p => p.id !== id);
    }

    FileView {
        path: Quickshell.shellPath("presets.json")
        blockLoading: true
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                data.presets = [{ id: "nord", name: "Nord", colors: "palette", palette: "nord" }];
                writeAdapter();
            }
        }

        JsonAdapter {
            id: data

            property var presets: []
            property var baseline: ({})
        }
    }
}
