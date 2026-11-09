import QtQuick
import "../.."

// One bar whose full length is the battery's capacity when new.
// Inputs (fractions of that capacity): charge, capacity. Also tint.
Canvas {
    // Colors below come from the theme, so repaint when it changes.
    readonly property var themeWatch: Theme.palette
    onThemeWatchChanged: requestPaint()

    id: root

    readonly property real charge: parent.charge
    readonly property real capacity: parent.capacity
    property color tint: parent.tint

    Behavior on tint {
        ColorMotion {}
    }

    implicitHeight: 12
    onChargeChanged: requestPaint()
    onCapacityChanged: requestPaint()
    onTintChanged: requestPaint()
    onWidthChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const h = height;
        const r = Math.min(Theme.shape.controlRadius, h / 2);
        const usable = width * capacity;

        ctx.beginPath();
        ctx.moveTo(r, 0);
        ctx.arcTo(width, 0, width, h, r);
        ctx.arcTo(width, h, 0, h, r);
        ctx.arcTo(0, h, 0, 0, r);
        ctx.arcTo(0, 0, width, 0, r);
        ctx.closePath();
        ctx.clip();

        ctx.fillStyle = Theme.colors.surfaceRaised;
        ctx.fillRect(0, 0, usable, h);

        // Capacity lost to wear.
        ctx.save();
        ctx.beginPath();
        ctx.rect(usable, 0, width - usable, h);
        ctx.clip();
        ctx.strokeStyle = Theme.colors.inactive;
        ctx.lineWidth = 1;
        for (let x = usable - h; x < width; x += 4) {
            ctx.beginPath();
            ctx.moveTo(x, h);
            ctx.lineTo(x + h, 0);
            ctx.stroke();
        }
        ctx.restore();

        ctx.fillStyle = tint;
        ctx.fillRect(0, 0, width * charge, h);

        ctx.fillStyle = Theme.colors.surface;
        ctx.fillRect(usable, 0, 1.5, h);
    }
}
