import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Only shows while a camera is in use. camera-watch.py reports changes as they happen.
Part {
    id: root

    slot: "cameraIcon"

    property bool cameraOn: false

    readonly property color tint: Theme.colors.error
    readonly property int iconSize: Theme.layout.barIconSize

    Process {
        running: true
        command: [Quickshell.shellPath("bar/camera-watch.py")]

        stdout: SplitParser {
            onRead: line => root.cameraOn = line.trim() === "1"
        }
    }
}
