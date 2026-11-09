import QtQuick
import "../.."

// Input: layoutName, e.g. "English (US)" shows EN, "Arabic" shows AR.
Label {
    text: parent.layoutName.slice(0, 2).toUpperCase()
    color: Theme.colors.foreground
    font.pixelSize: Theme.fonts.bar
    transform: Translate {
        y: Theme.layout.barTextShift
    }
    font.weight: Theme.fonts.weight
}
