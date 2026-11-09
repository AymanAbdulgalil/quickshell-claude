import QtQuick
import ".."

// The open list of a Dropdown.
Rectangle {
    id: list

    property var options: []
    property var value

    signal picked(var value)

    implicitHeight: Math.min(items.implicitHeight + 2 * Theme.space.xxs, 200)
    radius: Theme.shape.controlRadius
    color: Theme.colors.surfaceRaised
    border.color: Theme.colors.border
    border.width: 1

    Flickable {
        anchors.fill: parent
        anchors.margins: Theme.space.xxs
        clip: true
        contentHeight: items.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: items

            width: parent.width

            Repeater {
                model: list.options

                InteractiveSurface {
                    id: entry

                    required property var modelData

                    width: items.width
                    height: Theme.control.small
                    radius: Theme.shape.innerRadius
                    restColor: Theme.colors.clear
                    selected: modelData[0] === list.value
                    selectedColor: Theme.colors.surfaceHover
                    onClicked: list.picked(modelData[0])

                    Label {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.space.s
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: entry.modelData[1]
                    }
                }
            }
        }
    }
}
