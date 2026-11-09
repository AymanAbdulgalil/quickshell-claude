import QtQuick
import ".."

// Holds one bar icon that only shows sometimes (camera, recording microphone). It opens along the bar with the
// icon's size plus a gap after it, and fades the icon, so the icons beside it move instead of jumping.
Item {
    id: root

    property bool shown: false
    property real gap: Theme.layout.itemSpacing
    default property alias icon: holder.data

    readonly property real openLength: (Theme.layout.barVertical ? holder.height : holder.width) + gap

    implicitHeight: Theme.layout.barVertical ? (shown ? openLength : 0) : holder.height
    implicitWidth: Theme.layout.barVertical ? holder.width : (shown ? openLength : 0)
    clip: true

    Behavior on implicitWidth {
        Motion {
            preset: Theme.motion.standard
        }
    }

    Behavior on implicitHeight {
        Motion {
            preset: Theme.motion.standard
        }
    }

    Item {
        id: holder

        width: childrenRect.width
        height: childrenRect.height
        opacity: root.shown ? 1 : 0

        Behavior on opacity {
            Motion {
                preset: Theme.motion.standard
            }
        }
    }
}
