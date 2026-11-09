import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Wayland
import ".."
import "../controls"

BarPanel {
    id: panel

    name: "bluetooth"
    cardWidth: Theme.layout.listPanelWidth
    fixedHeight: Theme.layout.listPanelHeight


    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter?.enabled ?? false
    readonly property bool blocked: adapter?.state === BluetoothAdapterState.Blocked
    readonly property var devices: adapter?.devices.values ?? []
    readonly property var mine: devices.filter(d => d.paired).slice().sort((a, b) => {
        if (a.connected !== b.connected)
            return a.connected ? -1 : 1;
        return a.name.localeCompare(b.name);
    })
    // Unnamed nearby devices only show an address, which helps nobody pair with them.
    readonly property var nearby: devices.filter(d => !d.paired && d.deviceName !== "" && d.deviceName !== d.address.replace(/:/g, "-"))

    property string expanded: ""

    // Keep rows alive across updates, instead of rebuilding every row on any change.
    ScriptModel {
        id: mineModel

        values: panel.mine
    }

    ScriptModel {
        id: nearbyModel

        values: panel.nearby
    }

    readonly property bool scanning: adapter?.discovering ?? false

    // Scans for a short while, so it does not spin and use the radio forever.
    function setScanning(on) {
        if (adapter && powered)
            adapter.discovering = on;
        if (on)
            scanStop.restart();
        else
            scanStop.stop();
    }

    Timer {
        id: scanStop

        interval: 20000
        onTriggered: panel.setScanning(false)
    }

    onPanelOpened: setScanning(true)
    onPanelClosed: {
        setScanning(false);
        expanded = "";
    }
    onPoweredChanged: setScanning(open && powered)


    // Answers pairing requests from devices that need no code. Only while the panel is open.
    Process {
        id: agent

        running: panel.open && panel.powered
        command: ["bluetoothctl", "--agent", "NoInputNoOutput"]
        stdinEnabled: true
        onStarted: agent.write("default-agent\n")
    }


    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space.s

        Label {
            Layout.fillWidth: true
            text: "Bluetooth"
        font.family: Theme.fonts.familyTitle
            color: Theme.colors.foregroundStrong
            font.pixelSize: Theme.fonts.body
            font.weight: Theme.fonts.weight
        }


        IconButton {
            glyph: "reboot"
            spinning: panel.scanning
            onClicked: panel.setScanning(!panel.scanning)
        }

        SettingSwitch {
            checked: panel.powered
            onToggled: on => panel.adapter.enabled = on
        }
    }

    Label {
        Layout.fillWidth: true
        visible: !panel.powered
        wrapMode: Text.WordWrap
        text: !panel.adapter ? "No Bluetooth adapter found." : panel.blocked ? "Bluetooth is blocked by the airplane or hardware switch." : "Bluetooth is off."
        color: Theme.colors.muted
    }

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: list.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: list

                visible: panel.powered
            width: parent.width
            spacing: Theme.space.xxs

            SettingSection {
                Layout.topMargin: 0
                visible: panel.mine.length > 0
                text: "My devices"
            }

            Repeater {
                model: mineModel

                BluetoothRow {
                    required property var modelData

                    device: modelData
                    expanded: panel.expanded === modelData.address
                    onToggled: panel.expanded = expanded ? "" : modelData.address
                }
            }

            SettingSection {
                text: "Nearby"
            }

            Label {
                Layout.fillWidth: true
                Layout.margins: Theme.space.m
                visible: panel.nearby.length === 0
                text: panel.scanning ? "Looking for devices." : "No devices found. Use the refresh button to look again."
                color: Theme.colors.muted
            }

            Repeater {
                model: nearbyModel

                BluetoothRow {
                    required property var modelData

                    device: modelData
                    expanded: panel.expanded === modelData.address
                    onToggled: panel.expanded = expanded ? "" : modelData.address
                }
            }
        }
    }
}
