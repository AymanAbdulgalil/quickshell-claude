import QtQuick
import "../.."

// Draws one network state. All state decisions live in bar/NetworkIndicator.
// The icon uses the foreground color; only marks carry color.
//
// Inputs: signalStrength (0 to 1), vpn, netState:
//         wifi | wifi-no-internet | wifi-firewall | disconnected | searching | connecting
//         | software-off | hardware-off | hotspot | monitor
//         | ethernet | ethernet-no-internet | ethernet-firewall | ethernet-connecting
Canvas {
    // Colors below come from the theme, so repaint when it changes.
    readonly property var themeWatch: Theme.palette
    onThemeWatchChanged: requestPaint()

    id: root

    readonly property string status: parent.netState
    readonly property real signalStrength: parent.signalStrength
    readonly property bool vpn: parent.vpn

    readonly property var spec: ({
            "wifi": { kind: "wifi" },
            "wifi-no-internet": { kind: "wifi", mark: "alert" },
            "wifi-firewall": { kind: "wifi", mark: "wall" },
            "disconnected": { kind: "wifi", bars: 3, mark: "cross" },
            "searching": { kind: "wifi", steps: 3, anim: "sweep" },
            "connecting": { kind: "wifi", steps: 4, anim: "fill" },
            "software-off": { kind: "wifi", bars: 3, mark: "slash" },
            "hardware-off": { kind: "wifi", bars: 3, mark: "hard-slash" },
            "hotspot": { kind: "hotspot" },
            "monitor": { kind: "monitor" },
            "ethernet": { kind: "ethernet" },
            "ethernet-no-internet": { kind: "ethernet", mark: "alert" },
            "ethernet-firewall": { kind: "ethernet", mark: "wall" },
            "ethernet-connecting": { kind: "ethernet", steps: 2, anim: "blink" }
        })[status] ?? { kind: "wifi", bars: 3, mark: "cross" }

    readonly property int bars: spec.bars ?? (signalStrength >= 0.67 ? 3 : signalStrength >= 0.34 ? 2 : signalStrength > 0 ? 1 : 0)
    readonly property int steps: spec.steps ?? 0
    // Steps on a Timer: an endless animation would keep the bar's render loop running for a change it shows four times a second.
    property int step: 0

    onStepsChanged: step = 0

    Timer {
        interval: Theme.motion.iconStep
        repeat: true
        running: root.steps > 0
        onTriggered: root.step = (root.step + 1) % root.steps
    }
    readonly property string mark: spec.mark ?? (vpn ? "shield" : "")

    function isLit(i) {
        if (spec.anim === "sweep")
            return i === step;
        if (spec.anim === "fill")
            return i < step;
        if (spec.anim === "blink")
            return step === 0;
        return spec.kind !== "wifi" || i < bars;
    }

    // Each bar fades between dim and lit.
    property real lit0: isLit(0) ? 1 : 0
    property real lit1: isLit(1) ? 1 : 0
    property real lit2: isLit(2) ? 1 : 0

    Behavior on lit0 {
        Motion {
            preset: Theme.motion.quick
        }
    }
    Behavior on lit1 {
        Motion {
            preset: Theme.motion.quick
        }
    }
    Behavior on lit2 {
        Motion {
            preset: Theme.motion.quick
        }
    }

    // Marks fade out, change, and fade back in.
    property string shownMark: ""
    property real markAlpha: 1

    onMarkChanged: markSwap.restart()
    Component.onCompleted: shownMark = mark

    SequentialAnimation {
        id: markSwap

        Motion {
            target: root
            property: "markAlpha"
            to: 0
            preset: Theme.motion.quick
        }
        ScriptAction {
            script: root.shownMark = root.mark
        }
        Motion {
            target: root
            property: "markAlpha"
            to: 1
            preset: Theme.motion.quick
        }
    }

    // The bar's size unless a list asks for its own. Drawn 14 units tall with a pixel to spare above and below.
    readonly property int canvasHeight: parent.iconSize ?? Theme.layout.barIconSize
    readonly property real unit: Theme.iconUnit(canvasHeight)

    implicitWidth: Math.ceil(20 * unit)
    implicitHeight: canvasHeight

    onLit0Changed: requestPaint()
    onLit1Changed: requestPaint()
    onLit2Changed: requestPaint()
    onShownMarkChanged: requestPaint()
    onMarkAlphaChanged: requestPaint()
    onStatusChanged: requestPaint()

    function mixed(amount) {
        const a = Theme.colors.inactive;
        const b = Theme.colors.foreground;
        return Qt.rgba(a.r + (b.r - a.r) * amount, a.g + (b.g - a.g) * amount, a.b + (b.b - a.b) * amount, 1);
    }

    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.translate(0, canvasHeight / 2 - 8 * unit);
        ctx.scale(unit, unit);
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.lineWidth = 1.6;

        // Fits each drawing to y 1 to 15, so every bar icon is exactly as tall. Badges are placed after this.
        const fit = ({ wifi: [1.053, 8.35], ethernet: [1.12, 8.5], hotspot: [0.909, 8.1], monitor: [1.085, 8] })[spec.kind];
        ctx.save();
        ctx.translate(9, 8);
        ctx.scale(fit[0], fit[0]);
        ctx.translate(-9, -fit[1]);

        if (spec.kind === "wifi")
            drawWifi(ctx);
        else if (spec.kind === "ethernet")
            drawEthernet(ctx);
        else if (spec.kind === "hotspot")
            drawHotspot(ctx);
        else
            drawMonitor(ctx);
        ctx.restore();

        ctx.globalAlpha = markAlpha;
        if (shownMark === "slash" || shownMark === "hard-slash")
            drawSlash(ctx, shownMark === "slash" ? Theme.colors.accent : Theme.colors.error);
        else if (shownMark)
            drawBadge(ctx, shownMark);
        ctx.globalAlpha = 1;
    }

    function drawWifi(ctx) {
        const cx = 9;
        const cy = 14;
        ctx.fillStyle = Theme.colors.foreground;
        ctx.beginPath();
        ctx.arc(cx, cy - 0.5, 1.5, 0, Math.PI * 2);
        ctx.fill();

        const levels = [lit0, lit1, lit2];
        for (let i = 0; i < 3; i++) {
            ctx.strokeStyle = mixed(levels[i]);
            ctx.beginPath();
            ctx.arc(cx, cy, 4.5 + i * 3.5, Math.PI * 1.25, Math.PI * 1.75);
            ctx.stroke();
        }
    }

    function drawEthernet(ctx) {
        ctx.strokeStyle = mixed(lit0);
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.moveTo(2, 3);
        ctx.lineTo(16, 3);
        ctx.lineTo(16, 11);
        ctx.lineTo(12.5, 11);
        ctx.lineTo(12.5, 14);
        ctx.lineTo(5.5, 14);
        ctx.lineTo(5.5, 11);
        ctx.lineTo(2, 11);
        ctx.closePath();
        ctx.stroke();

        ctx.lineWidth = 1.2;
        for (const x of [6, 9, 12]) {
            ctx.beginPath();
            ctx.moveTo(x, 6);
            ctx.lineTo(x, 8);
            ctx.stroke();
        }
    }

    // Hotspot: a tower sending out in color, so it cannot be mistaken for a normal connection.
    function drawHotspot(ctx) {
        const cx = 10;
        const cy = 6.5;
        ctx.strokeStyle = Theme.colors.info;
        ctx.fillStyle = Theme.colors.info;
        ctx.beginPath();
        ctx.arc(cx, cy, 1.8, 0, Math.PI * 2);
        ctx.fill();
        ctx.beginPath();
        ctx.moveTo(cx, cy);
        ctx.lineTo(cx - 3.2, 15);
        ctx.moveTo(cx, cy);
        ctx.lineTo(cx + 3.2, 15);
        ctx.moveTo(cx - 2, 11.5);
        ctx.lineTo(cx + 2, 11.5);
        ctx.stroke();
        for (const r of [4.5, 7.5]) {
            ctx.beginPath();
            ctx.arc(cx, cy, r, -Math.PI / 4, Math.PI / 4);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(cx, cy, r, Math.PI * 0.75, Math.PI * 1.25);
            ctx.stroke();
        }
    }

    // Monitor mode: listening in every direction rather than linked to an access point.
    function drawMonitor(ctx) {
        const cx = 10;
        const cy = 8;
        ctx.fillStyle = Theme.colors.special;
        ctx.beginPath();
        ctx.arc(cx, cy, 1.8, 0, Math.PI * 2);
        ctx.fill();
        ctx.strokeStyle = Theme.colors.foreground;
        for (const r of [4.5, 8]) {
            ctx.beginPath();
            ctx.arc(cx, cy, r, -Math.PI / 4, Math.PI / 4);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(cx, cy, r, Math.PI * 0.75, Math.PI * 1.25);
            ctx.stroke();
        }
    }

    function drawSlash(ctx, color) {
        for (const pass of [[Theme.colors.surface, 4], [color, 1.6]]) {
            ctx.strokeStyle = pass[0];
            ctx.lineWidth = pass[1];
            ctx.beginPath();
            ctx.moveTo(3, 1.5);
            ctx.lineTo(16, 14.5);
            ctx.stroke();
        }
    }

    // Small glyph in the bottom-right corner, cut out of whatever is under it.
    function drawBadge(ctx, mark) {
        const x = 15.5;
        const y = 11.5;
        ctx.fillStyle = Theme.colors.surface;
        ctx.beginPath();
        ctx.arc(x, y, 4.5, 0, Math.PI * 2);
        ctx.fill();

        ctx.lineWidth = 1.4;
        if (mark === "cross") {
            ctx.strokeStyle = Theme.colors.error;
            ctx.beginPath();
            ctx.moveTo(x - 2.3, y - 2.3);
            ctx.lineTo(x + 2.3, y + 2.3);
            ctx.moveTo(x + 2.3, y - 2.3);
            ctx.lineTo(x - 2.3, y + 2.3);
            ctx.stroke();
        } else if (mark === "alert") {
            ctx.strokeStyle = Theme.colors.warning;
            ctx.fillStyle = Theme.colors.warning;
            ctx.beginPath();
            ctx.moveTo(x, y - 3.2);
            ctx.lineTo(x, y + 0.6);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(x, y + 3, 0.9, 0, Math.PI * 2);
            ctx.fill();
        } else if (mark === "wall") {
            ctx.strokeStyle = Theme.colors.caution;
            ctx.lineWidth = 1.1;
            ctx.lineCap = "butt";
            ctx.strokeRect(x - 3.2, y - 3.2, 6.4, 6.4);
            ctx.beginPath();
            ctx.moveTo(x - 3.2, y);
            ctx.lineTo(x + 3.2, y);
            ctx.moveTo(x, y - 3.2);
            ctx.lineTo(x, y);
            ctx.moveTo(x - 1.6, y);
            ctx.lineTo(x - 1.6, y + 3.2);
            ctx.moveTo(x + 1.6, y);
            ctx.lineTo(x + 1.6, y + 3.2);
            ctx.stroke();
        } else if (mark === "up") {
            ctx.strokeStyle = Theme.colors.info;
            ctx.beginPath();
            ctx.moveTo(x, y + 3.2);
            ctx.lineTo(x, y - 3);
            ctx.moveTo(x - 2.6, y - 0.6);
            ctx.lineTo(x, y - 3.2);
            ctx.lineTo(x + 2.6, y - 0.6);
            ctx.stroke();
        } else if (mark === "shield") {
            ctx.fillStyle = Theme.colors.success;
            ctx.beginPath();
            ctx.moveTo(x, y - 3.8);
            ctx.lineTo(x + 3.2, y - 2.5);
            ctx.lineTo(x + 3.2, y + 0.3);
            ctx.quadraticCurveTo(x + 3, y + 2.8, x, y + 4);
            ctx.quadraticCurveTo(x - 3, y + 2.8, x - 3.2, y + 0.3);
            ctx.lineTo(x - 3.2, y - 2.5);
            ctx.closePath();
            ctx.fill();
        }
    }
}
