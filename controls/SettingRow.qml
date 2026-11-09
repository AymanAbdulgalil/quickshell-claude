import QtQuick
import QtQuick.Layouts
import ".."

// A label on the left, a control on the right, one row height.
RowLayout {
    id: row

    property string label
    // Optional second line, muted.
    property string hint: ""
    default property alias control: holder.data

    Layout.fillWidth: true
    Layout.minimumHeight: Theme.control.settingRow
    spacing: Theme.space.l

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 0

        Label {
            Layout.fillWidth: true
            text: row.label
            elide: Text.ElideRight
        }

        Label {
            Layout.fillWidth: true
            visible: row.hint !== ""
            text: row.hint
            elide: Text.ElideRight
            color: Theme.colors.muted
            font.pixelSize: Theme.fonts.caption
        }
    }

    Item {
        id: holder

        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}
