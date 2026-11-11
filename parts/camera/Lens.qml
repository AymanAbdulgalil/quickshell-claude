import QtQuick
import "../.."

// A photo camera: body with a raised top and a ring for the lens. Filled: a solid body with the lens ring cut out.
// Inputs: tint, iconSize
Canvas {
    readonly property var iconWatch: [Theme.icons.style]
    onIconWatchChanged: requestPaint()
    readonly property color tint: parent.tint

    implicitWidth: parent.iconSize
    implicitHeight: parent.iconSize
    onTintChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const unit = Theme.iconUnit(height);
        ctx.translate(width / 2 - 8 * unit, height / 2 - 8 * unit);
        ctx.scale(unit, unit);
        // Fits this drawing to y 1 to 15, so every bar icon is exactly as tall.
        ctx.translate(8, 8);
        ctx.scale(1.037, 1.037);
        ctx.translate(-8, -8);
        ctx.strokeStyle = tint;
        ctx.lineWidth = Theme.icons.stroke;
        ctx.fillStyle = tint;
        ctx.lineJoin = "round";

        // Body, with the viewfinder hump on top.
        ctx.beginPath();
        ctx.moveTo(1.5, 5.5);
        ctx.arcTo(1.5, 4, 3, 4, 1.5);
        ctx.lineTo(4.6, 4);
        ctx.lineTo(5.8, 2);
        ctx.lineTo(10.2, 2);
        ctx.lineTo(11.4, 4);
        ctx.lineTo(13, 4);
        ctx.arcTo(14.5, 4, 14.5, 5.5, 1.5);
        ctx.lineTo(14.5, 12.5);
        ctx.arcTo(14.5, 14, 13, 14, 1.5);
        ctx.lineTo(3, 14);
        ctx.arcTo(1.5, 14, 1.5, 12.5, 1.5);
        ctx.closePath();
        if (Theme.icons.filled)
            ctx.fill();
        ctx.stroke();

        // The lens ring.
        if (Theme.icons.filled)
            ctx.globalCompositeOperation = "destination-out";
        ctx.beginPath();
        ctx.arc(8, 8.8, 2.8, 0, 2 * Math.PI);
        ctx.stroke();
    }
}
