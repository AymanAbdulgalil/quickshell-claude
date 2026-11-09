import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."

// Top right, under the bar, on the screen in use.
PanelWindow {
    id: window

    readonly property string barEdge: Theme.layout.barEdge
    readonly property bool atBottom: barEdge === "bottom"
    readonly property int edge: Theme.layout.barEdge === "top" || atBottom ? Theme.layout.barClearance : Theme.layout.barMargin

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: Notifications.popups.length > 0
    implicitWidth: Theme.layout.notificationWidth
    // One size, with clicks only on the cards, so a new or closing card never makes the window flicker.
    implicitHeight: (screen?.height ?? 1080) - edge - Theme.layout.barMargin
    mask: Region {
        item: stack
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: !atBottom
        bottom: atBottom
        right: barEdge !== "right"
        left: barEdge === "right"
    }

    margins {
        top: atBottom ? 0 : edge
        bottom: atBottom ? edge : 0
        right: barEdge === "right" ? 0 : Theme.layout.barMargin
        left: barEdge === "right" ? Theme.layout.barClearance : 0
    }

    Column {
        id: stack

        y: window.atBottom ? window.height - height : 0
        width: parent.width
        spacing: Theme.layout.panelGap

        Repeater {
            // Newest on top; the oldest wait their turn beyond the limit.
            model: Notifications.popups.slice(-Settings.notificationMaxPopups).reverse()

            NotificationCard {
                required property var modelData

                width: parent.width
                notification: modelData
                timed: true
                onTimedOut: Notifications.removePopup(modelData)
            }
        }
    }
}
