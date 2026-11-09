import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import ".."

Part {
    id: root

    slot: "language"

    property string layoutName: ""

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "activelayout")
                return;

            const data = event.data;
            root.layoutName = data.slice(data.indexOf(",") + 1);
        }
    }

    Process {
        command: ["hyprctl", "devices", "-j"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const keyboard = JSON.parse(text).keyboards.find(k => k.main);
                if (keyboard)
                    root.layoutName = keyboard.active_keymap;
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "current", "next"])
    }
}
