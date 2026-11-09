import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import ".."
import "../controls"

// One device. Click to open its controls.
ColumnLayout {
    id: root

    property var device
    property bool expanded: false

    signal toggled

    readonly property bool busy: device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting
    readonly property string glyphName: {
        const icon = device.icon ?? "";
        if (icon.includes("audio") || icon.includes("head"))
            return "headset";
        if (icon.includes("phone"))
            return "phone";
        if (icon.includes("computer"))
            return "computer";
        if (icon.includes("mouse"))
            return "mouse";
        if (icon.includes("keyboard"))
            return "keyboard";
        return "device";
    }

    Layout.fillWidth: true
    spacing: Theme.space.s

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Theme.control.row
        radius: Theme.shape.controlRadius
        color: rowArea.containsMouse || root.expanded ? Theme.colors.surfaceRaised : Theme.colors.clear

        Behavior on color {
            ColorMotion {
                preset: Theme.motion.quick
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.space.m
            anchors.rightMargin: Theme.space.m
            spacing: Theme.space.ml

            Part {
                slot: "powerGlyph"

                readonly property string glyph: root.glyphName
                readonly property color tint: Theme.colors.foreground
                readonly property int iconSize: 16
            }

            Column {
                Layout.fillWidth: true

                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.device.name
                    color: Theme.colors.foregroundStrong
                    font.pixelSize: Theme.fonts.body
                }

                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: {
                        if (root.device.pairing)
                            return "Pairing";
                        if (root.device.state === BluetoothDeviceState.Connecting)
                            return "Connecting";
                        if (root.device.state === BluetoothDeviceState.Disconnecting)
                            return "Disconnecting";
                        if (root.device.blocked)
                            return "Blocked";
                        if (root.device.connected)
                            return root.device.batteryAvailable ? "Connected, battery " + Math.round(root.device.battery * 100) + "%" : "Connected";
                        return root.device.paired ? "Paired" : "Not paired";
                    }
                    color: Theme.colors.muted
                }
            }

            Part {
                visible: root.device.connected
                slot: "powerGlyph"

                readonly property string glyph: "check"
                readonly property color tint: Theme.colors.accent
                readonly property int iconSize: 14
            }
        }

        MouseArea {
            id: rowArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.space.m
        Layout.rightMargin: Theme.space.m
        Layout.bottomMargin: Theme.space.s
        visible: root.expanded
        spacing: Theme.space.s

        InfoRow {
            label: "Address"
            value: root.device.address
        }

        SettingRow {
            label: "Connect automatically"
            visible: root.device.paired
            SettingSwitch {
                checked: root.device.trusted
                onToggled: on => root.device.trusted = on
            }
        }

        SettingRow {
            label: "Can wake this laptop"
            visible: root.device.paired
            SettingSwitch {
                checked: root.device.wakeAllowed
                onToggled: on => root.device.wakeAllowed = on
            }
        }

        SettingRow {
            label: "Block"
            SettingSwitch {
                checked: root.device.blocked
                onToggled: on => root.device.blocked = on
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.s

            ActionButton {
                visible: !root.device.paired
                label: root.device.pairing ? "Cancel" : "Pair"
                enabled: !root.device.blocked
                onActivated: root.device.pairing ? root.device.cancelPair() : root.device.pair()
            }

            ActionButton {
                visible: root.device.paired
                label: root.device.connected ? "Disconnect" : "Connect"
                enabled: !root.device.blocked
                busy: root.busy
                onActivated: root.device.connected ? root.device.disconnect() : root.device.connect()
            }

            ActionButton {
                visible: root.device.paired
                label: "Forget"
                confirm: true
                onActivated: root.device.forget()
            }
        }
    }
}
