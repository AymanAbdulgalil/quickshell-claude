import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property string label
    property bool selected: false

    signal clicked

    Layout.fillWidth: true
    implicitHeight: Theme.control.regular
    radius: Theme.shape.controlRadius
    color: selected ? Theme.colors.surfaceHover : area.containsMouse ? Theme.colors.surfaceRaised : Theme.colors.clear

    Behavior on color {
        ColorMotion {
            preset: Theme.motion.quick
        }
    }

    // A short accent mark beside the selected tab.
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: root.selected ? 14 : 0
        radius: 2
        color: Theme.colors.accent

        Behavior on height {
            Motion {
                preset: Theme.motion.quick
            }
        }
    }

    Label {
        anchors.left: parent.left
        anchors.leftMargin: Theme.space.l
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.selected ? Theme.colors.foregroundStrong : Theme.colors.foreground
        font.pixelSize: Theme.fonts.body

        Behavior on color {
            ColorMotion {
                preset: Theme.motion.quick
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
