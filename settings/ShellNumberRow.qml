import QtQuick
import ".."
import "../controls"
import "../theming"

// A number stored directly on the active preset.
SettingRow {
    id: row

    required property string field
    property alias options: stepper.options
    property alias format: stepper.format
    property bool percent: false

    SettingStepper {
        id: stepper

        value: ThemePresets.active[row.field] * (row.percent ? 100 : 1)
        onPicked: v => {
            const changes = {};
            changes[row.field] = row.percent ? v / 100 : v;
            ThemeManager.edit(changes);
        }
    }
}
