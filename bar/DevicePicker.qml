import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"

// Which speaker or microphone is in use. Its list floats over the panel (BarPanel.popupOwner), so the panel keeps the
// height of its rows instead of saving room for an open list.
InteractiveSurface {
    id: root

    property var devices: []
    property var current: null
    // The BarPanel this sits in, which draws the open list.
    required property var panel
    readonly property bool expanded: panel.popupOwner === root
    // What the floating list reads.
    readonly property var options: devices.map(d => [d, AudioState.deviceName(d)])
    readonly property var value: current

    signal picked(var node)

    Layout.fillWidth: true
    implicitHeight: Theme.control.small
    restColor: Theme.colors.clear
    onClicked: panel.popupOwner = expanded ? null : root

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
