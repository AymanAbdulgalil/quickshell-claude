import QtQuick
import QtQuick.Layouts
import ".."

// Caption and hairline that starts a group of rows.
ColumnLayout {
    property alias text: caption.text

    Layout.fillWidth: true
    Layout.topMargin: Theme.space.xl
    Layout.bottomMargin: Theme.space.xs
    spacing: Theme.space.xs

    Label {
        id: caption

        color: Theme.colors.muted
        font.weight: Theme.fonts.weight
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.colors.border
    }
}
