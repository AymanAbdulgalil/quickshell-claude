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

    Label {
        id: percent

        anchors.centerIn: parent
        visible: root.mode === "normal"
        text: "%"
        color: root.tint
        font.pixelSize: Theme.fonts.bar
        transform: Translate {
            y: Theme.layout.barTextShift
        }
        font.weight: Theme.fonts.weight
    }

    Label {
        id: alert

        anchors.centerIn: parent
        visible: root.mode === "low"
        opacity: flash.on ? 1 : 0
        text: "!"
        color: root.tint
        font.pixelSize: Theme.fonts.bar
        transform: Translate {
            y: Theme.layout.barTextShift
        }
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
    readonly property real strokeWidth: 1.4

    // Charging: an arrow that rises and fades at both ends of its travel, so it never reaches the edge of the slot.
    Canvas {
        id: arrow

        readonly property int travel: Math.max(4, Math.round(root.symbolHeight * 0.4))
        property int tick: 0
        readonly property color paintTint: root.tint
        readonly property real paintHeight: root.symbolHeight

        width: root.width
        height: Math.ceil(root.symbolHeight) + 2
        x: 0
        y: Math.round((root.height - height) / 2 + travel / 2 - tick)
        opacity: Math.min(1, Math.min(tick + 1, travel - tick) / 2)
        visible: root.mode === "charging"
        onVisibleChanged: requestPaint()
        onPaintTintChanged: requestPaint()
        onPaintHeightChanged: requestPaint()
        onWidthChanged: requestPaint()

        Timer {
            interval: Theme.motion.chargeCycle / (arrow.travel * 2)
            repeat: true
            running: root.mode === "charging"
            onTriggered: arrow.tick = (arrow.tick + 1) % (arrow.travel + 1)
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            // On a pixel centre, so the shaft stays sharp.
            const mid = Math.floor(width / 2) - 0.5;
            const top = 1 + root.strokeWidth / 2;
            const bottom = height - 1 - root.strokeWidth / 2;
            const wing = Math.min(width / 2 - 1, root.symbolHeight * 0.4);
            ctx.strokeStyle = root.tint;
            ctx.lineWidth = root.strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.beginPath();
            ctx.moveTo(mid, bottom);
            ctx.lineTo(mid, top);
            ctx.moveTo(mid - wing, top + wing);
            ctx.lineTo(mid, top);
            ctx.lineTo(mid + wing, top + wing);
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
