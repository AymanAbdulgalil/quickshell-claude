import QtQuick
import ".."

Rectangle {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    width: 34
    height: 18
    radius: 9
    color: checked ? Theme.colors.accent : Theme.colors.surfaceRaised

    Behavior on color {
        ColorMotion {
            preset: Theme.motion.quick
        }
    }

    Rectangle {
        x: root.checked ? root.width - width - 2 : 2
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        radius: 7
        color: Theme.colors.foregroundStrong

        Behavior on x {
            Motion {
                preset: Theme.motion.quick
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
