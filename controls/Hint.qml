import QtQuick
import QtQuick.Layouts
import ".."

// A muted line of help or an empty state. Wraps to the width it is given.
Label {
    Layout.fillWidth: true
    wrapMode: Text.WordWrap
    color: Theme.colors.inactive
    font.pixelSize: Theme.fonts.caption
}
