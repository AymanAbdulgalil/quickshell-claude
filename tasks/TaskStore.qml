pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Tasks and their reminders, kept in ~/.local/share/quickshell/tasks.json. Each task belongs to a day and may have
// a time; a task with a time can remind a while before it, as a notification.
// A task: { id, date: "2026-11-10", time: "14:30" or "", title, done, remind: minutes before (-1 for none), reminded }
// Reminders wait on one timer set to the next one due, never more than 15 minutes ahead, so a wake from sleep finds
// any it missed (sent late, up to 12 hours late). Nothing polls.
Singleton {
    id: root

    readonly property var tasks: data.tasks
    // Choices for the reminder, in minutes before the task's time.
    readonly property var remindChoices: [[-1, "None"], [0, "At time"], [5, "5 min"], [15, "15 min"], [60, "1 hour"], [1440, "1 day"]]

    function dateKey(d) {
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
    }

    function dateOf(key) {
        const [y, m, d] = key.split("-").map(Number);
        return new Date(y, m - 1, d);
    }

    // A day's tasks: those with a time first, by time, then the rest in the order they were added.
    function on(key) {
        return tasks.filter(t => t.date === key).sort((a, b) => (a.time === "") - (b.time === "") || a.time.localeCompare(b.time) || a.id - b.id);
    }

    // Tasks not yet done per day, for the calendar's dots.
    readonly property var openCounts: {
        const counts = {};
        for (const t of tasks) {
            if (!t.done)
                counts[t.date] = (counts[t.date] ?? 0) + 1;
        }
        return counts;
    }

    function add(fields) {
        const task = Object.assign({ id: Date.now(), date: "", time: "", title: "", done: false, remind: -1, reminded: false }, fields);
        data.tasks = tasks.concat([task]);
    }

    function update(id, fields) {
        // A changed time or reminder is a new reminder.
        const fresh = "time" in fields || "remind" in fields || "date" in fields ? { reminded: false } : {};
        data.tasks = tasks.map(t => t.id === id ? Object.assign({}, t, fields, fresh) : t);
    }

    function remove(id) {
        data.tasks = tasks.filter(t => t.id !== id);
    }

    // When a task's reminder is due, or null.
    function remindAt(t) {
        if (t.done || t.reminded || t.remind < 0 || !/^\d{1,2}:\d{2}$/.test(t.time))
            return null;
        const [h, m] = t.time.split(":").map(Number);
        const at = dateOf(t.date);
        at.setHours(h, m, 0, 0);
        return new Date(at.getTime() - t.remind * 60000);
    }

    function check() {
        const now = Date.now();
        let next = Infinity;
        const due = [];
        for (const t of tasks) {
            const at = remindAt(t);
            if (!at)
                continue;
            if (at.getTime() <= now) {
                if (now - at.getTime() < 12 * 3600000)
                    due.push(t);
                else
                    update(t.id, { reminded: true });
            } else {
                next = Math.min(next, at.getTime());
            }
        }
        for (const t of due) {
            const when = t.remind === 0 ? "Now" : t.remind >= 1440 ? "Tomorrow at " + t.time : "At " + t.time;
            Quickshell.execDetached(["notify-send", "-a", "Tasks", "-u", "normal", t.title, when]);
            data.tasks = tasks.map(x => x.id === t.id ? Object.assign({}, x, { reminded: true }) : x);
        }
        timer.interval = Math.max(1000, Math.min(next - now + 500, 15 * 60000));
        timer.restart();
    }

    onTasksChanged: Qt.callLater(check)

    Timer {
        id: timer

        onTriggered: root.check()
    }

    FileView {
        path: Quickshell.env("HOME") + "/.local/share/quickshell/tasks.json"
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

            property var tasks: []
        }
    }
}
