import QtQuick
import ".."
import "../controls"
import "../hyprland"

// A behaviour option on or off (hyprland.json).
SettingRow {
    id: row

    required property string option
    property bool fallback: false

    SettingSwitch {
        checked: HyprConfig.options[row.option] ?? row.fallback
        onToggled: on => HyprConfig.setOption(row.option, on)
    }
}
