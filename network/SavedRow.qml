import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"

// One saved connection, in range or not.
ColumnLayout {
    id: root

    property var connection
    property bool expanded: false

    signal toggled

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

            Column {
                Layout.fillWidth: true

                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.connection.name
                    color: Theme.colors.foregroundStrong
                    font.pixelSize: Theme.fonts.body
                }

                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.connection.typeLabel + (root.connection.active ? ", connected" : "") + (root.connection.autoconnect ? "" : ", manual")
                    color: Theme.colors.muted
                }
            }

            Label {
                visible: root.connection.wifi
                text: root.connection.priority
                color: Theme.colors.muted
            }

            Part {
                visible: root.connection.active
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

        SavedControls {
            connection: root.connection
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.s

            ActionButton {
                label: root.connection.active ? "Disconnect" : "Connect"
                onActivated: root.connection.active ? NetworkState.bringDown(root.connection.uuid) : NetworkState.bringUp(root.connection.uuid)
            }

            ActionButton {
                label: "Forget"
                confirm: true
                onActivated: NetworkState.forget(root.connection.uuid)
            }
        }
    }
}
