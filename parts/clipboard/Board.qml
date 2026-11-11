import QtQuick
import "../.."

// Inputs: tint, iconSize. Filled: a solid board, its clip set apart by a cut, and the lines cut out.
Canvas {
    readonly property var iconWatch: [Theme.icons.style]
    onIconWatchChanged: requestPaint()
    readonly property color tint: parent.tint

    implicitWidth: parent.iconSize
    implicitHeight: parent.iconSize
    onTintChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.scale(width / 16, height / 16);
        ctx.strokeStyle = tint;
        ctx.lineWidth = Theme.icons.stroke;
        ctx.fillStyle = tint;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.beginPath();
        ctx.moveTo(5.5, 3);
        ctx.lineTo(3, 3);
        ctx.lineTo(3, 15);
        ctx.lineTo(13, 15);
        ctx.lineTo(13, 3);
        ctx.lineTo(10.5, 3);
        if (Theme.icons.filled) {
            ctx.closePath();
            ctx.fill();
        }
        ctx.stroke();
        const clip = () => {
            ctx.beginPath();
            ctx.moveTo(5.5, 1.5);
            ctx.lineTo(10.5, 1.5);
            ctx.lineTo(10.5, 4.5);
            ctx.lineTo(5.5, 4.5);
            ctx.closePath();
        };
        if (Theme.icons.filled) {
            ctx.save();
            ctx.globalCompositeOperation = "destination-out";
            ctx.lineWidth = Theme.icons.stroke * 2.2;
            clip();
            ctx.stroke();
            ctx.restore();
            clip();
            ctx.fill();
        }
        clip();
        ctx.stroke();
        if (Theme.icons.filled)
            ctx.globalCompositeOperation = "destination-out";
        ctx.beginPath();
        ctx.moveTo(5.5, 8);
        ctx.lineTo(10.5, 8);
        ctx.moveTo(5.5, 11);
        ctx.lineTo(10.5, 11);
        ctx.stroke();
    }
}
