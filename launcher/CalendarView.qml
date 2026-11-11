import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import "../tasks"

// A month grid. The week starts on Saturday. A day can be clicked (it opens that day's tasks) and shows a dot for each
// task not yet done (the theme's accent element), up to five dots or four other
// elements, and a plus after them when there are more.
ColumnLayout {
    id: root

    property date today
    property int monthOffset: 0
    // The day whose tasks are open, as TaskStore.dateKey gives it.
    property string selectedDay: ""

    signal navigate(int by)
    signal dayClicked(string key)

    readonly property date first: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
    // getDay: Sunday is 0, Saturday is 6. Days to show from the previous month.
    readonly property int lead: (first.getDay() + 1) % 7
    readonly property var cells: {
        const list = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(first.getFullYear(), first.getMonth(), 1 - lead + i);
            list.push({
                key: TaskStore.dateKey(d),
                day: d.getDate(),
                inMonth: d.getMonth() === first.getMonth(),
                isToday: d.toDateString() === today.toDateString()
            });
        }
        return list;
    }

    spacing: Theme.space.xs

    RowLayout {
        Layout.fillWidth: true

        IconButton {
            glyph: "back"
            onClicked: root.navigate(-1)
        }

        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDate(root.first, "MMMM yyyy")
            color: Theme.colors.foregroundStrong
            font.pixelSize: Theme.fonts.body
            font.weight: Theme.fonts.weight

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.navigate(0)
            }
        }

        IconButton {
            glyph: "forward"
            onClicked: root.navigate(1)
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        columnSpacing: 1
        rowSpacing: 0

        Repeater {
            model: ["Sa", "Su", "Mo", "Tu", "We", "Th", "Fr"]

            Label {
                required property string modelData

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: 22
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
                color: Theme.colors.muted
            }
        }

        Repeater {
            model: root.cells

            Rectangle {
                id: cell

                required property var modelData

                readonly property int open: TaskStore.openCounts[modelData.key] ?? 0
                readonly property bool picked: modelData.key === root.selectedDay
                readonly property color ink: modelData.isToday ? Theme.colors.onAccent : modelData.inMonth ? Theme.colors.foreground : Theme.colors.inactive

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 27
                radius: Theme.shape.controlRadius
                color: modelData.isToday ? Theme.colors.accent : area.containsMouse || picked ? Theme.colors.surfaceHover : Theme.colors.clear
                border.width: picked ? 1 : 0
                border.color: Theme.colors.accent

                Behavior on color {
                    ColorMotion {
                        preset: Theme.motion.quick
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: cell.open > 0 ? -2 : 0
                    text: cell.modelData.day
                    color: cell.ink
                }

                // One accent element per open task, up to a row's worth, then a plus when there are more (2026-11-11).
                Row {
                    readonly property bool dots: Theme.icons.mark === "dot"
                    readonly property int most: dots ? 5 : 4
                    readonly property color tint: cell.modelData.isToday ? Theme.colors.onAccent : Theme.colors.accent

                    id: marks

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: dots ? 3 : 2
                    spacing: dots ? 2 : 1

                    Repeater {
                        model: Math.min(marks.most, cell.open)

                        Item {
                            width: marks.dots ? 3 : 5
                            height: width

                            Rectangle {
                                anchors.fill: parent
                                visible: marks.dots
                                radius: width / 2
                                color: marks.tint
                            }

                            AccentMark {
                                anchors.centerIn: parent
                                visible: !marks.dots
                                width: 7
                                height: 7
                                size: 5
                                color: marks.tint
                            }
                        }
                    }

                    // More than fit: a plus in the day's text colour, a little apart, so it never reads as one more mark.
                    Item {
                        visible: cell.open > marks.most
                        width: 7
                        height: marks.dots ? 3 : 5

                        Rectangle {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: 1
                            width: 5
                            height: 1
                            color: cell.modelData.isToday ? Theme.colors.onAccent : Theme.colors.muted
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: 1
                            width: 1
                            height: 5
                            color: cell.modelData.isToday ? Theme.colors.onAccent : Theme.colors.muted
                        }
                    }
                }

                MouseArea {
                    id: area

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dayClicked(cell.modelData.key)
                }
            }
        }
    }
}
