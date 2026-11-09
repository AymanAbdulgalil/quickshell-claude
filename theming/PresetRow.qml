import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: row

    property var preset
    property bool selected: false

    signal clicked

    Layout.fillWidth: true
    implicitHeight: 36
    radius: Theme.shape.controlRadius
    color: selected ? Theme.colors.surfaceHover : area.containsMouse ? Theme.colors.surfaceRaised : Theme.colors.clear

    Behavior on color {
        ColorMotion {
            preset: Theme.motion.quick
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.space.m
        anchors.rightMargin: Theme.space.m
        spacing: Theme.space.ml

        Label {
            Layout.fillWidth: true
            text: row.preset.name
            color: Theme.colors.foreground
            font.pixelSize: Theme.fonts.body
        }

        // The theme's own colors, so it can be judged before picking it.
        Row {
            spacing: Theme.space.xxs

            Repeater {
                model: [row.preset.palette.surface, row.preset.palette.surfaceHover, row.preset.palette.foreground, row.preset.palette.accent, row.preset.palette.success, row.preset.palette.warning, row.preset.palette.error, row.preset.palette.special]

                Rectangle {
                    required property string modelData

                    width: 16
                    height: 16
                    radius: 4
                    color: modelData
                    border.width: 1
                    border.color: Theme.colors.border
                }
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }
}
