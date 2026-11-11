import QtQuick
import ".."

// A bar icon that opens a slider panel. Scrolling on it changes the value directly.
Item {
    id: root

    property string panel
    property string slot
    property var barScreen
    property real level: 0
    property bool off: false
    // Draws the icon in the error color, such as the microphone while something records.
    property bool alert: false

    signal scrolled(bool up)

    function centre() {
        // Along the bar: where this icon's panel should centre itself.
        return Theme.layout.barVertical ? mapToItem(null, 0, height / 2).y + Theme.layout.barGapStart : mapToItem(null, width / 2, 0).x + Theme.layout.barGapStart;
    }

    function publish() {
        if (visible && width > 0)
            Panels.positions[panel] = centre();
    }

    Connections {
        target: Panels

        function onPositionsWanted() {
            root.publish();
        }
    }

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Part {
        id: icon

        slot: root.slot

        readonly property real level: root.level
        readonly property color tint: root.alert ? Theme.colors.error : Theme.colors.foreground
        readonly property int iconSize: Theme.layout.barIconSize
        readonly property bool off: root.off
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: Panels.toggle(root.panel, root.barScreen, root.centre())
        onWheel: wheel => root.scrolled(wheel.angleDelta.y > 0)
    }
}
