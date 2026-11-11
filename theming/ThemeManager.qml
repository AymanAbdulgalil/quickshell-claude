pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import ".."
import "../power"
import "../themes/palettes.js" as Palettes

// Switches and edits theme presets, sets the wallpaper, and passes the look on to other apps.
Singleton {
    id: root

    readonly property var active: ThemePresets.active
    // Colors found in the active preset's wallpaper, offered as swatches for custom colors.
    property var swatches: []
    property bool qtToolInstalled: true
    // What Hyprland said about the last look it was given; empty when it was accepted.
    property string lastError: ""

    // Switching applies at once; dragging or holding a control waits for the last value.
    readonly property int switchDelay: 40
    readonly property int editDelay: 180

    function apply(id) {
        if (ThemePresets.find(id)) {
            applyDelay.interval = switchDelay;
            Settings.themePreset = id;
        }
    }

    // Changes the active preset.
    function edit(changes) {
        ThemePresets.update(active.id, changes);
    }

    // One visual Hyprland option in the active preset. `fallback` is Hyprland's own default, used to reset the option
    // when switching to a preset that does not set it.
    function editHypr(name, value, fallback) {
        const stored = ThemePresets.list.find(p => p.id === active.id)?.hypr ?? {};
        if (fallback !== undefined && !(name in ThemePresets.defaults.hypr) && !(name in ThemePresets.baseline)) {
            const baseline = Object.assign({}, ThemePresets.baseline);
            baseline[name] = fallback;
            ThemePresets.baseline = baseline;
        }
        const next = Object.assign({}, stored);
        next[name] = value;
        applyDelay.interval = root.editDelay;
        edit({ hypr: next });
    }

    function editAnimation(leaf, changes) {
        const stored = ThemePresets.list.find(p => p.id === active.id)?.animations ?? {};
        const next = Object.assign({}, stored);
        next[leaf] = Object.assign({}, stored[leaf] ?? {}, changes);
        applyDelay.interval = root.editDelay;
        edit({ animations: next });
    }

    // --- Thumbnails of preset wallpapers, so the preset cards and the theme switcher show at once.

    readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/quickshell/thumbs"
    readonly property var presetWallpapers: [...new Set(ThemePresets.all.map(p => p.wallpaper).filter(w => w !== ""))]
    readonly property string presetWallpaperList: JSON.stringify(presetWallpapers)
    property var thumbsReady: ({})

    onPresetWallpaperListChanged: makeThumbs()

    function thumbPath(path) {
        return thumbDir + "/" + Qt.md5(path) + ".jpg";
    }

    // The thumbnail once it exists, the wallpaper itself until then.
    function thumb(path) {
        if (!path)
            return "";
        return "file://" + (thumbsReady[path] ? thumbPath(path) : path);
    }

    function makeThumbs() {
        thumbnailer.running = false;
        thumbnailer.command = ["sh", "-c", `
            mkdir -p "$DIR"
            while [ $# -gt 0 ]; do
                s=$1; t=$2; shift 2
                if [ ! "$t" -nt "$s" ]; then
                    nice magick "$s" -resize 720x -quality 85 "$t.new.jpg" && mv "$t.new.jpg" "$t"
                fi
                [ -e "$t" ] && printf '%s\\n' "$s"
            done`, "sh"].concat(presetWallpapers.reduce((all, w) => all.concat([w, thumbPath(w)]), []));
        thumbnailer.environment = { DIR: thumbDir };
        thumbnailer.running = true;
    }

    Process {
        id: thumbnailer

        stdout: SplitParser {
            onRead: line => {
                const ready = Object.assign({}, root.thumbsReady);
                ready[line] = true;
                root.thumbsReady = ready;
            }
        }
    }

    function setColors(source) {
        const changes = { colors: source };
        // Custom colors start from whatever is showing, so a single color can be changed.
        if (source === "custom" && !active.custom?.surface)
            changes.custom = Object.assign({}, Theme.palette);
        edit(changes);
    }

    function setCustomColor(role, hex) {
        const p = Object.assign({}, active.custom?.surface ? active.custom : Theme.palette);
        p[role] = hex;
        edit({ colors: "custom", custom: p });
    }

    // A copy of the active preset, which then becomes active.
    function newPreset() {
        const copy = Object.assign({}, ThemePresets.list.find(p => p.id === active.id) ?? {});
        copy.id = "preset" + Date.now();
        copy.name = active.name + " copy";
        ThemePresets.add(copy);
        apply(copy.id);
    }

    function deletePreset(id) {
        if (ThemePresets.list.length <= 1)
            return;
        if (id === active.id)
            apply(ThemePresets.all.find(p => p.id !== id).id);
        ThemePresets.remove(id);
    }

    // --- Wallpaper

    readonly property string wallpaper: active.wallpaper
    property bool started: false

    onWallpaperChanged: {
        if (started && wallpaper !== "")
            Quickshell.execDetached(["awww", "img", wallpaper, "--transition-type", "fade", "--transition-fps", "60", "--transition-duration", "0.4"]);
        readSwatches();
    }

    // --- Colors from wallpapers. One extraction at a time; results are kept per wallpaper and style.

    property var queue: []

    function readSwatches() {
        if (wallpaper !== "")
            want(wallpaper, active.dark, true);
    }

    function want(path, dark, forSwatches) {
        queue = queue.concat([{ path: path, dark: dark, swatches: forSwatches }]);
        next();
    }

    function next() {
        if (extractor.running || queue.length === 0)
            return;
        extractor.job = queue[0];
        queue = queue.slice(1);
        extractor.command = ["magick", extractor.job.path, "-resize", "160x100!", "-colors", "24", "-depth", "8", "-format", "%c", "histogram:info:-"];
        extractor.running = true;
    }

    // Every wallpaper-colored preset gets its colors worked out, so switching is instant.
    function fillCache() {
        for (const p of ThemePresets.all) {
            if (p.colors === "wallpaper" && p.wallpaper !== "" && !Settings.wallpaperPalettes[ThemePresets.wallpaperKey(p)])
                want(p.wallpaper, p.dark, false);
        }
    }

    readonly property string cacheNeeds: JSON.stringify(ThemePresets.all.filter(p => p.colors === "wallpaper").map(p => ThemePresets.wallpaperKey(p)))
    onCacheNeedsChanged: fillCache()

    Process {
        id: extractor

        property var job

        onExited: root.next()

        stdout: StdioCollector {
            onStreamFinished: {
                const found = [];
                for (const line of text.split("\n")) {
                    const m = line.match(/^\s*(\d+):.*?(#[0-9A-Fa-f]{6})/);
                    if (m)
                        found.push({ hex: m[2].toLowerCase(), weight: parseInt(m[1]) });
                }
                if (found.length === 0)
                    return;
                found.sort((a, b) => b.weight - a.weight);
                const job = extractor.job;
                if (job.swatches && job.path === root.wallpaper)
                    root.swatches = found;
                const cache = Object.assign({}, Settings.wallpaperPalettes);
                // Both styles at once: switching dark and light is then instant too.
                for (const dark of [true, false])
                    cache[job.path + "|" + (dark ? "dark" : "light")] = Palettes.fromSwatches(found, dark);
                Settings.wallpaperPalettes = cache;
            }
        }
    }

    // --- Passing the look on to other apps, only when it really changes and not at every start.

    readonly property var hyprLook: ({
            hypr: Object.assign({}, ThemePresets.baseline, active.hypr),
            curves: active.curves,
            animations: active.animations,
            cursorTheme: active.cursorTheme,
            cursorSize: active.cursorSize
        })
    readonly property var look: Object.assign({ font: active.font, fontMono: active.fontMono, wallpaper: active.wallpaper, loginWallpaper: active.loginWallpaper ?? "" }, hyprLook)
    // Colors, font and wallpaper reach every app; the rest only reaches Hyprland, so it is sent there alone.
    readonly property string appsSignature: JSON.stringify(Theme.palette) + active.font + active.fontMono + active.wallpaper + (active.loginWallpaper ?? "") + JSON.stringify(Settings.themeApps)
    readonly property string hyprSignature: JSON.stringify(hyprLook)
    readonly property string signature: appsSignature + hyprSignature
    // What the last finished run covered. A run replaced halfway stays unrecorded, so the next run still covers it.
    property string appliedApps: ""
    property string appliedHypr: ""

    onSignatureChanged: {
        if (appliedApps !== "" && (appsSignature !== appliedApps || hyprSignature !== appliedHypr))
            applyDelay.restart();
    }

    Component.onCompleted: {
        appliedApps = appsSignature;
        appliedHypr = hyprSignature;
        started = true;
        fillCache();
        makeThumbs();
    }

    function applyToApps(everything) {
        applier.sentApps = appsSignature;
        applier.sentHypr = hyprSignature;
        applier.payload = JSON.stringify({
            palette: Theme.palette,
            look: root.look,
            apps: Settings.themeApps,
            only: everything || appsSignature !== appliedApps ? null : ["hyprland"],
            // For this moment only, never saved: a change made while a panel is open must not undo the fade.
            live: windowsFaded ? windowFade() : {}
        }) + "\n";
        applier.running = false;
        applier.running = true;
    }

    Timer {
        id: applyDelay

        interval: root.switchDelay
        onTriggered: root.applyToApps(false)
    }

    Process {
        id: applier

        property string payload
        property string sentApps
        property string sentHypr

        stdinEnabled: true
        command: [Quickshell.shellPath("themes/apply.py")]
        stderr: StdioCollector {
            onStreamFinished: root.lastError = text.trim()
        }

        onStarted: {
            write(payload);
            stdinEnabled = false;
        }
        onExited: code => {
            stdinEnabled = true;
            if (code === 0) {
                root.appliedApps = sentApps;
                root.appliedHypr = sentHypr;
            }
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v qt6ct"]
        onExited: code => root.qtToolInstalled = code === 0
    }

    // Windows fade back while any panel is open (bar panels, launcher, Settings, clipboard, theme wheel), so the
    // panel reads as what has focus. Hyprland animates the change with its own fade curve.
    readonly property bool windowsFaded: Panels.name !== ""

    onWindowsFadedChanged: applyWindowFade()

    function windowFade() {
        return {
            "decoration:active_opacity": Math.min(active.fadeFocused, active.hypr["decoration:active_opacity"]),
            "decoration:inactive_opacity": Math.min(active.fadeUnfocused, active.hypr["decoration:inactive_opacity"])
        };
    }

    function applyWindowFade() {
        const o = windowsFaded ? windowFade() : active.hypr;
        Quickshell.execDetached(["hyprctl", "eval", `hl.config({ decoration = { active_opacity = ${o["decoration:active_opacity"]}, inactive_opacity = ${o["decoration:inactive_opacity"]} } })`]);
    }

    // A config reload puts back what theme.lua says, which drops the fade and the night shader.
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "configreloaded")
                return;
            if (root.windowsFaded)
                root.applyWindowFade();
            NightMode.verify();
        }
    }

    // From keybinds and scripts: qs ipc call theme preset nord
    IpcHandler {
        target: "theme"

        function preset(id: string): void {
            root.apply(id);
        }

        // Passes the current look on to other apps again (after installing one, or editing apply.py).
        function reapply(): void {
            root.applyToApps(true);
        }

        function list(): string {
            return ThemePresets.all.map(p => p.id + "\t" + p.name).join("\n");
        }

        function panel(): void {
            Panels.toggleOnFocused("themes");
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "themes"
        description: "Open the theme switcher"
        onPressed: Panels.toggleOnFocused("themes")
    }
}
