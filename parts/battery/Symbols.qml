import QtQuick
import "../.."

// What sits beside the battery number.
// Inputs: mode ("normal" | "low" | "charging" | "full"), tint
Item {
    id: root

    readonly property string mode: parent.mode
    property color tint: parent.tint

    Behavior on tint {
        ColorMotion {}
    }

    // One width for every symbol, the width of %, so the number never moves when the state changes.
    implicitWidth: Math.ceil(percent.implicitWidth)
    implicitHeight: Theme.layout.barIconSize

    BarText {
        id: percent

        anchors.centerIn: parent
        visible: root.mode === "normal"
        text: "%"
        color: root.tint
    }

    BarText {
        id: alert

        anchors.centerIn: parent
        visible: root.mode === "low"
        opacity: flash.on ? 1 : 0
        text: "!"
        color: root.tint
        font.weight: Font.Bold

        Timer {
            id: flash

            property bool on: true

            interval: Theme.motion.flash
            repeat: true
            running: root.mode === "low"
            onTriggered: on = !on
        }
    }

    // The symbols below stand as tall as the digits beside them.
    readonly property real symbolHeight: Theme.active.barDigitHeight
    // Thick icons get a heavier line; filled ones a solid arrow head.
    readonly property real strokeWidth: Theme.icons.style === "thick" ? 1.9 : 1.4

    // Charging: arrow heads only, no shaft, pointing up. One head after another rises through the slot, fading in at the
    // bottom and out at the top (two overlap into a blob at bar sizes). Stepped one whole pixel at a time.
    Canvas {
        id: arrow

        readonly property real wing: Math.min(width / 2 - 1, root.symbolHeight * 0.42)
        readonly property real rise: Math.max(2, Math.round(wing * 0.75))
        // Pixels a head travels from its first row to its last.
        readonly property int travel: Math.max(4, Math.round(height - 2 - rise - root.strokeWidth))
        property int tick: 0
        readonly property color paintTint: root.tint
        readonly property real paintHeight: root.symbolHeight
        readonly property var iconWatch: [Theme.icons.style]

        onIconWatchChanged: requestPaint()
        width: root.width
        height: Math.ceil(root.symbolHeight) + 2
        y: Math.round((root.height - height) / 2)
        visible: root.mode === "charging"
        onVisibleChanged: requestPaint()
        onPaintTintChanged: requestPaint()
        onPaintHeightChanged: requestPaint()
        onWidthChanged: requestPaint()
        onTickChanged: requestPaint()

        Timer {
            interval: Theme.motion.chargeCycle / arrow.travel
            repeat: true
            running: root.mode === "charging"
            onTriggered: arrow.tick = (arrow.tick + 1) % arrow.travel
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const mid = Math.floor(width / 2) - 0.5;
            const bottom = height - 1 - root.strokeWidth / 2;
            ctx.strokeStyle = root.tint;
            ctx.lineWidth = root.strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            // 0 at the bottom of the travel, 1 at the top.
            const p = tick / (travel - 1);
            const tip = Math.round(bottom - rise - p * (travel - 1)) + 0.5;
            ctx.globalAlpha = Math.max(0.15, Math.min(1, Math.min(p, 1 - p) * 3));
            ctx.beginPath();
            ctx.moveTo(mid - wing, tip + rise);
            ctx.lineTo(mid, tip);
            ctx.lineTo(mid + wing, tip + rise);
            if (Theme.icons.filled) {
                ctx.closePath();
                ctx.fillStyle = root.tint;
                ctx.fill();
            }
            ctx.stroke();
        }
    }

    // Full: a check mark, as tall as the digits.
    Canvas {
        anchors.fill: parent
        visible: root.mode === "full"
        onVisibleChanged: requestPaint()
        readonly property color paintTint: root.tint
        readonly property real paintHeight: root.symbolHeight
        readonly property var iconWatch: [Theme.icons.style]
        onIconWatchChanged: requestPaint()
        onPaintTintChanged: requestPaint()
        onPaintHeightChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const h = root.symbolHeight - root.strokeWidth;
            const w = Math.min(width - root.strokeWidth - 1, h * 1.2);
            ctx.translate(width / 2, height / 2);
            ctx.strokeStyle = root.tint;
            ctx.lineWidth = root.strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.beginPath();
            ctx.moveTo(-w / 2, h * 0.08);
            ctx.lineTo(-w * 0.12, h / 2);
            ctx.lineTo(w / 2, -h / 2);
            ctx.stroke();
        }
    }
}
