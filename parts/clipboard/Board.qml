import QtQuick
import "../.."

// Inputs: tint, iconSize
Canvas {
    readonly property color tint: parent.tint

    implicitWidth: parent.iconSize
    implicitHeight: parent.iconSize
    onTintChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.scale(width / 16, height / 16);
        ctx.strokeStyle = tint;
        ctx.lineWidth = 1.5;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.beginPath();
        ctx.moveTo(5.5, 3);
        ctx.lineTo(3, 3);
        ctx.lineTo(3, 15);
        ctx.lineTo(13, 15);
        ctx.lineTo(13, 3);
        ctx.lineTo(10.5, 3);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(5.5, 1.5);
        ctx.lineTo(10.5, 1.5);
        ctx.lineTo(10.5, 4.5);
        ctx.lineTo(5.5, 4.5);
        ctx.closePath();
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(5.5, 8);
        ctx.lineTo(10.5, 8);
        ctx.moveTo(5.5, 11);
        ctx.lineTo(10.5, 11);
        ctx.stroke();
    }
}
