import QtQuick
import "../.."

// Inputs: count, off (do not disturb), tint, iconSize
Canvas {
    // Colors below come from the theme, so repaint when it changes.
    readonly property var themeWatch: Theme.palette
    onThemeWatchChanged: requestPaint()

    readonly property color tint: parent.tint
    readonly property int count: parent.count
    readonly property bool off: parent.off

    implicitWidth: parent.iconSize
    implicitHeight: parent.iconSize
    onTintChanged: requestPaint()
    onCountChanged: requestPaint()
    onOffChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const unit = Theme.iconUnit(height);
        ctx.translate(width / 2 - 8 * unit, height / 2 - 8 * unit);
        ctx.scale(unit, unit);
        // Fits this drawing to y 1 to 15, so every bar icon is exactly as tall.
        ctx.translate(8, 8);
        ctx.scale(0.959, 0.959);
        ctx.translate(-8, -8.15);
        ctx.strokeStyle = tint;
        ctx.fillStyle = tint;
        ctx.lineWidth = 1.5;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        // Fills the 16 by 16 grid like the other status icons.
        ctx.beginPath();
        ctx.moveTo(1.8, 12);
        ctx.lineTo(3.4, 9.8);
        ctx.lineTo(3.4, 6.2);
        ctx.arc(8, 6.2, 4.6, Math.PI, 0);
        ctx.lineTo(12.6, 9.8);
        ctx.lineTo(14.2, 12);
        ctx.closePath();
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(8, 12.8, 1.9, 0, Math.PI);
        ctx.stroke();

        if (off) {
            for (const pass of [[Theme.colors.surface, 4], [Theme.colors.accent, 1.6]]) {
                ctx.strokeStyle = pass[0];
                ctx.lineWidth = pass[1];
                ctx.beginPath();
                ctx.moveTo(2, 2);
                ctx.lineTo(14, 14);
                ctx.stroke();
            }
        } else if (count > 0) {
            ctx.fillStyle = Theme.colors.surface;
            ctx.beginPath();
            ctx.arc(12.5, 3.5, 3.5, 0, Math.PI * 2);
            ctx.fill();
            ctx.fillStyle = Theme.colors.accent;
            ctx.beginPath();
            ctx.arc(12.5, 3.5, 2.4, 0, Math.PI * 2);
            ctx.fill();
        }
    }
}
