import QtQuick
import ".."

// A thin scroll bar that shows while its view scrolls or the pointer is over it, then fades. Lay it along the bottom
// (horizontal) or the right edge of what it scrolls. It only shows when there is something to scroll.
Item {
    id: root

    property bool horizontal: false
    // Sizes along the bar's direction, and how far the content is scrolled.
    property real contentSize: 0
    property real viewSize: 0
    property real position: 0
    readonly property real most: Math.max(0, contentSize - viewSize)
    readonly property real length: horizontal ? width : height
    property bool awake: false

    signal moved(real position)

    function wake() {
        awake = true;
        sleep.restart();
    }

    onPositionChanged: wake()

    implicitWidth: horizontal ? 0 : Theme.space.ml
    implicitHeight: horizontal ? Theme.space.ml : 0
    visible: most > 0.5
    opacity: awake || hover.hovered || drag.pressed ? 1 : 0

    Behavior on opacity {
        Motion {
            preset: Theme.motion.standard
        }
    }

    Timer {
        id: sleep

        interval: 900
        onTriggered: root.awake = false
    }

    HoverHandler {
        id: hover
    }

    Rectangle {
        readonly property real size: Math.max(24, root.length * root.viewSize / Math.max(1, root.contentSize))
        readonly property real at: root.most > 0 ? (root.length - size) * root.position / root.most : 0

        x: root.horizontal ? at : root.width - width - 2
        y: root.horizontal ? root.height - height - 2 : at
        width: root.horizontal ? size : 4
        height: root.horizontal ? 4 : size
        radius: 2
        color: Theme.colors.muted
    }

    MouseArea {
        id: drag

        function scrollTo(at) {
            root.moved(Math.max(0, Math.min(1, at / root.length)) * root.most);
        }

        anchors.fill: parent
        preventStealing: true
        onPressed: mouse => scrollTo(root.horizontal ? mouse.x : mouse.y)
        onPositionChanged: mouse => scrollTo(root.horizontal ? mouse.x : mouse.y)
    }
}
