import QtQuick
import ".."
import "../controls"
import "../hyprland"

// A behaviour option as typed text (hyprland.json).
SettingRow {
    id: row

    required property string option
    property string placeholder

    TextField {
        width: 190
        placeholder: row.placeholder
        text: HyprConfig.options[row.option] ?? ""
        onFinished: if (text !== (HyprConfig.options[row.option] ?? ""))
            HyprConfig.setOption(row.option, text)
    }
}
