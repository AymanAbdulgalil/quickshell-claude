import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

// Analog clock with digital time under it, a separator, then the calendar.
Rectangle {
    id: panel

    property bool running: false
    // Month being shown: 0 is this month.
    property int monthOffset: 0

    onRunningChanged: if (running)
        monthOffset = 0

    implicitHeight: row.implicitHeight + 2 * Theme.layout.panelPadding
    radius: Theme.shape.panelRadius
    color: Theme.colors.surface
    border.color: Theme.colors.border
    border.width: Theme.shape.borderWidth

    SystemClock {
        id: clock

        enabled: panel.running
        precision: SystemClock.Seconds
    }

    function twoDigits(n) {
        return String(n).padStart(2, "0");
    }

    MouseArea {
        anchors.fill: parent
        onWheel: wheel => panel.monthOffset += wheel.angleDelta.y > 0 ? -1 : 1
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: Theme.layout.panelPadding
        spacing: Theme.space.xl

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            // Wide enough for the clock and the date under it; the rest goes to the calendar.
            Layout.preferredWidth: 150
            Layout.minimumWidth: 150
            spacing: Theme.space.m

            Part {
                Layout.alignment: Qt.AlignHCenter
                slot: "analogClock"

                readonly property int hours: clock.hours
                readonly property int minutes: clock.minutes
                readonly property int seconds: clock.seconds
                readonly property int size: 124
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: panel.twoDigits(clock.hours % 12 || 12) + ":" + panel.twoDigits(clock.minutes)
                color: Theme.colors.foregroundStrong
                font.pixelSize: Theme.fonts.display
                font.weight: Theme.fonts.weight
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(clock.date, "dddd, d MMMM")
                color: Theme.colors.muted
            }
        }

        CalendarView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            today: clock.date
            monthOffset: panel.monthOffset
            onNavigate: by => panel.monthOffset = by === 0 ? 0 : panel.monthOffset + by
        }
    }
}
