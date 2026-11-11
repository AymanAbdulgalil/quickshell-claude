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
import "tasks"
import "timer"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        required property var modelData

        screen: modelData
        implicitHeight: Theme.layout.barVertical ? 0 : Theme.layout.barHeight
        implicitWidth: Theme.layout.barVertical ? Theme.layout.barHeight : 0
        color: "transparent"
        // Windows keep clear of the bar and of its inner gap. Hyprland adds the edge gap (the margin) itself.
        exclusiveZone: Theme.layout.barHeight + Theme.layout.barGapInner

        anchors {
            top: Theme.layout.barEdge !== "bottom"
            bottom: Theme.layout.barEdge !== "top"
            left: Theme.layout.barEdge !== "right"
            right: Theme.layout.barEdge !== "left"
        }

        // Each side has its own gap: the screen edge the bar is on, and its two ends. The side facing the windows
        // has no margin; its gap is in the exclusive zone.
        margins {
            top: Theme.layout.barEdge === "top" ? Theme.layout.barGapEdge : Theme.layout.barVertical ? Theme.layout.barGapStart : 0
            bottom: Theme.layout.barEdge === "bottom" ? Theme.layout.barGapEdge : Theme.layout.barVertical ? Theme.layout.barGapEnd : 0
            left: Theme.layout.barEdge === "left" ? Theme.layout.barGapEdge : Theme.layout.barVertical ? 0 : Theme.layout.barGapStart
            right: Theme.layout.barEdge === "right" ? Theme.layout.barGapEdge : Theme.layout.barVertical ? 0 : Theme.layout.barGapEnd
        }

        Rectangle {
            id: barBody

            // The bar's entrance at start: it slides in from its screen edge, fades in, or both, as the preset says.
            property real entered: 0

            // Runs once, as the bar is made. A Behavior would be skipped this early.
            Motion on entered {
                from: 0
                to: 1
                preset: Theme.motion.bar
            }

            width: parent.width
            height: parent.height
            opacity: Theme.motion.barFade ? entered : 1
            transform: Translate {
                readonly property real away: Theme.motion.barSlide ? (1 - barBody.entered) * (Theme.layout.barHeight + Theme.layout.barGapEdge) : 0

                x: Theme.layout.barEdge === "left" ? -away : Theme.layout.barEdge === "right" ? away : 0
                y: Theme.layout.barEdge === "top" ? -away : Theme.layout.barEdge === "bottom" ? away : 0
            }
            radius: Theme.shape.barRadius
            color: Theme.colors.surface
            border.color: Theme.colors.border
            border.width: Theme.shape.barBorderWidth

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
                opacity: status === Loader.Ready || !Theme.motion.barFade ? 1 : 0

                Behavior on opacity {
                    Motion {
                        preset: Theme.motion.bar
                    }
                }
            }
        }
    }
}
