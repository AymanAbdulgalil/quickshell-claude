import QtQuick
import ".."
import "../controls"
import "../theming"

// A number from the active preset's Hyprland options.
SettingRow {
    id: row

    required property string option
    property alias options: stepper.options
    property alias format: stepper.format
    // Shows and stores a fraction as a percentage.
    property bool percent: false

    SettingStepper {
        id: stepper

        value: ThemePresets.active.hypr[row.option] * (row.percent ? 100 : 1)
        onPicked: v => ThemeManager.editHypr(row.option, row.percent ? v / 100 : v)
    }
}
