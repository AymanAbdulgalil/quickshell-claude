import QtQuick
import ".."
import "../controls"
import "../hyprland"

// A behaviour option as a number (hyprland.json).
SettingRow {
    id: row

    required property string option
    property real fallback: 0
    property alias options: stepper.options
    property alias format: stepper.format

    SettingStepper {
        id: stepper

        value: HyprConfig.options[row.option] ?? row.fallback
        onPicked: v => HyprConfig.setOption(row.option, v)
    }
}
