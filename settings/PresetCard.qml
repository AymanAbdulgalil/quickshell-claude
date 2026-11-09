import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import ".."
import "../theming"

// A theme preset: its wallpaper, name, and a strip of its colors.
Item {
    id: root

    property var preset
    property bool selected: false
    readonly property var palette: ThemePresets.paletteOf(preset)

    signal clicked

    implicitHeight: width * 0.62 + 26

    ClippingRectangle {
        id: picture

        width: parent.width
        height: parent.width * 0.62
        radius: Theme.shape.controlRadius
        color: root.palette.surface

        Image {
            anchors.fill: parent
            asynchronous: true
            sourceSize.width: 240
            fillMode: Image.PreserveAspectCrop
            source: ThemeManager.thumb(root.preset.wallpaper)
        }

        // The preset's own colors.
        Row {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: Theme.space.s
            spacing: Theme.space.xxs

            Repeater {
                model: [root.palette.surface, root.palette.foreground, root.palette.accent, root.palette.accentAlt, root.palette.success, root.palette.warning, root.palette.error]

                Rectangle {
                    required property string modelData

                    width: 10
                    height: 10
                    radius: 5
                    color: modelData
                    border.width: 1
                    border.color: root.palette.border
                }
            }
        }
    }

    // Outline on top of the picture: accent for the preset in use.
    Rectangle {
        anchors.fill: picture
        radius: picture.radius
        color: "transparent"
        border.width: root.selected ? 2 : 1
        border.color: root.selected ? Theme.colors.accent : area.containsMouse ? Theme.colors.foreground : Theme.colors.border

        Behavior on border.color {
            ColorMotion {
                preset: Theme.motion.quick
            }
        }
    }

    Label {
        anchors.top: picture.bottom
        anchors.topMargin: 5
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.preset.name
        color: root.selected ? Theme.colors.foregroundStrong : Theme.colors.foreground
        font.weight: root.selected ? Theme.fonts.weight : Font.Normal
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
