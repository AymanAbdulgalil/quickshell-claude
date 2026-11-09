import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."

// The window every panel lives in. It keeps one size, with input limited to the card, and only the card grows and
// shrinks: resizing the window itself looked like one panel replacing another. Panels only fade, like windows.
// placement: "right" (under the bar, right edge), "anchor" (under a bar icon, at Panels.anchorX), "center" (screen middle).
PanelWindow {
    id: panel

    required property string name
    property var homeScreen
    property var barWindow
    property string placement: "right"
    property int cardWidth: Theme.layout.panelWidth
    property int bodySpacing: Theme.space.ml
    property int bodyPadding: Theme.layout.panelPadding
    // A height the card keeps whatever it holds; 0 fits its content. Its list should use Layout.fillHeight.
    property int fixedHeight: 0
    // Exclusive: while a panel is open, windows behind it get no keys.
    property int keyboardWhenOpen: WlrKeyboardFocus.Exclusive
    default property alias body: column.data

    readonly property bool open: Panels.name === name && Panels.screen === homeScreen
    readonly property bool centered: placement === "center"
    readonly property string edge: Theme.layout.barEdge
    readonly property bool vertical: Theme.layout.barVertical
    readonly property bool atBottom: !centered && edge === "bottom"
    // From the screen edge the bar is on, to where a panel starts.
    readonly property int barEdge: Theme.layout.barClearance
    // Starts false and follows `open` a frame later, so a panel built on first open still fades in.
    property bool shown: false

    signal panelOpened
    signal panelClosed

    onOpenChanged: shown = open
    onShownChanged: {
        if (shown) {
            card.forceActiveFocus();
            panelOpened();
        } else {
            panelClosed();
        }
    }
    Component.onCompleted: Qt.callLater(() => shown = open)

    screen: homeScreen
    visible: shown || card.opacity > 0
    implicitWidth: cardWidth
    implicitHeight: centered ? (screen?.height ?? 1080) : (screen?.height ?? 1080) - (vertical ? 2 * Theme.layout.barMargin : barEdge + Theme.layout.barMargin)
    mask: Region {
        item: card
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? keyboardWhenOpen : WlrKeyboardFocus.None

    anchors {
        top: centered || edge !== "bottom"
        bottom: !centered && edge !== "top"
        left: !centered && (vertical ? edge === "left" : placement === "anchor")
        right: !centered && (vertical ? edge === "right" : placement === "right")
    }

    margins {
        top: centered ? 0 : edge === "top" ? barEdge : edge === "bottom" ? 0 : Theme.layout.barMargin
        bottom: centered ? 0 : edge === "bottom" ? barEdge : edge === "top" ? 0 : Theme.layout.barMargin
        left: edge === "left" ? barEdge : placement === "anchor" && !vertical ? Math.max(Theme.layout.barMargin, Math.min((screen?.width ?? 1920) - cardWidth - Theme.layout.barMargin, Panels.anchorX - cardWidth / 2)) : 0
        right: edge === "right" ? barEdge : placement === "right" && !vertical ? Theme.layout.barMargin : 0
    }

    // Clicking anywhere outside the panel and the bar closes it.
    HyprlandFocusGrab {
        windows: panel.barWindow ? [panel, panel.barWindow] : [panel]
        active: panel.open
        onCleared: Panels.close()
    }

    Rectangle {
        id: card

        width: parent.width
        y: {
            if (panel.centered)
                return Math.round((panel.height - height) / 2);
            if (panel.vertical)
                return panel.placement === "anchor" ? Math.max(0, Math.min(panel.height - height, Panels.anchorX - Theme.layout.barMargin - height / 2)) : panel.height - height;
            return panel.atBottom ? panel.height - height : 0;
        }
        opacity: panel.shown ? 1 : 0
        implicitHeight: panel.fixedHeight > 0 ? panel.fixedHeight : column.implicitHeight + 2 * panel.bodyPadding
        height: implicitHeight
        clip: true
        radius: Theme.shape.panelRadius
        color: Theme.colors.surface
        border.color: Theme.colors.border
        border.width: Theme.shape.borderWidth
        focus: true

        Keys.onEscapePressed: Panels.close()

        Behavior on height {
            Motion {
                preset: Theme.motion.panel
            }
        }

        Behavior on opacity {
            Motion {
                preset: Theme.motion.panel
            }
        }

        ColumnLayout {
            id: column

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: panel.bodyPadding
            height: panel.fixedHeight > 0 ? panel.fixedHeight - 2 * panel.bodyPadding : implicitHeight
            spacing: panel.bodySpacing
        }
    }
}
