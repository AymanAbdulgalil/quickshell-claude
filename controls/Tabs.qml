import QtQuick
import QtQuick.Layouts
import ".."

// Equal-width tabs filling their row. `options` is a list of [value, label].
Rectangle {
    id: root

    property var options: []
    property var value

    signal picked(var value)

    Layout.fillWidth: true
    implicitHeight: Theme.control.regular
    radius: Theme.shape.controlRadius
    color: Theme.colors.surfaceRaised

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.space.xxs
        spacing: Theme.space.xxs

        Repeater {
            model: root.options

            InteractiveSurface {
                id: tab

                required property var modelData

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                radius: Theme.shape.innerRadius
                selected: root.value === modelData[0]
                onClicked: root.picked(modelData[0])

                Label {
                    anchors.centerIn: parent
                    text: tab.modelData[1]
                    color: tab.contentColor

                    Behavior on color {
                        ColorMotion {
                            preset: Theme.motion.quick
                        }
                    }
                }
            }
        }
    }
}
