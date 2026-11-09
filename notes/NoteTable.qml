import QtQuick
import ".."

// A Markdown table drawn over its hidden source lines while it is not being edited. Scrolls sideways when wider than the note.
Item {
    id: root

    required property var modelData
    property var offsets: ({})

    readonly property int key: modelData.key
    readonly property real most: Math.max(0, modelData.total - width)
    property real offset: Math.min(offsets[key] ?? 0, most)

    x: modelData.x
    y: modelData.y
    width: Math.min(modelData.total, modelData.available)
    height: modelData.height
    clip: true

    function scroll(by) {
        offset = Math.max(0, Math.min(most, offset + by));
        offsets[key] = offset;
    }

    WheelHandler {
        orientation: Qt.Horizontal
        onWheel: event => root.scroll(-event.angleDelta.x / 2)
    }

    WheelHandler {
        acceptedModifiers: Qt.ShiftModifier
        onWheel: event => root.scroll(-event.angleDelta.y / 2)
    }

    Item {
        x: -root.offset
        width: root.modelData.total
        height: parent.height

        Rectangle {
            width: parent.width
            height: root.modelData.rows[0].height
            color: Theme.colors.surfaceHover
        }

        Repeater {
            model: root.modelData.rows

            Item {
                id: row

                required property var modelData
                required property int index

                y: modelData.y
                width: parent.width
                height: modelData.height

                Rectangle {
                    visible: row.index > 0
                    width: parent.width
                    height: 1
                    color: Theme.colors.border
                }

                Repeater {
                    model: row.modelData.cells

                    Label {
                        required property string modelData
                        required property int index

                        x: root.modelData.columns[index] + Theme.space.m
                        anchors.verticalCenter: parent.verticalCenter
                        textFormat: Text.StyledText
                        text: modelData
                        font.family: Theme.fonts.familyMono
                        font.pixelSize: Theme.fonts.body
                        font.bold: row.index === 0
                        color: row.index === 0 ? Theme.colors.foregroundStrong : Theme.colors.foreground
                    }
                }
            }
        }

        Repeater {
            model: root.modelData.columns.slice(1, -1)

            Rectangle {
                required property var modelData

                x: modelData
                width: 1
                height: parent.height
                color: Theme.colors.border
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.colors.clear
            border.color: Theme.colors.border
            border.width: 1
        }
    }
}
