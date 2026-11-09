import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"

RowLayout {
    id: row

    property string role
    property string label
    property bool selected: false

    signal picked

    readonly property string current: Theme.palette[role]

    onCurrentChanged: field.text = current
    Component.onCompleted: field.text = current

    Layout.fillWidth: true
    spacing: Theme.space.m

    Label {
        Layout.fillWidth: true
        text: row.label
        color: row.selected ? Theme.colors.accent : Theme.colors.foreground
    }

    Rectangle {
        implicitWidth: 22
        implicitHeight: 22
        radius: 4
        color: row.current
        border.width: 1
        border.color: Theme.colors.border

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.picked()
        }
    }

    TextField {
        id: field

        Layout.fillWidth: false
        Layout.preferredWidth: 90
        placeholder: "#rrggbb"
        onAccepted: {
            if (/^#[0-9a-fA-F]{6}$/.test(text))
                ThemeManager.setCustomColor(row.role, text.toLowerCase());
            else
                text = row.current;
        }
    }
}
