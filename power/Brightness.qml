pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Screen backlight. Normal and night mode each keep their own level in Settings, and the
// level fades between them along with the screen temperature.
Singleton {
    id: root

    property real level: 1
    property int maxRaw: 0
    readonly property bool available: maxRaw > 0
    // Idle dimming from hypridle. Does not touch the saved levels.
    property bool dimmed: false

    property int pendingRaw: -1
    property real lastWrite: 0

    function target() {
        const normal = Settings.normalBrightness < 0 ? level : Settings.normalBrightness;
        return normal + (Settings.nightBrightness - normal) * NightMode.level;
    }

    function clamp(value) {
        return Math.max(0.01, Math.min(1, value));
    }

    // From the slider and brightness keys: saved for whichever mode is on.
    function set(value) {
        const v = clamp(value);
        if (NightMode.enabled)
            Settings.nightBrightness = v;
        else
            Settings.normalBrightness = v;
        if (!dimmed)
            apply(v);
    }

    // Keys move in proportion, so the low end stays fine grained.
    function step(up) {
        set(up ? Math.max(level * 1.2, level + 0.01) : level / 1.2);
    }

    function dim() {
        dimmed = true;
        const low = Settings.dimPercent / 100;
        if (level > low)
            apply(low);
    }

    function undim() {
        dimmed = false;
        apply(clamp(target()));
    }

    function apply(value) {
        level = value;
        pendingRaw = Math.round(value * maxRaw);
        lastWrite = Date.now();
        if (!writer.running)
            flush();
    }

    function flush() {
        if (pendingRaw < 0)
            return;
        writer.command = ["brightnessctl", "-q", "set", String(pendingRaw)];
        pendingRaw = -1;
        writer.running = true;
    }

    // Follows the night fade, and the settings page while its sliders move.
    readonly property var followed: [NightMode.level, Settings.normalBrightness, Settings.nightBrightness]
    onFollowedChanged: if (available && !dimmed && Settings.normalBrightness >= 0)
        apply(clamp(target()))

    // One write at a time, always the newest value.
    Process {
        id: writer

        onExited: root.flush()
    }

    Process {
        id: reader

        running: true
        command: ["brightnessctl", "-m"]

        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                root.maxRaw = parseInt(f[4]) || 0;
                if (!root.available)
                    return;
                const hardware = parseInt(f[2]) / root.maxRaw;
                if (Settings.normalBrightness < 0) {
                    Settings.normalBrightness = hardware;
                    Settings.nightBrightness = root.clamp(hardware * 0.7);
                }
                // A reading just after a write can be stale; while dimmed it is not the real level.
                if (root.dimmed || Date.now() - root.lastWrite < 1000)
                    return;
                if (Panels.name === "power" && Math.abs(hardware - root.level) > 0.01)
                    root.set(hardware);
                else if (Math.abs(hardware - root.clamp(root.target())) > 0.01)
                    root.apply(root.clamp(root.target()));
                else
                    root.level = hardware;
            }
        }
    }

    // Catches changes made outside this shell while the slider is open.
    Timer {
        interval: 2000
        repeat: true
        running: Panels.name === "power"
        onTriggered: reader.running = true
    }

    IpcHandler {
        target: "brightness"

        function up(): void {
            root.step(true);
        }

        function down(): void {
            root.step(false);
        }

        function dim(): void {
            root.dim();
        }

        function undim(): void {
            root.undim();
        }
    }
}
