import QtQuick
import "../.."

// Inputs: hours (0 to 23), minutes
Label {
    function twoDigits(n) {
        return String(n).padStart(2, "0");
    }

    // 12-hour, zero padded, no AM/PM: 01:03, 12:30.
    text: twoDigits(parent.hours % 12 || 12) + (Theme.layout.barVertical ? "\n" : ":") + twoDigits(parent.minutes)
    horizontalAlignment: Text.AlignHCenter
    color: Theme.colors.foreground
    font.pixelSize: Theme.fonts.bar
    transform: Translate {
        y: Theme.layout.barTextShift
    }
    font.weight: Theme.fonts.weight
}
