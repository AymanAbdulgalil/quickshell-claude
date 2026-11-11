import QtQuick
import ".."
import "../power"

Item {
    id: root

    signal clicked

    implicitWidth: Math.ceil(row.implicitWidth)
    implicitHeight: row.implicitHeight
    visible: PowerInfo.present

    Grid {
        id: row

        columns: Theme.layout.barVertical ? 1 : 2
        columnSpacing: 3
        rowSpacing: 1
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        BarText {
            text: PowerInfo.percent
            color: PowerInfo.tint
            Behavior on color {
                ColorMotion {}
            }
        }

        Part {
            slot: "batterySuffix"

            readonly property string mode: PowerInfo.mode
            readonly property color tint: PowerInfo.tint
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
