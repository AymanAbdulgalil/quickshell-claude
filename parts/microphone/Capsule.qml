import QtQuick
import "../.."

// Microphone whose capsule fills with the level. Muted adds a slash.
// Inputs: level (0 to 1), tint, iconSize, off (muted)
Canvas {
    // Colors below come from the theme, so repaint when it changes.
    readonly property var themeWatch: Theme.palette
    onThemeWatchChanged: requestPaint()

    property color tint: parent.tint
    readonly property int shown: Math.round(parent.level * 10)
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
    onShownChanged: requestPaint()
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
        ctx.scale(0.903, 0.903);
        ctx.translate(-8, -8);
        ctx.strokeStyle = tint;
        ctx.fillStyle = tint;
        ctx.lineWidth = 1.5;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        // Capsule from y=1 to y=10.
        const capsule = () => {
            ctx.beginPath();
            ctx.arc(8, 3.5, 2.5, Math.PI, 0);
            ctx.lineTo(10.5, 7.5);
            ctx.arc(8, 7.5, 2.5, 0, Math.PI);
            ctx.closePath();
        };
        capsule();
        ctx.stroke();
        const top = 1 + 9 * (1 - shown / 10);
        ctx.save();
        ctx.beginPath();
        ctx.rect(0, top, 16, 16);
        ctx.clip();
        capsule();
        ctx.fill();
        ctx.restore();

        ctx.beginPath();
        ctx.arc(8, 7.5, 5, 0, Math.PI);
        ctx.moveTo(8, 12.5);
        ctx.lineTo(8, 15);
        ctx.stroke();

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
