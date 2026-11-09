pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import ".."

// Watches the clipboard and keeps history on disk through clip.py.
Singleton {
    id: root

    readonly property string helper: Quickshell.shellPath("clipboard/clip.py")
    readonly property string dir: Quickshell.env("HOME") + "/.local/share/quickshell/clipboard"
    property var entries: []
    property bool persistInstalled: true

    function fileUrl(entry) {
        return "file://" + dir + "/" + entry.file;
    }

    function isLink(entry) {
        return entry.kind === "text" && /^(https?:\/\/|www\.)\S+$/i.test(entry.text.trim());
    }

    function run(args) {
        Quickshell.execDetached([helper].concat(args));
        refresh.restart();
    }

    function copy(entry) {
        run(["copy", entry.id]);
    }

    function togglePin(entry) {
        run(["pin", entry.id]);
    }

    function remove(entry) {
        run(["delete", entry.id]);
    }

    function clear() {
        run(["clear"]);
    }

    function toggle() {
        Panels.toggleOnFocused("clipboard");
    }

    Timer {
        id: refresh

        interval: 250
        onTriggered: index.reload()
    }

    FileView {
        id: index

        path: root.dir + "/index.json"
        printErrors: false
        onLoaded: {
            try {
                root.entries = JSON.parse(text());
            } catch (e) {
                root.entries = [];
            }
        }
    }

    // Records every change. clip.py prints a line when the history changed.
    Process {
        running: true
        command: ["wl-paste", "--watch", root.helper, "store"]

        stdout: SplitParser {
            onRead: refresh.restart()
        }
    }

    // Keeps a copy alive after its source window closes, with every format the source offered.
    Process {
        id: persist

        running: true
        command: ["sh", "-c", "exec wl-clip-persist --clipboard regular"]
        onExited: code => root.persistInstalled = code !== 127
    }

    // After a reboot the clipboard is empty: bring back the newest copy.
    Process {
        running: true
        command: [root.helper, "restore"]
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "clipboard"
        description: "Open clipboard history"
        onPressed: root.toggle()
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            root.toggle();
        }
    }
}
