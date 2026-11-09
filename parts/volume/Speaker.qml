import QtQuick
import "../.."

// Speaker with one to three waves by level. Muted adds a slash.
// Inputs: level (0 to 1), tint, iconSize, off (muted)
Canvas {
    // Colors below come from the theme, so repaint when it changes.
    readonly property var themeWatch: Theme.palette
    onThemeWatchChanged: requestPaint()

    property color tint: parent.tint
    readonly property int waves: parent.level <= 0 ? 0 : parent.level < 0.34 ? 1 : parent.level < 0.67 ? 2 : 3
    property real slash: parent.off ? 1 : 0

    Behavior on slash {
        Motion {
            preset: Theme.motion.quick
        }
    }
    Behavior on tint {
        ColorMotion {}
    }

    implicitWidth: parent.iconSize
    implicitHeight: parent.iconSize
    onWavesChanged: requestPaint()
    onSlashChanged: requestPaint()
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
        ctx.scale(1.03, 1.03);
        ctx.translate(-8, -8);
        ctx.strokeStyle = tint;
        ctx.fillStyle = tint;
        ctx.lineWidth = 1.5;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        // Fills the 16 by 16 grid like the other status icons.
        ctx.beginPath();
        ctx.moveTo(0.8, 5);
        ctx.lineTo(3.8, 5);
        ctx.lineTo(7.4, 1.2);
        ctx.lineTo(7.4, 14.8);
        ctx.lineTo(3.8, 11);
        ctx.lineTo(0.8, 11);
        ctx.closePath();
        ctx.stroke();

        for (let i = 0; i < waves; i++) {
            ctx.beginPath();
            ctx.arc(7, 8, 3.6 + i * 2.2, -Math.PI * 0.3, Math.PI * 0.3);
            ctx.stroke();
        }

        if (slash > 0) {
            ctx.globalAlpha = slash;
            for (const pass of [[Theme.colors.surface, 4], [Theme.colors.accent, 1.6]]) {
                ctx.strokeStyle = pass[0];
                ctx.lineWidth = pass[1];
                ctx.beginPath();
                ctx.moveTo(2, 2);
                ctx.lineTo(14, 14);
                ctx.stroke();
            }
        }
    }
}
