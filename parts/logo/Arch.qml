import QtQuick
import "../.."

// The Arch Linux logo, on an icon's canvas and grid like the status icons, spanning y 1 to 15 with its line (2026-11-11).
// The inner arch is a little wider than the real logo's, so it stays open at bar sizes. Thin and thick lines draw the
// outline; filled draws the logo solid. Inputs: tint, iconSize
Canvas {
    readonly property color tint: parent.tint
    readonly property var iconWatch: [Theme.icons.style]

    implicitWidth: parent.iconSize
    implicitHeight: parent.iconSize
    onIconWatchChanged: requestPaint()
    onTintChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const unit = Theme.iconUnit(height);
        // The thin line is lighter than the icons', and the thick one too: the arch closes up otherwise.
        const line = Theme.icons.stroke * 0.8;
        const inset = line / 2;
        ctx.translate(width / 2 - 7 * unit, height / 2 - 8 * unit);
        ctx.scale(unit, unit);
        ctx.strokeStyle = tint;
        ctx.fillStyle = tint;
        ctx.lineWidth = line;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.beginPath();
        ctx.moveTo(7, 1 + inset);
        ctx.lineTo(0.2 + inset, 15 - inset);
        ctx.bezierCurveTo(2.2, 13.9, 3.7, 13.1, 5.15, 12.75);
        ctx.lineTo(5.1, 11.6);
        ctx.bezierCurveTo(5.1, 9.85, 5.95, 8.75, 7, 8.75);
        ctx.bezierCurveTo(8.05, 8.75, 8.9, 9.85, 8.9, 11.6);
        ctx.lineTo(8.85, 12.75);
        ctx.bezierCurveTo(10.3, 13.1, 11.8, 13.9, 13.8 - inset, 15 - inset);
        ctx.closePath();
        if (Theme.icons.filled)
            ctx.fill();
        ctx.stroke();
    }
}
