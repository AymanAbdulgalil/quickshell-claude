import QtQuick
import "../.."

// Brightness icon: rays grow and the sun fills with the level. Becomes a moon in night mode.
// Filled: the disc above the level is faint, not empty, and the moon is solid.
// Inputs: level (0 to 1), tint, iconSize, off (night mode)
Canvas {
    readonly property var iconWatch: [Theme.icons.style]
    onIconWatchChanged: requestPaint()
    id: root

    property color tint: parent.tint
    readonly property int shown: Math.round(parent.level * 20)
    readonly property bool night: parent.off
    property real moon: night ? 1 : 0

    Behavior on moon {
        Motion {}
    }
    Behavior on tint {
        ColorMotion {}
    }

    implicitWidth: parent.iconSize
    implicitHeight: parent.iconSize
    onShownChanged: requestPaint()
    onTintChanged: requestPaint()
    onMoonChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const unit = Theme.iconUnit(height);
        ctx.translate(width / 2 - 8 * unit, height / 2 - 8 * unit);
        ctx.scale(unit, unit);
        const level = shown / 20;
        ctx.strokeStyle = tint;
        ctx.fillStyle = tint;
        ctx.lineWidth = Theme.icons.stroke;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        // Scaled by the level so it stays exactly as tall as the other icons while the rays grow.
        if (moon < 1) {
            const fit = 7 / (5.05 + 3 * level);
            ctx.save();
            ctx.translate(8, 8);
            ctx.scale(fit, fit);
            ctx.translate(-8, -8);
            ctx.globalAlpha = 1 - moon;
            const r = 2.4 + level;
            ctx.beginPath();
            ctx.arc(8, 8, r, 0, Math.PI * 2);
            ctx.stroke();
            if (Theme.icons.filled) {
                ctx.globalAlpha = (1 - moon) * 0.35;
                ctx.fill();
                ctx.globalAlpha = 1 - moon;
            }
            // The disc fills from the bottom with the level.
            ctx.save();
            ctx.beginPath();
            ctx.rect(0, 8 + r - 2 * r * level, 16, 2 * r * level);
            ctx.clip();
            ctx.beginPath();
            ctx.arc(8, 8, r, 0, Math.PI * 2);
            ctx.fill();
            ctx.restore();

            const length = 0.3 + 2 * level;
            for (let i = 0; i < 8; i++) {
                const a = Math.PI * i / 4;
                const inner = r + 1.6;
                ctx.beginPath();
                ctx.moveTo(8 + inner * Math.cos(a), 8 + inner * Math.sin(a));
                ctx.lineTo(8 + (inner + length) * Math.cos(a), 8 + (inner + length) * Math.sin(a));
                ctx.stroke();
            }
            ctx.restore();
        }
        if (moon > 0) {
            ctx.translate(8, 8);
            ctx.scale(1.037, 1.037);
            ctx.translate(-8, -8);
            ctx.globalAlpha = moon;
            ctx.beginPath();
            ctx.arc(8, 8, 6, Math.PI * 0.2, Math.PI * 1.45);
            ctx.quadraticCurveTo(5.5, 7, 12.8, 11.5);
            if (Theme.icons.filled)
                ctx.fill();
            ctx.stroke();
        }
    }
}
