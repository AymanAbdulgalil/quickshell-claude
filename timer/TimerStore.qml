pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// The stopwatch and the timers (2026-11-11), kept in ~/.local/share/quickshell/timers.json, so both survive a restart.
//
// Stopwatch: one session of runs, each { start, stop } in epoch ms (stop is 0 while running), and its snapshots,
// each { kind: "lap" or "stop", elapsed, at }. Reset moves the session to `history` (newest first, at most 30).
// Timers: { id, at (epoch ms it rings), label, kind: "duration" or "time", length (ms, for a duration), rang }.
// A timer is picked (TimerPanel's steppers) as a length or as a time of day (24-hour, the next one to come). Ringing sends
// a notification. One Timer waits for the next one due, never more
// than 15 minutes ahead, so a wake from sleep catches up (sent up to 12 hours late). Nothing polls.
Singleton {
    id: root

    readonly property var runs: data.runs
    readonly property var snapshots: data.snapshots
    readonly property var history: data.history
    readonly property var timers: data.timers
    readonly property bool running: runs.length > 0 && runs[runs.length - 1].stop === 0
    // When the next timer rings, or 0. The time panel's clock shows it with two hands.
    readonly property real nextAt: {
        const waiting = timers.filter(t => !t.rang).map(t => t.at);
        return waiting.length > 0 ? Math.min(...waiting) : 0;
    }
    // Lengths offered as one click.
    readonly property var quickLengths: [["1m", 60000], ["5m", 300000], ["10m", 600000], ["25m", 1500000], ["1h", 3600000]]

    // --- Stopwatch

    function elapsed(now) {
        let total = 0;
        for (const r of data.runs)
            total += (r.stop || now) - r.start;
        return total;
    }

    function isRunning() {
        return data.runs.length > 0 && data.runs[data.runs.length - 1].stop === 0;
    }

    function startStop() {
        const now = Date.now();
        if (isRunning()) {
            data.snapshots = data.snapshots.concat([{ kind: "stop", elapsed: elapsed(now), at: now }]);
            data.runs = data.runs.map((r, i) => i === data.runs.length - 1 ? { start: r.start, stop: now } : r);
        } else {
            data.runs = data.runs.concat([{ start: now, stop: 0 }]);
        }
    }

    // A snapshot without stopping.
    function lap() {
        if (!isRunning())
            return;
        const now = Date.now();
        data.snapshots = data.snapshots.concat([{ kind: "lap", elapsed: elapsed(now), at: now }]);
    }

    function reset() {
        const now = Date.now();
        const total = elapsed(now);
        if (total > 0)
            data.history = [{ started: data.runs[0].start, ended: now, total: total, snapshots: data.snapshots }].concat(data.history).slice(0, 30);
        data.runs = [];
        data.snapshots = [];
    }

    function clearHistory() {
        data.history = [];
    }

    // --- Timers

    // A time of day, in minutes from midnight: the next one to come, today or tomorrow.
    function addAt(minutes, label) {
        const now = Date.now();
        const at = new Date(now);
        at.setHours(Math.floor(minutes / 60), minutes % 60, 0, 0);
        if (at.getTime() <= now)
            at.setDate(at.getDate() + 1);
        addTimer({ at: at.getTime(), kind: "time", length: 0 }, label);
    }

    function addLength(length, label) {
        addTimer({ at: Date.now() + length, kind: "duration", length: length }, label);
    }

    function addTimer(p, label) {
        // Unique even when two are added within the same millisecond.
        const id = Math.max(Date.now(), ...data.timers.map(t => t.id + 1));
        data.timers = data.timers.concat([Object.assign({ id: id, label: (label ?? "").trim(), rang: false }, p)]);
    }

    // A rung length starts over; a rung time of day goes to its next one.
    function again(id) {
        const now = Date.now();
        data.timers = data.timers.map(t => {
            if (t.id !== id)
                return t;
            if (t.kind === "duration")
                return Object.assign({}, t, { at: now + t.length, rang: false });
            const at = new Date(t.at);
            while (at.getTime() <= now)
                at.setDate(at.getDate() + 1);
            return Object.assign({}, t, { at: at.getTime(), rang: false });
        });
    }

    function remove(id) {
        data.timers = data.timers.filter(t => t.id !== id);
    }

    function clearRung() {
        data.timers = data.timers.filter(t => !t.rang);
    }

    // --- Text

    function twoDigits(n) {
        return String(n).padStart(2, "0");
    }

    // 1:02:03.4, or 02:03.4 under an hour.
    function stopwatchText(ms, tenths) {
        const s = Math.floor(ms / 1000);
        const h = Math.floor(s / 3600);
        const main = (h > 0 ? h + ":" : "") + twoDigits(Math.floor(s / 60) % 60) + ":" + twoDigits(s % 60);
        return tenths === false ? main : main + "." + Math.floor(ms / 100) % 10;
    }

    // 1:02:03 or 2:03 left, rounded up so it reads 0:00 only when it rings.
    function remainingText(ms) {
        const s = Math.max(0, Math.ceil(ms / 1000));
        const h = Math.floor(s / 3600);
        return (h > 0 ? h + ":" + twoDigits(Math.floor(s / 60) % 60) : Math.floor(s / 60)) + ":" + twoDigits(s % 60);
    }

    function lengthText(ms) {
        const s = Math.round(ms / 1000);
        const h = Math.floor(s / 3600);
        const m = Math.floor(s / 60) % 60;
        const parts = [];
        if (h > 0)
            parts.push(h + " h");
        if (m > 0)
            parts.push(m + " min");
        if (s % 60 > 0)
            parts.push(s % 60 + " s");
        return parts.join(" ");
    }

    function clockText(ms) {
        return Qt.formatTime(new Date(ms), "HH:mm");
    }

    // --- Ringing

    function check() {
        const now = Date.now();
        let next = Infinity;
        const due = [];
        for (const t of data.timers) {
            if (t.rang)
                continue;
            if (t.at <= now)
                due.push(t);
            else
                next = Math.min(next, t.at);
        }
        if (due.length > 0) {
            for (const t of due) {
                if (now - t.at > 12 * 3600000)
                    continue;
                const title = t.label !== "" ? t.label : t.kind === "duration" ? "Timer" : "Alarm";
                const body = t.kind === "duration" ? lengthText(t.length) + " timer, done at " + clockText(t.at) : "It is " + clockText(t.at);
                // Critical: it stays until dismissed and plays the warning sound.
                Quickshell.execDetached(["notify-send", "-a", "Timer", "-u", "critical", title, body]);
            }
            const ids = due.map(t => t.id);
            data.timers = data.timers.map(t => ids.includes(t.id) ? Object.assign({}, t, { rang: true }) : t);
        }
        if (next < Infinity) {
            timer.interval = Math.max(50, Math.min(next - now + 20, 15 * 60000));
            timer.restart();
        } else {
            timer.stop();
        }
    }

    onTimersChanged: Qt.callLater(check)

    Timer {
        id: timer

        onTriggered: root.check()
    }

    FileView {
        path: Quickshell.env("HOME") + "/.local/share/quickshell/timers.json"
        blockLoading: true
        // Writes at once: an async write let the file's old contents back into the adapter between quick changes.
        blockWrites: true
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: data

            property var runs: []
            property var snapshots: []
            property var history: []
            property var timers: []
        }
    }
}
