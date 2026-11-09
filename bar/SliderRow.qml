import QtQuick
import QtQuick.Layouts
import ".."

// One horizontal slider: the icon as a button (mute, night mode), the track, and the percentage.
Item {
    id: row

    property string slot
    // For slot "powerGlyph": which drawing.
    property string glyph: ""
    // Instead of the percentage.
    property string valueText: ""
    property real value: 0
    property bool off: false
    // Draws the icon in the error color, such as the microphone while something records.
    property bool alert: false

    signal moved(real value)
    signal iconClicked

    Layout.fillWidth: true
    implicitWidth: 240
    implicitHeight: 30

    Rectangle {
        id: button

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        height: 30
        radius: Theme.shape.controlRadius
        color: buttonArea.containsMouse ? Theme.colors.surfaceHover : Theme.colors.clear

        Behavior on color {
            ColorMotion {
                preset: Theme.motion.quick
            }
        }

        Part {
            anchors.centerIn: parent
            slot: row.slot

            readonly property string glyph: row.glyph
            readonly property real level: row.value
            readonly property color tint: row.alert ? Theme.colors.error : Theme.colors.foreground
            readonly property int iconSize: 16
            readonly property bool off: row.off
        }

        MouseArea {
            id: buttonArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.iconClicked()
        }
    }

    Item {
        id: track

        anchors.left: button.right
        anchors.leftMargin: 8
        anchors.right: percent.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        height: 20

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Theme.colors.surfaceRaised

            Rectangle {
                width: Math.max(height, parent.width * row.value)
                height: parent.height
                radius: parent.radius
                color: row.off ? Theme.colors.inactive : Theme.colors.accent

                Behavior on color {
                    ColorMotion {}
                }
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: (parent.width - width) * row.value
            width: 12
            height: 12
            radius: 6
            color: Theme.colors.foregroundStrong
            border.color: Theme.colors.surface
            border.width: 2
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            function setFrom(x) {
                row.moved(Math.max(0, Math.min(1, x / width)));
            }

            onPressed: mouse => setFrom(mouse.x)
            onPositionChanged: mouse => setFrom(mouse.x)
            onWheel: wheel => row.moved(Math.max(0, Math.min(1, row.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }

    Label {
        id: percent

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        horizontalAlignment: Text.AlignRight
        text: row.valueText !== "" ? row.valueText : Math.round(row.value * 100)
        color: Theme.colors.muted
    }
}
