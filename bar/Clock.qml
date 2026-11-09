import QtQuick
import Quickshell
import ".."

Part {
    slot: "clock"

    readonly property int hours: clock.hours
    readonly property int minutes: clock.minutes

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }
}
