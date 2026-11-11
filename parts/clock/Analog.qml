import QtQuick
import "../.."
import "../accent/shapes.js" as Shapes

// A 24-hour dial (2026-11-11): the hour hand goes round once a day, midnight at the top and noon at the bottom.
// Inputs: hours (0 to 23), minutes, seconds, size, and from the stopwatch and timers:
//   stopwatch: the stopwatch's runs, [{ start, stop }] in epoch ms (stop 0 while running)
//   laps: its snapshots, [{ kind, at }]; only kind "lap" is drawn
//   alarmAt: epoch ms of the next timer, or 0
//   now: epoch ms, for a run still going
// The stopwatch tints the face as wedges from the centre: while the session spans two hours or less they follow the minute
// hand (one turn an hour), after that the hour hand (one turn a day). Where the turns overlap, the tint is stronger. Tints are
// solid colours worked out from the surface, not stacked transparency. A pause leaves a gap. Each lap is the accent element
// on the rim at the hour hand's place; laps of a later day sit one orbit further in. The next timer is one hand, at its hour.
Canvas {
    // Colors below come from the theme, so repaint when it changes.
    readonly property var themeWatch: [Theme.palette, Theme.icons.mark, Theme.fonts.family]
    onThemeWatchChanged: requestPaint()

    readonly property int hours: parent.hours
    readonly property int minutes: parent.minutes
    readonly property int seconds: parent.seconds
    readonly property var stopwatch: parent.stopwatch ?? []
    readonly property var laps: (parent.laps ?? []).filter(s => s.kind === "lap")
    readonly property real alarmAt: parent.alarmAt ?? 0
    readonly property real now: parent.now ?? Date.now()

    implicitWidth: parent.size
    implicitHeight: parent.size
    onSecondsChanged: requestPaint()
    onStopwatchChanged: requestPaint()
    onLapsChanged: requestPaint()
    onAlarmAtChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const c = width / 2;
        const r = c - 4;
        const day = 86400000;
        const hour = 3600000;
        ctx.lineCap = "round";

        // Where a moment sits in a turn of `period` (an hour or a day), in local time.
        const within = (ms, period) => {
            const d = new Date(ms);
            return (((d.getHours() * 60 + d.getMinutes()) * 60 + d.getSeconds()) * 1000 + d.getMilliseconds()) % period;
        };
        // A canvas angle (0 at three o'clock) for a fraction of a turn, 0 at the top.
        const angle = turn => Math.PI * 2 * turn - Math.PI / 2;
        const tint = level => {
            const a = Theme.colors.accent;
            return Qt.tint(Theme.colors.surface, Qt.rgba(a.r, a.g, a.b, [0, 0.14, 0.26, 0.38, 0.5][Math.min(4, level)]));
        };

        // --- Stopwatch wedges
        const runs = stopwatch.map(run => ({ start: run.start, stop: run.stop || now })).filter(run => run.stop > run.start);
        if (runs.length > 0) {
            const span = runs[runs.length - 1].stop - runs[0].start;
            const period = span > 2 * hour ? day : hour;
            // Each run cut at the top of the dial into pieces of one turn or less.
            const events = [];
            for (const run of runs) {
                let left = run.stop - run.start;
                let from = within(run.start, period);
                while (left > 0) {
                    const piece = Math.min(left, period - from);
                    events.push([from, 1], [from + piece, -1]);
                    left -= piece;
                    from = 0;
                }
            }
            events.sort((a, b) => a[0] - b[0] || a[1] - b[1]);
            // How many turns cover each stretch of the dial.
            const stretches = [];
            let count = 0;
            let prev = 0;
            for (const [at, step] of events) {
                if (at > prev && count > 0)
                    stretches.push([prev, at, count]);
                count += step;
                prev = at;
            }
            const most = stretches.reduce((m, s) => Math.max(m, s[2]), 0);
            // Each level over the one below, joined into whole wedges so no seams show between neighbours.
            for (let level = 1; level <= Math.min(4, most); level++) {
                const ranges = [];
                for (const [a, b, n] of stretches) {
                    if (n < level)
                        continue;
                    if (ranges.length > 0 && Math.abs(ranges[ranges.length - 1][1] - a) < 1)
                        ranges[ranges.length - 1][1] = b;
                    else
                        ranges.push([a, b]);
                }
                ctx.fillStyle = tint(level);
                for (const [a, b] of ranges) {
                    ctx.beginPath();
                    if (b - a >= period - 1) {
                        ctx.arc(c, c, r, 0, Math.PI * 2);
                    } else {
                        ctx.moveTo(c, c);
                        ctx.arc(c, c, r, angle(a / period), angle(b / period), false);
                        ctx.closePath();
                    }
                    ctx.fill();
                }
            }
        }

        // --- Dial
        ctx.strokeStyle = Theme.colors.border;
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.arc(c, c, r, 0, Math.PI * 2);
        ctx.stroke();

        for (let i = 0; i < 24; i++) {
            const a = Math.PI * i / 12;
            const major = i % 6 === 0;
            ctx.strokeStyle = major ? Theme.colors.foreground : Theme.colors.inactive;
            ctx.lineWidth = major ? 2 : 1.2;
            const inner = r - (major ? 9 : 5.5);
            ctx.beginPath();
            ctx.moveTo(c + inner * Math.sin(a), c - inner * Math.cos(a));
            ctx.lineTo(c + (r - 3) * Math.sin(a), c - (r - 3) * Math.cos(a));
            ctx.stroke();
        }

        // 00, 06, 12, 18 inside the major ticks.
        ctx.fillStyle = Theme.colors.muted;
        ctx.font = "9px \"" + Theme.fonts.family + "\"";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        for (let i = 0; i < 4; i++) {
            const a = Math.PI * i / 2;
            ctx.fillText(String(i * 6).padStart(2, "0"), c + (r - 18) * Math.sin(a), c - (r - 18) * Math.cos(a) + 0.5);
        }

        // --- Laps, at the hour hand's place; a later day's one orbit further in.
        if (runs.length > 0) {
            for (const lap of laps) {
                const orbit = Math.max(0, Math.floor((lap.at - runs[0].start) / day));
                const radius = r - orbit * 6;
                const a = angle(within(lap.at, day) / day);
                const x = c + radius * Math.cos(a);
                const y = c + radius * Math.sin(a);
                Shapes.fill(ctx, Theme.icons.mark, x, y, 4.4, Theme.colors.surface);
                Shapes.fill(ctx, Theme.icons.mark, x, y, 3, Theme.colors.accent);
            }
        }

        const hand = (turn, length, lineWidth, color, tail) => {
            const a = Math.PI * 2 * turn;
            ctx.strokeStyle = color;
            ctx.lineWidth = lineWidth;
            ctx.beginPath();
            ctx.moveTo(c - (tail ?? 0) * Math.sin(a), c + (tail ?? 0) * Math.cos(a));
            ctx.lineTo(c + length * Math.sin(a), c - length * Math.cos(a));
            ctx.stroke();
            return [c + length * Math.sin(a), c - length * Math.cos(a)];
        };

        // --- The next timer: one hand at its hour, under the clock's own, ending in the accent element.
        if (alarmAt > 0) {
            const [x, y] = hand(within(alarmAt, day) / day, r * 0.62, 1.5, Theme.colors.warning);
            Shapes.fill(ctx, Theme.icons.mark, x, y, 3.6, Theme.colors.warning);
        }

        hand((hours + minutes / 60) / 24, r * 0.5, 3.5, Theme.colors.foregroundStrong);
        hand((minutes + seconds / 60) / 60, r * 0.76, 2, Theme.colors.foreground);
        hand(seconds / 60, r * 0.84, 1, Theme.colors.accent, r * 0.14);

        ctx.fillStyle = Theme.colors.foregroundStrong;
        ctx.beginPath();
        ctx.arc(c, c, 3.5, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = Theme.colors.accent;
        ctx.beginPath();
        ctx.arc(c, c, 1.5, 0, Math.PI * 2);
        ctx.fill();
    }
}
