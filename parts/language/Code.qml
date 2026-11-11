import QtQuick
import "../.."

// Input: layoutName, e.g. "English (US)" shows EN, "Arabic" shows AR.
BarText {
    text: parent.layoutName.slice(0, 2).toUpperCase()
    color: Theme.colors.foreground
}
