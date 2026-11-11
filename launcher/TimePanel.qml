import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../timer"

// Analog clock with digital time under it, a separator, then the calendar. Clicking a day opens its tasks; clicking
// the clock opens the stopwatch and timers (2026-11-11), which the clock also shows: stopwatch runs as tinted wedges,
// laps on the rim, and the next timer as a hand. Both clocks are 24-hour.
Rectangle {
    id: panel

    property bool running: false
    // Month being shown: 0 is this month.
    property int monthOffset: 0
    // The day whose tasks are open, if any.
    property string selectedDay: ""
    // The stopwatch and timers are open in the launcher's place.
    property bool timerOpen: false

    signal dayClicked(string key)
    signal clockClicked

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
        spacing: Theme.space.l

        ColumnLayout {
            id: clockSide

            Layout.alignment: Qt.AlignVCenter
            // Wider since 2026-11-11, for the stopwatch and timer marks; the rest goes to the calendar.
            Layout.preferredWidth: 184
            Layout.minimumWidth: 184
            spacing: Theme.space.m

            Part {
                Layout.alignment: Qt.AlignHCenter
                slot: "analogClock"

                readonly property int hours: clock.hours
                readonly property int minutes: clock.minutes
                readonly property int seconds: clock.seconds
                readonly property int size: 150
                readonly property var stopwatch: TimerStore.runs
                readonly property var laps: TimerStore.snapshots
                readonly property real alarmAt: TimerStore.nextAt
                // A run still going grows each second with the clock.
                readonly property real now: {
                    clock.seconds;
                    return Date.now();
                }

                // Opens the stopwatch and timers; again, back to the launcher.
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.clockClicked()
                }
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: panel.twoDigits(clock.hours) + ":" + panel.twoDigits(clock.minutes)
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

        // Between the clock and the calendar (2026-11-10), which leaves the calendar a little slimmer.
        Rectangle {
            Layout.fillHeight: true
            implicitWidth: 1
            color: Theme.colors.border
        }

        CalendarView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            today: clock.date
            monthOffset: panel.monthOffset
            selectedDay: panel.selectedDay
            onNavigate: by => panel.monthOffset = by === 0 ? 0 : panel.monthOffset + by
            onDayClicked: key => panel.dayClicked(key)
        }
    }
}
