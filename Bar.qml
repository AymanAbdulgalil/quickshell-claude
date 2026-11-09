import QtQuick
import Quickshell
// Not used here directly: these make Quickshell include the folders BarContents loads from.
import "bar"
import "power"
import "network"
import "bluetooth"
import "controls"
import "launcher"
import "notifications"
import "clipboard"
import "theming"
import "settings"
import "notes"
import "hyprland"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        required property var modelData

        screen: modelData
        implicitHeight: Theme.layout.barVertical ? 0 : Theme.layout.barHeight
        implicitWidth: Theme.layout.barVertical ? Theme.layout.barHeight : 0
        color: "transparent"

        anchors {
            top: Theme.layout.barEdge !== "bottom"
            bottom: Theme.layout.barEdge !== "top"
            left: Theme.layout.barEdge !== "right"
            right: Theme.layout.barEdge !== "left"
        }

        margins {
            top: Theme.layout.barEdge === "bottom" ? 0 : Theme.layout.barMargin
            bottom: Theme.layout.barEdge === "top" ? 0 : Theme.layout.barMargin
            left: Theme.layout.barEdge === "right" ? 0 : Theme.layout.barMargin
            right: Theme.layout.barEdge === "left" ? 0 : Theme.layout.barMargin
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.shape.barRadius
            color: Theme.colors.surface
            border.color: Theme.colors.border
            border.width: Theme.shape.borderWidth

            Loader {
                id: contents

                readonly property var barScreen: bar.modelData
                readonly property var barWindow: bar
                readonly property bool vertical: Theme.layout.barVertical

                // Nested Grids keep their old sizes when their columns change live, which threw the icons out of place.
                // Building the contents again for the new direction avoids that.
                onVerticalChanged: {
                    source = "";
                    source = Qt.resolvedUrl("BarContents.qml");
                }

                anchors.fill: parent
                asynchronous: true
                source: Qt.resolvedUrl("BarContents.qml")
                opacity: status === Loader.Ready ? 1 : 0

                Behavior on opacity {
                    Motion {}
                }
            }
        }
    }
}
