import QtQuick
import "../.."
import "../../controls"

// Inputs: current, occupied
// With the dot as the accent element, the current workspace is a wide pill. With any other element (2026-11-11), each
// workspace is that element: larger and in accent for the current one.
Item {
    id: root

    readonly property bool current: parent.current
    readonly property bool occupied: parent.occupied
    readonly property bool pillStyle: Theme.icons.mark === "dot"
    readonly property int pill: current ? 18 : 8
    readonly property color tint: root.current ? Theme.colors.accent : root.occupied ? Theme.colors.foreground : Theme.colors.inactive

    implicitWidth: Theme.layout.barVertical ? 12 : 18
    implicitHeight: Theme.layout.barVertical ? 18 : 12

    Rectangle {
        anchors.centerIn: parent
        visible: root.pillStyle
        width: Theme.layout.barVertical ? 8 : root.pill
        height: Theme.layout.barVertical ? root.pill : 8
        radius: 4
        color: root.tint

        Behavior on color {
            ColorMotion {
                preset: Theme.motion.quick
            }
        }

        Behavior on width {
            Motion {
                preset: Theme.motion.quick
            }
        }

        Behavior on height {
            Motion {
                preset: Theme.motion.quick
            }
        }
    }

    AccentMark {
        anchors.centerIn: parent
        visible: !root.pillStyle
        width: 16
        height: 16
        size: root.current ? 12 : 7.5
        color: root.tint

        Behavior on color {
            ColorMotion {
                preset: Theme.motion.quick
            }
        }

        Behavior on size {
            Motion {
                preset: Theme.motion.quick
            }
        }
    }
}
