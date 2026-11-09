import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Wayland
import ".."
import "../controls"

BarPanel {
    id: panel

    name: "network"
    cardWidth: Theme.layout.listPanelWidth
    fixedHeight: Theme.layout.listPanelHeight


    // Keeps rows alive across updates. A plain list rebuilt every row, icons included, on each signal change.
    ScriptModel {
        id: liveNetworks

        values: NetworkState.networks
    }

    property string tab: "networks"
    // The open row: a network name, or a saved connection's id.
    property string expanded: ""
    property bool hiddenFormOpen: false

    onPanelClosed: {
        expanded = "";
        hiddenFormOpen = false;
    }


    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space.s

        Label {
            Layout.fillWidth: true
            text: "Wi-Fi"
        font.family: Theme.fonts.familyTitle
            color: Theme.colors.foregroundStrong
            font.pixelSize: Theme.fonts.body
            font.weight: Theme.fonts.weight
        }


        IconButton {
            glyph: "reboot"
            spinning: NetworkState.scanning
            onClicked: NetworkState.rescan()
        }

        SettingSwitch {
            checked: NetworkState.wifiOn
            onToggled: on => Networking.wifiEnabled = on
        }
    }

    // Unmistakable while the laptop is sharing rather than connecting.
    Rectangle {
        Layout.fillWidth: true
        visible: NetworkState.hotspotOn
        implicitHeight: 34
        radius: Theme.shape.controlRadius
        color: Theme.colors.info

        Label {
            anchors.fill: parent
            anchors.margins: Theme.space.m
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: "Sharing as " + NetworkState.hotspotConfig.name + ", " + NetworkState.hotspotClients.length + (NetworkState.hotspotClients.length === 1 ? " device" : " devices")
            color: Theme.colors.onAccent
            font.weight: Theme.fonts.weight
        }
    }

    Tabs {
        options: [["networks", "Wi-Fi"], ["saved", "Saved"]]
        value: panel.tab
        onPicked: v => {
            panel.tab = v;
            panel.expanded = "";
        }
    }

    Label {
        Layout.fillWidth: true
        visible: NetworkState.lastError !== ""
        wrapMode: Text.WordWrap
        text: NetworkState.lastError
        color: Theme.colors.error
    }

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: pages.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: pages

            width: parent.width
            spacing: Theme.space.xxs

            // --- Networks in range
            ColumnLayout {
                Layout.fillWidth: true
                visible: panel.tab === "networks"
                spacing: Theme.space.xxs

                Label {
                    Layout.fillWidth: true
                    Layout.margins: Theme.space.m
                    visible: NetworkState.networks.length === 0 && NetworkState.stale.length === 0
                    wrapMode: Text.WordWrap
                    text: !NetworkState.hardwareOn ? "Wi-Fi is off at the hardware switch." : !NetworkState.wifiOn ? "Wi-Fi is off." : "Looking for networks."
                    color: Theme.colors.muted
                }

                Repeater {
                    model: liveNetworks

                    WifiRow {
                        required property var modelData

                        network: modelData
                        expanded: panel.expanded === modelData.name
                        onToggled: panel.expanded = expanded ? "" : modelData.name
                    }
                }

                // Last time's networks until the scan answers, so the list is there at once.
                Repeater {
                    model: NetworkState.stale

                    RowLayout {
                        id: staleRow

                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.control.row
                        Layout.leftMargin: Theme.space.m
                        spacing: Theme.space.ml
                        opacity: 0.5

                        Part {
                            slot: "networkIcon"

                            readonly property string netState: "wifi"
                            readonly property real signalStrength: staleRow.modelData.signalStrength
                            readonly property bool vpn: false
                            readonly property int iconSize: 16
                        }

                        Label {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: staleRow.modelData.name
                            font.pixelSize: Theme.fonts.body
                        }
                    }
                }
            }

            // --- Saved connections, most preferred first
            ColumnLayout {
                Layout.fillWidth: true
                visible: panel.tab === "saved"
                spacing: Theme.space.xxs

                Label {
                    Layout.fillWidth: true
                    Layout.margins: Theme.space.m
                    wrapMode: Text.WordWrap
                    text: "When several saved networks are in range, the highest preference connects first."
                    color: Theme.colors.muted
                }

                Repeater {
                    model: NetworkState.saved.filter(c => c.name !== "Hotspot" && !c.vpn)

                    SavedRow {
                        required property var modelData

                        connection: modelData
                        expanded: panel.expanded === modelData.uuid
                        onToggled: panel.expanded = expanded ? "" : modelData.uuid
                    }
                }
            }
        }
    }

    // Outside the scrolling list, so it stays put.
    ActionButton {
        visible: panel.tab === "networks" && !panel.hiddenFormOpen && NetworkState.wifiOn
        Layout.fillWidth: true
        label: "Join a hidden network"
        onActivated: {
            panel.hiddenFormOpen = true;
            hiddenName.focusNow();
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: panel.tab === "networks" && panel.hiddenFormOpen
        spacing: Theme.space.s

        TextField {
            id: hiddenName

            placeholder: "Network name"
        }

        TextField {
            id: hiddenPassword

            placeholder: "Password, if any"
            secret: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.s

            ActionButton {
                label: "Cancel"
                onActivated: panel.hiddenFormOpen = false
            }

            ActionButton {
                label: "Join"
                enabled: hiddenName.text !== ""
                onActivated: {
                    NetworkState.joinHidden(hiddenName.text, hiddenPassword.text);
                    hiddenName.text = "";
                    hiddenPassword.text = "";
                    panel.hiddenFormOpen = false;
                }
            }
        }
    }
}
