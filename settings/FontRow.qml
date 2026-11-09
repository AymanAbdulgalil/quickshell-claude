import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import "../theming"

// One of the preset's fonts: type to get installed families. Empty follows the main text font.
ColumnLayout {
    id: row

    required property string label
    required property string field
    readonly property string current: ThemePresets.active[field]
    readonly property var matches: {
        const q = input.text.trim().toLowerCase();
        if (!input.focused || q === "" || q === current.toLowerCase())
            return [];
        return Qt.fontFamilies().filter(f => f.toLowerCase().includes(q)).slice(0, 10);
    }

    function save(value) {
        const changes = {};
        changes[field] = value;
        ThemeManager.edit(changes);
        input.text = Qt.binding(() => row.current);
    }

    Layout.fillWidth: true
    spacing: Theme.space.xs

    SettingRow {
        label: row.label
        TextField {
            id: input

            readonly property bool focused: activeFocusInside

            width: 260
            text: row.current
            placeholder: row.field === "font" ? "Font family" : "Same as text"
            onAccepted: {
                const typed = text.trim();
                const exact = Qt.fontFamilies().find(f => f.toLowerCase() === typed.toLowerCase());
                if (exact)
                    row.save(exact);
                else if (typed === "" && row.field !== "font")
                    row.save("");
                else if (row.matches.length > 0)
                    row.save(row.matches[0]);
                else
                    text = Qt.binding(() => row.current);
            }
            onEscaped: text = Qt.binding(() => row.current)
        }
    }

    Flow {
        Layout.fillWidth: true
        visible: row.matches.length > 0
        spacing: Theme.space.xs

        Repeater {
            model: row.matches

            InteractiveSurface {
                id: chip

                required property string modelData

                width: chipName.implicitWidth + 2 * Theme.space.m
                height: Theme.control.small
                onClicked: row.save(modelData)

                Label {
                    id: chipName

                    anchors.centerIn: parent
                    text: chip.modelData
                    font.family: chip.modelData
                }
            }
        }
    }
}
