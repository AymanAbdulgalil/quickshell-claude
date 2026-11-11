import QtQuick

// Text on the bar: bar size and weight, in a whole-pixel box as tall as an icon, with its digits centred in it.
// A second line (the clock on a vertical bar) grows the box downward.
Label {
    height: lineCount > 1 ? Math.ceil(implicitHeight) : Theme.layout.barTextBox
    verticalAlignment: Text.AlignTop
    font.family: Theme.fonts.barFamily
    font.pixelSize: Theme.fonts.bar
    font.weight: Theme.fonts.barWeight
    transform: Translate {
        y: Theme.layout.barTextShift
    }
}
