import QtQuick
import ".."

// A Markdown table drawn over its hidden source lines while it is not being edited. When it is wider than the note
// (wrapped), it scrolls sideways on its own: NoteEditor routes the wheel here and keeps the offsets, so they survive a
// rebuild. Unwrapped, it is drawn whole and the note itself scrolls.
Item {
    id: root

    required property var modelData
    property var offsets: ({})

    readonly property int key: modelData.key
    readonly property real most: Math.max(0, modelData.total - width)
    readonly property real offset: Math.min(offsets[key] ?? 0, most)

    signal scrolled(real offset)

    x: modelData.x
    y: modelData.y
    width: Math.min(modelData.total, modelData.available)
    height: modelData.height

    Item {
        anchors.fill: parent
        clip: true

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

    // Just under the table, so it never covers the last row.
    AutoScrollBar {
        id: bar

        horizontal: true
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.bottom
        height: Theme.space.s
        contentSize: root.modelData.total
        viewSize: root.width
        position: root.offset
        onMoved: p => root.scrolled(p)
    }
}
