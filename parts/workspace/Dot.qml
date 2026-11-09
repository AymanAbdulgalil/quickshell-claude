import QtQuick
import "../.."

// Inputs: current, occupied
Item {
    id: root

    readonly property bool current: parent.current
    readonly property bool occupied: parent.occupied
    readonly property int pill: current ? 18 : 8

    implicitWidth: Theme.layout.barVertical ? 8 : 18
    implicitHeight: Theme.layout.barVertical ? 18 : 8

    Rectangle {
        anchors.centerIn: parent
        width: Theme.layout.barVertical ? 8 : root.pill
        height: Theme.layout.barVertical ? root.pill : 8
        radius: 4
        color: root.current ? Theme.colors.accent : root.occupied ? Theme.colors.foreground : Theme.colors.inactive

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
}
