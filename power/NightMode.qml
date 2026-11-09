pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Screen temperature and the night fade. Brightness follows `level` from Brightness.qml.
Singleton {
    id: root

    readonly property alias enabled: kept.enabled
    // How far the fade has got: 0 is normal, 1 is full night.
    property real level: 0
    property bool fading: false

    // Hyprland only re-reads a shader when its path changes, so two paths take turns.
    property int slot: 0
    property string lastKey: "unset"
    readonly property string dir: Quickshell.env("XDG_RUNTIME_DIR") + "/quickshell-night"

    function set(on) {
        kept.enabled = on;
        fading = true;
        const to = on ? 1 : 0;
        fade.stop();
        fade.from = level;
        fade.to = to;
        fade.duration = Math.max(1, Math.abs(to - level) * Settings.nightFadeSeconds * 1000);
        fade.start();
        push();
    }

    // Red, green and blue multipliers for a color temperature (Tanner Helland's approximation).
    function kelvinRgb(kelvin) {
        if (kelvin >= 6500)
            return [1, 1, 1];
        const t = kelvin / 100;
        const clamp = v => Math.max(0, Math.min(1, v / 255));
        const g = 99.4708025861 * Math.log(t) - 161.1195681661;
        const b = t <= 19 ? 0 : 138.5177312231 * Math.log(t - 10) - 305.0447927307;
        return [1, clamp(g), clamp(b)];
    }

    function currentRgb() {
        const a = kelvinRgb(Settings.normalTemperature);
        const b = kelvinRgb(Settings.nightTemperature);
        return a.map((v, i) => v + (b[i] - v) * level);
    }

    // A plain shader for one color. A shader using Hyprland's `time` needs damage tracking
    // off, which costs far too much GPU. No shader at all when the screen is unchanged.
    function push() {
        if (writer.running)
            return;
        const rgb = currentRgb();
        const key = rgb.map(v => v.toFixed(3)).join(",");
        if (key === lastKey)
            return;
        lastKey = key;
        slot = 1 - slot;
        const plain = key === "1.000,1.000,1.000";
        const path = plain ? "" : dir + "/night-" + slot + ".glsl";
        const source = `#version 300 es
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;
void main() {
    vec4 c = texture(tex, v_texcoord);
    fragColor = vec4(c.rgb * vec3(${key}), c.a);
}
`;
        writer.command = ["sh", "-c", 'mkdir -p "$1"; [ -z "$3" ] || printf %s "$2" > "$3"; hyprctl eval "hl.config({ decoration = { screen_shader = \\"$3\\" } })" >/dev/null', "sh", dir, source, path];
        writer.running = true;
    }

    // A Hyprland config reload clears the shader, so check rather than assume.
    function verify() {
        if (!fading)
            reader.running = true;
    }

    function minutesNow() {
        const now = new Date();
        return now.getHours() * 60 + now.getMinutes();
    }

    function scheduleSaysNight() {
        const now = minutesNow();
        const a = Settings.nightStart;
        const b = Settings.nightEnd;
        return a <= b ? now >= a && now < b : now >= a || now < b;
    }

    // Follows the schedule at its boundaries, so a manual change lasts until the next one.
    property bool lastScheduled: false

    // The schedule turned night mode on or off by itself (for a notification).
    signal scheduled(bool on)

    function checkSchedule(force) {
        if (!Settings.autoNight)
            return;
        const should = scheduleSaysNight();
        if (force || should !== lastScheduled) {
            lastScheduled = should;
            if (should !== enabled) {
                set(should);
                if (!force)
                    scheduled(should);
            }
        }
    }

    readonly property var watched: [Settings.normalTemperature, Settings.nightTemperature]
    onWatchedChanged: push()
    readonly property var scheduleWatched: [Settings.autoNight, Settings.nightStart, Settings.nightEnd]
    onScheduleWatchedChanged: checkSchedule(true)

    Component.onCompleted: {
        level = kept.enabled ? 1 : 0;
        lastScheduled = scheduleSaysNight();
        push();
        checkSchedule(true);
    }

    Timer {
        interval: 30000
        repeat: true
        running: Settings.autoNight
        onTriggered: root.checkSchedule(false)
    }

    NumberAnimation {
        id: fade

        target: root
        property: "level"
        onFinished: {
            root.fading = false;
            root.push();
        }
    }

    // Steps of the fade: small enough to look smooth, few enough to stay cheap.
    Timer {
        interval: Theme.motion.nightStep
        repeat: true
        running: root.fading
        onTriggered: root.push()
    }

    Process {
        id: writer

        // Catches the final color if it arrived while a write was still running.
        onExited: root.push()
    }

    Process {
        id: reader

        command: ["hyprctl", "getoption", "decoration:screen_shader"]

        stdout: StdioCollector {
            onStreamFinished: {
                const applied = text.includes("quickshell-night");
                if (applied !== (root.lastKey !== "1.000,1.000,1.000")) {
                    root.lastKey = "unset";
                    root.push();
                }
            }
        }
    }

    PersistentProperties {
        id: kept

        reloadableId: "nightMode"

        property bool enabled: false
    }
}
