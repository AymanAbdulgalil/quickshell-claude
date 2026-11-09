import QtQuick
import ".."

// A choice from a list too long for segments. The list floats over the window, drawn by settings/SettingsWindow.qml.
// It is never moved there: binding this item's parent to the window's content item crashed the shell (2026-11-08).
// `options` is a list of [value, label].
InteractiveSurface {
    id: root

    property var options: []
    property var value
    property int controlWidth: 170
    readonly property bool expanded: Panels.activeDropdown === root
    readonly property var current: options.find(o => o[0] === value)

    signal picked(var value)

    width: controlWidth
    height: Theme.control.small
    implicitWidth: controlWidth
    implicitHeight: height
    onClicked: Panels.activeDropdown = expanded ? null : root
    Component.onDestruction: if (Panels.activeDropdown === root)
        Panels.activeDropdown = null

    Label {
        anchors.left: parent.left
        anchors.right: chevron.left
        anchors.leftMargin: Theme.space.m
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: root.current ? root.current[1] : String(root.value ?? "")
    }

    Part {
        id: chevron

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
