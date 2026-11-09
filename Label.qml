import QtQuick

// All text in the shell. Plain text unless told otherwise, so a Wi-Fi name with "<b>" in it stays literal.
Text {
    color: Theme.colors.foreground
    textFormat: Text.PlainText
    font.family: Theme.fonts.family
    font.pixelSize: Theme.fonts.small
}
