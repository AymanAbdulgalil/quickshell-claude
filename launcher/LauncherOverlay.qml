import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

// Launcher a little below the middle of the screen, with the time panel above it.
PanelWindow {
    id: overlay

    property var homeScreen
    readonly property bool open: Panels.name === "launcher" && Panels.screen === homeScreen

    // Follows `open` a frame later, so it still fades in when built by opening.
    property bool shown: false

    onOpenChanged: shown = open
    onShownChanged: if (shown)
        launcher.reset()
    Component.onCompleted: Qt.callLater(() => shown = open)

    screen: homeScreen
    visible: shown || stack.opacity > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Panels.close()
    }

    Column {
        id: stack

        readonly property int shift: Theme.layout.launcherShift

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + shift
        spacing: Theme.layout.panelGap

        opacity: overlay.shown ? 1 : 0

        Behavior on opacity {
            Motion {
                preset: Theme.motion.panel
            }
        }

        TimePanel {
            running: overlay.visible
            width: Theme.layout.launcherWidth
        }

        LauncherPanel {
            id: launcher

            width: Theme.layout.launcherWidth
            height: Theme.layout.launcherHeight
        }
    }
}
