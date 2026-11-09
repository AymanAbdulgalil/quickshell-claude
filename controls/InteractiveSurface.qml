import QtQuick
import ".."

// A clickable rectangle with the shell's interaction states. Put content inside it.
Rectangle {
    id: root

    property bool selected: false
    property bool armed: false
    property color restColor: Theme.colors.surfaceRaised
    property color hoverColor: Theme.colors.surfaceHover
    property color selectedColor: Theme.colors.accent
    readonly property bool hovered: area.containsMouse && enabled
    readonly property alias pressed: area.pressed
    readonly property color contentColor: armed || (selected && selectedColor === Theme.colors.accent) ? Theme.colors.onAccent : Theme.colors.foreground

    signal clicked

    radius: Theme.shape.controlRadius
    opacity: enabled ? 1 : 0.4
    color: armed ? Theme.colors.error : selected ? selectedColor : hovered ? hoverColor : restColor

    Behavior on color {
        ColorMotion {
            preset: Theme.motion.quick
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.enabled)
            root.clicked()
    }
}
