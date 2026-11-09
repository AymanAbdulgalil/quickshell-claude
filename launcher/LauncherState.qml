pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import ".."

// What the launcher searches and how it runs things.
Singleton {
    id: root

    readonly property bool open: Panels.name === "launcher"
    property var binaries: []

    function toggle() {
        Panels.toggleOnFocused("launcher");
    }

    property real lastShortcut: 0

    function fromShortcut() {
        if (Panels.capturingKeys || Date.now() - lastShortcut < 300)
            return;
        lastShortcut = Date.now();
        toggle();
    }

    property real binariesRead: 0

    // Walking every folder on PATH each time was the slowest part of opening; programs rarely change.
    onOpenChanged: {
        if (open && Date.now() - binariesRead > 300000) {
            binariesRead = Date.now();
            binaryReader.running = true;
        }
    }

    readonly property var apps: DesktopEntries.applications.values.filter(e => !e.noDisplay)

    function usage(key) {
        return Settings.launcherUsage[key] ?? 0;
    }

    function remember(key) {
        const u = Object.assign({}, Settings.launcherUsage);
        u[key] = (u[key] ?? 0) + 1;
        Settings.launcherUsage = u;
    }

    // Lower is better; -1 means no match.
    function rank(text, query) {
        const t = text.toLowerCase();
        if (t === query)
            return 0;
        if (t.startsWith(query))
            return 1;
        const at = t.indexOf(query);
        if (at > 0)
            return /[\s\-_.]/.test(t[at - 1]) ? 2 : 3;
        return -1;
    }

    function searchApps(query) {
        const q = query.toLowerCase();
        const scored = [];
        for (const e of apps) {
            let r = q === "" ? 0 : rank(e.name, q);
            if (r < 0 && q !== "") {
                const extra = [e.genericName, e.comment].concat(e.keywords ?? []).join(" ");
                r = rank(extra, q) >= 0 ? 4 : -1;
            }
            if (r >= 0)
                scored.push({ entry: e, r: r, u: usage("app:" + e.id) });
        }
        scored.sort((a, b) => a.r - b.r || b.u - a.u || a.entry.name.localeCompare(b.entry.name));
        return scored.map(s => s.entry);
    }

    function searchBinaries(query) {
        const q = query.toLowerCase();
        const scored = [];
        for (const b of binaries) {
            const r = q === "" ? 0 : rank(b, q);
            if (r >= 0)
                scored.push({ name: b, r: r, u: usage("bin:" + b) });
            if (q === "" && scored.length > 400)
                break;
        }
        scored.sort((a, b) => a.r - b.r || b.u - a.u || a.name.localeCompare(b.name));
        return scored.slice(0, 200).map(s => s.name);
    }

    function inTerminal(args, hold) {
        const term = [Settings.terminal];
        if (hold)
            term.push("--hold");
        Quickshell.execDetached(term.concat(["-e"]).concat(args));
    }

    function runApp(entry, args, terminal) {
        remember("app:" + entry.id);
        if (args === "" && !terminal) {
            entry.execute();
            return;
        }
        const command = entry.command.concat(args === "" ? [] : args.split(/\s+/));
        if (terminal || entry.runInTerminal)
            inTerminal(command, false);
        else
            Quickshell.execDetached(command);
    }

    function runCommand(line, terminal) {
        const name = line.split(/\s+/)[0];
        remember("bin:" + name);
        if (terminal)
            inTerminal(["sh", "-c", line], true);
        else
            Quickshell.execDetached(["sh", "-c", line]);
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "launcher"
        description: "Open the launcher and time panel"
        // A release bind sends only one of these, but which one depends on how it fires.
        onPressed: root.fromShortcut()
        onReleased: root.fromShortcut()
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggle();
        }
    }

    Process {
        id: binaryReader

        command: ["sh", "-c", `IFS=:; for d in $PATH; do [ -d "$d" ] && find -L "$d" -maxdepth 1 -type f -executable -printf '%f\n' 2>/dev/null; done | sort -u`]

        stdout: StdioCollector {
            onStreamFinished: root.binaries = text.split("\n").filter(b => /^[A-Za-z0-9]/.test(b))
        }
    }
}
