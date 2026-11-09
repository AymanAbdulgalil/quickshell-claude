import QtQuick
import "../.."

// Inputs: hours, minutes, seconds, size
Canvas {
    // Colors below come from the theme, so repaint when it changes.
    readonly property var themeWatch: Theme.palette
    onThemeWatchChanged: requestPaint()

    readonly property int hours: parent.hours
    readonly property int minutes: parent.minutes
    readonly property int seconds: parent.seconds

    implicitWidth: parent.size
    implicitHeight: parent.size
    onSecondsChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const c = width / 2;
        const r = c - 2;
        ctx.lineCap = "round";

        ctx.strokeStyle = Theme.colors.border;
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.arc(c, c, r, 0, Math.PI * 2);
        ctx.stroke();

        for (let i = 0; i < 12; i++) {
            const a = Math.PI * i / 6;
            const major = i % 3 === 0;
            ctx.strokeStyle = major ? Theme.colors.foreground : Theme.colors.inactive;
            ctx.lineWidth = major ? 2 : 1.5;
            ctx.beginPath();
            ctx.moveTo(c + (r - (major ? 10 : 7)) * Math.sin(a), c - (r - (major ? 10 : 7)) * Math.cos(a));
            ctx.lineTo(c + (r - 3) * Math.sin(a), c - (r - 3) * Math.cos(a));
            ctx.stroke();
        }

        const hand = (angle, length, width_, color) => {
            ctx.strokeStyle = color;
            ctx.lineWidth = width_;
            ctx.beginPath();
            ctx.moveTo(c, c);
            ctx.lineTo(c + length * Math.sin(angle), c - length * Math.cos(angle));
            ctx.stroke();
        };
        hand(Math.PI * ((hours % 12) + minutes / 60) / 6, r * 0.5, 3, Theme.colors.foregroundStrong);
        hand(Math.PI * (minutes + seconds / 60) / 30, r * 0.74, 2.2, Theme.colors.foreground);
        hand(Math.PI * seconds / 30, r * 0.82, 1, Theme.colors.accent);

        ctx.fillStyle = Theme.colors.accent;
        ctx.beginPath();
        ctx.arc(c, c, 2.5, 0, Math.PI * 2);
        ctx.fill();
    }
}
