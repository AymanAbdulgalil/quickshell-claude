import QtQuick
import QtQuick.Layouts
import ".."

// One results column. The active column shows a highlight; the other shows none.
ListView {
    id: list

    property bool active: false
    property bool isApps: false

    signal picked(int index)

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredWidth: 1
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    highlightMoveDuration: Theme.motion.quick.duration
    highlight: Rectangle {
        radius: Theme.shape.controlRadius
        color: Theme.colors.surfaceHover
        opacity: list.active ? 1 : 0

        Behavior on opacity {
            Motion {
                preset: Theme.motion.quick
            }
        }
    }

    delegate: Item {
        id: row

        required property var modelData
        required property int index

        width: ListView.view.width
        height: 30

        Label {
            anchors.fill: parent
            anchors.leftMargin: Theme.space.ml
            anchors.rightMargin: Theme.space.ml
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: list.isApps ? row.modelData.name : row.modelData
            color: list.active && row.ListView.isCurrentItem ? Theme.colors.foregroundStrong : Theme.colors.foreground
            font.pixelSize: Theme.fonts.body

            Behavior on color {
                ColorMotion {
                    preset: Theme.motion.quick
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: list.currentIndex = row.index
            onClicked: list.picked(row.index)
        }
    }
}
