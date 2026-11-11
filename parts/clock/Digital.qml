import QtQuick
import "../.."

// Inputs: hours (0 to 23), minutes
BarText {
    function twoDigits(n) {
        return String(n).padStart(2, "0");
    }

    // 24-hour (2026-11-11): 01:03, 13:30.
    text: twoDigits(parent.hours) + (Theme.layout.barVertical ? "\n" : ":") + twoDigits(parent.minutes)
    horizontalAlignment: Text.AlignHCenter
    color: Theme.colors.foreground
}
