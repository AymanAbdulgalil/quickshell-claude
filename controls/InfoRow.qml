import QtQuick
import QtQuick.Layouts
import ".."

// A fact: label on the left, value on the right. Hidden when there is no value.
RowLayout {
    property string label
    property string value

    Layout.fillWidth: true
    visible: value !== ""
    spacing: Theme.space.l

    Label {
        text: parent.label
        color: Theme.colors.muted
    }

    Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideLeft
        text: parent.value
        color: Theme.colors.foreground
    }
}
