import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import ".."
import "../controls"

// Super+T: a panel with the presets in a looping row, the current one in the middle and a little larger. Arrows and Enter, the wheel, or a click pick one; Esc closes.
PanelWindow {
    id: panel

    property var homeScreen
    readonly property bool open: Panels.name === "themes" && Panels.screen === homeScreen
    readonly property var shown: ThemePresets.all
    readonly property int cardWidth: Math.round(((screen?.width ?? 1920) - 2 * Theme.layout.barMargin) * 0.75)

    function pick(preset) {
        if (preset)
            ThemeManager.apply(preset.id);
        Panels.close();
    }

    function move(by) {
        if (ring.count > 0)
            ring.currentIndex = (ring.currentIndex + by + ring.count) % ring.count;
    }

    // Follows `open` a frame later, so it still fades in when built by opening.
    property bool revealed: false

    onOpenChanged: revealed = open
    onRevealedChanged: {
        if (revealed) {
            ring.currentIndex = Math.max(0, shown.findIndex(p => p.id === ThemePresets.active.id));
            ring.positionViewAtIndex(ring.currentIndex, PathView.Center);
            card.forceActiveFocus();
        }
    }
    Component.onCompleted: Qt.callLater(() => revealed = open)

    screen: homeScreen
    visible: revealed || card.opacity > 0
    implicitWidth: cardWidth
    implicitHeight: card.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Stands clear of the bar when the bar is at the bottom.
    margins.bottom: Theme.layout.barAtBottom ? Theme.layout.barClearance : Theme.layout.barMargin

    anchors {
        bottom: true
    }

    HyprlandFocusGrab {
        windows: [panel]
        active: panel.open
        onCleared: Panels.close()
    }

    Rectangle {
        id: card

        width: parent.width
        height: body.implicitHeight + 2 * Theme.layout.panelPadding
        radius: Theme.shape.panelRadius
        color: Theme.colors.surface
        border.color: Theme.colors.border
        border.width: Theme.shape.borderWidth
        opacity: panel.revealed ? 1 : 0
        focus: true

        Keys.onEscapePressed: Panels.close()
        Keys.onLeftPressed: panel.move(-1)
        Keys.onRightPressed: panel.move(1)
        Keys.onReturnPressed: panel.pick(panel.shown[ring.currentIndex])
        Keys.onEnterPressed: panel.pick(panel.shown[ring.currentIndex])

        Behavior on opacity {
            Motion {
                preset: Theme.motion.panel
            }
        }

        ColumnLayout {
            id: body

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Theme.layout.panelPadding
            spacing: Theme.space.ml

            PathView {
                id: ring

                readonly property int slots: Math.min(count, count % 2 === 0 ? count - 1 : count, 5)

                Layout.fillWidth: true
                Layout.preferredHeight: 196
                clip: true
                model: panel.shown
                pathItemCount: Math.max(1, slots)
                interactive: false
                snapMode: PathView.SnapToItem
                highlightRangeMode: PathView.StrictlyEnforceRange
                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                highlightMoveDuration: Theme.motion.panel.duration * 1.4

                path: Path {
                    startX: 0
                    startY: ring.height / 2

                    PathLine {
                        x: ring.width
                        y: ring.height / 2
                    }
                }

                WheelHandler {
                    onWheel: event => panel.move(event.angleDelta.y > 0 ? -1 : 1)
                }

                delegate: Item {
                    id: slot

                    required property var modelData
                    required property int index
                    readonly property bool selected: PathView.isCurrentItem
                    readonly property bool inUse: modelData.id === ThemePresets.active.id

                    width: 272
                    height: ring.height
                    z: selected ? 1 : 0
                    opacity: selected ? 1 : 0.7

                    Behavior on opacity {
                        Motion {
                            preset: Theme.motion.panel
                        }
                    }

                    ClippingRectangle {
                        id: frame

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 153
                        radius: Theme.shape.controlRadius
                        color: ThemePresets.paletteOf(slot.modelData).surface
                        // Only the picture scales. Scaled native text draws its letters with uneven gaps.
                        scale: slot.selected ? 1 : 0.86
                        transformOrigin: Item.Bottom

                        Behavior on scale {
                            Motion {
                                preset: Theme.motion.panel
                            }
                        }

                        // The whole wallpaper, never cropped.
                        Image {
                            anchors.fill: parent
                            asynchronous: true
                            sourceSize.width: 544
                            fillMode: Image.PreserveAspectFit
                            source: ThemeManager.thumb(slot.modelData.wallpaper)
                        }
                    }

                    Label {
                        anchors.top: frame.bottom
                        anchors.topMargin: Theme.space.m
                        anchors.left: parent.left
                        anchors.right: parent.right
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: slot.modelData.name
                        color: slot.selected || slot.inUse ? Theme.colors.foregroundStrong : Theme.colors.muted
                        font.pixelSize: Theme.fonts.body
                        font.weight: slot.inUse ? Font.Bold : Theme.fonts.weight
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: panel.pick(slot.modelData)
                    }
                }
            }
        }
    }
}
