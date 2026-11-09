import QtQuick
import ".."
import "../controls"
import "../theming"

// An on or off choice from the active preset's Hyprland options.
SettingRow {
    id: row

    required property string option

    SettingSwitch {
        checked: ThemePresets.active.hypr[row.option]
        onToggled: on => ThemeManager.editHypr(row.option, on)
    }
}
