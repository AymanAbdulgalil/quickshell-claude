import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import "../theming"
import "../controls/Format.js" as Format

// How Hyprland draws windows, in the active preset. Everything else visual is under All options.
ColumnLayout {
    spacing: Theme.space.xxs

    PageTitle {
        text: "Windows"
    }
    ErrorNote {
        text: ThemeManager.lastError
    }

    SettingSection {
        text: "Gaps"
    }
    HyprNumberRow {
        label: "Between windows"
        option: "general:gaps_in"
        options: Format.range(0, 30)
        format: Format.px
    }
    HyprNumberRow {
        label: "Around windows"
        option: "general:gaps_out"
        options: Format.range(0, 40)
        format: Format.px
    }

    SettingSection {
        text: "Borders and corners"
    }
    HyprNumberRow {
        label: "Border width"
        option: "general:border_size"
        options: Format.range(0, 6)
        format: Format.px
    }
    HyprNumberRow {
        label: "Corner radius"
        option: "decoration:rounding"
        options: Format.range(0, 30)
        format: Format.px
    }
    SettingRow {
        label: "Corner shape"
        Dropdown {
            options: [[2, "Round"], [3, "Soft"], [4, "Square"]]
            value: ThemePresets.active.hypr["decoration:rounding_power"]
            onPicked: v => ThemeManager.editHypr("decoration:rounding_power", v)
        }
    }
    HyprSwitchRow {
        label: "Resize by dragging a border"
        option: "general:resize_on_border"
    }

    SettingSection {
        text: "Opacity"
    }
    HyprNumberRow {
        label: "Focused window"
        option: "decoration:active_opacity"
        options: Format.range(50, 100, 5)
        percent: true
        format: v => v + "%"
    }
    HyprNumberRow {
        label: "Unfocused windows"
        option: "decoration:inactive_opacity"
        options: Format.range(50, 100, 5)
        percent: true
        format: v => v + "%"
    }
    HyprSwitchRow {
        label: "Darken unfocused windows"
        option: "decoration:dim_inactive"
    }
    HyprNumberRow {
        visible: ThemePresets.active.hypr["decoration:dim_inactive"]
        label: "Darken by"
        option: "decoration:dim_strength"
        options: Format.range(5, 70, 5)
        percent: true
        format: v => v + "%"
    }
    ShellNumberRow {
        label: "Focused window while a panel is open"
        field: "fadeFocused"
        options: Format.range(20, 100, 5)
        percent: true
        format: v => v + "%"
    }
    ShellNumberRow {
        label: "Other windows while a panel is open"
        field: "fadeUnfocused"
        options: Format.range(10, 100, 5)
        percent: true
        format: v => v + "%"
    }

    SettingSection {
        text: "Effects, which use more GPU"
    }
    HyprSwitchRow {
        label: "Shadows"
        option: "decoration:shadow:enabled"
    }
    HyprNumberRow {
        visible: ThemePresets.active.hypr["decoration:shadow:enabled"]
        label: "Shadow size"
        option: "decoration:shadow:range"
        options: Format.range(2, 40, 2)
        format: Format.px
    }
    HyprSwitchRow {
        label: "Blur behind windows"
        option: "decoration:blur:enabled"
    }
    HyprNumberRow {
        visible: ThemePresets.active.hypr["decoration:blur:enabled"]
        label: "Blur size"
        option: "decoration:blur:size"
        options: Format.range(1, 14)
    }
    HyprNumberRow {
        visible: ThemePresets.active.hypr["decoration:blur:enabled"]
        label: "Blur passes"
        option: "decoration:blur:passes"
        options: Format.range(1, 4)
    }

    SettingSection {
        text: "Tiling"
    }
    SettingRow {
        label: "Layout"
        Dropdown {
            options: [["dwindle", "Dwindle"], ["master", "Master"], ["scrolling", "Scrolling"]]
            value: ThemePresets.active.hypr["general:layout"]
            onPicked: v => ThemeManager.editHypr("general:layout", v)
        }
    }
}
