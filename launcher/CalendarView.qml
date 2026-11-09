import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"

// A month grid. The week starts on Saturday.
ColumnLayout {
    id: root

    property date today
    property int monthOffset: 0

    signal navigate(int by)

    readonly property date first: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
    // getDay: Sunday is 0, Saturday is 6. Days to show from the previous month.
    readonly property int lead: (first.getDay() + 1) % 7
    readonly property var cells: {
        const list = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(first.getFullYear(), first.getMonth(), 1 - lead + i);
            list.push({
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
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 27
                radius: Theme.shape.controlRadius
                color: modelData.isToday ? Theme.colors.accent : Theme.colors.clear

                Label {
                    anchors.centerIn: parent
                    text: parent.modelData.day
                    color: parent.modelData.isToday ? Theme.colors.onAccent : parent.modelData.inMonth ? Theme.colors.foreground : Theme.colors.inactive
                }
            }
        }
    }
}
