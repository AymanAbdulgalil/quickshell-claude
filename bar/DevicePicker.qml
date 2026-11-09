import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"

// Which speaker or microphone is in use. Opens in place, inside the panel.
ColumnLayout {
    id: root

    property var devices: []
    property var current: null
    // "output" or "input". One list open at a time, so the panel's fixed height is enough.
    required property string which
    readonly property bool expanded: AudioState.openPicker === which

    signal picked(var node)

    Layout.fillWidth: true
    spacing: Theme.space.xxs

    InteractiveSurface {
        Layout.fillWidth: true
        implicitHeight: Theme.control.small
        restColor: Theme.colors.clear
        onClicked: AudioState.openPicker = root.expanded ? "" : root.which

        Label {
            anchors.left: parent.left
            anchors.right: arrow.left
            anchors.leftMargin: Theme.space.m
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            color: Theme.colors.muted
            text: AudioState.deviceName(root.current)
        }

        Part {
            id: arrow

            anchors.right: parent.right
            anchors.rightMargin: Theme.space.xs
            anchors.verticalCenter: parent.verticalCenter
            slot: "powerGlyph"
            rotation: root.expanded ? 180 : 0

            readonly property string glyph: "chevron"
            readonly property color tint: Theme.colors.muted
            readonly property int iconSize: 12

            Behavior on rotation {
                Motion {
                    preset: Theme.motion.quick
                }
            }
        }
    }

    Repeater {
        model: root.expanded ? root.devices : []

        InteractiveSurface {
            id: device

            required property var modelData

            Layout.fillWidth: true
            implicitHeight: Theme.control.small
            restColor: Theme.colors.clear
            selected: modelData === root.current
            selectedColor: Theme.colors.surfaceHover
            onClicked: {
                AudioState.openPicker = "";
                root.picked(modelData);
            }

            Label {
                anchors.fill: parent
                anchors.leftMargin: Theme.space.m
                anchors.rightMargin: Theme.space.m
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                text: AudioState.deviceName(device.modelData)
            }
        }
    }
}
