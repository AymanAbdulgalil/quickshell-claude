import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."
import "../controls"
import "../theming"
import "../controls/Format.js" as Format

// The bar, panels, type and motion of the shell itself, in the active preset.
ColumnLayout {
    id: page

    readonly property var preset: ThemePresets.active
    property var cursors: []

    spacing: Theme.space.xxs

    Process {
        running: true
        command: ["sh", "-c", "for d in /usr/share/icons/*/cursors \"$HOME\"/.local/share/icons/*/cursors; do [ -d \"$d\" ] && basename \"$(dirname \"$d\")\"; done | sort -u"]

        stdout: StdioCollector {
            onStreamFinished: page.cursors = text.split("\n").filter(t => t !== "")
        }
    }

    PageTitle {
        text: "Bar and panels"
    }

    SettingSection {
        text: "Type"
    }
    ShellNumberRow {
        label: "Panel text size"
        field: "fontSmall"
        options: Format.range(9, 16)
        format: Format.px
    }
    ShellNumberRow {
        label: "Bar text size"
        field: "fontBar"
        options: Format.range(10, 18)
        format: Format.px
    }
    ShellNumberRow {
        label: "Large numbers"
        field: "fontDisplay"
        options: Format.range(20, 48, 2)
        format: Format.px
    }
    SettingRow {
        label: "Weight"
        Dropdown {
            options: [[400, "Regular"], [500, "Medium"], [600, "Semibold"]]
            value: page.preset.fontWeight
            onPicked: v => ThemeManager.edit({ fontWeight: v })
        }
    }

    SettingSection {
        text: "Bar"
    }
    SettingRow {
        label: "Position"
        Dropdown {
            options: [["top", "Top"], ["bottom", "Bottom"], ["left", "Left"], ["right", "Right"]]
            value: page.preset.barPosition
            onPicked: v => ThemeManager.edit({ barPosition: v })
        }
    }
    ShellNumberRow {
        label: "Height"
        field: "barHeight"
        options: Format.range(24, 48)
        format: Format.px
    }
    ShellNumberRow {
        label: "Padding at the ends"
        field: "barPadding"
        options: Format.range(4, 24)
        format: Format.px
    }
    ShellNumberRow {
        label: "Between icons"
        field: "barItemSpacing"
        options: Format.range(4, 24)
        format: Format.px
    }
    ShellNumberRow {
        label: "Between groups"
        field: "barGroupSpacing"
        options: Format.range(8, 40)
        format: Format.px
    }

    SettingSection {
        text: "Panels"
    }
    ShellNumberRow {
        label: "Corner radius"
        field: "widgetRadius"
        options: Format.range(0, 24)
        format: Format.px
    }
    ShellNumberRow {
        label: "Gap from the bar"
        field: "panelBarGap"
        options: Format.range(0, 30)
        format: Format.px
    }
    ShellNumberRow {
        label: "Border"
        field: "panelBorder"
        options: Format.range(0, 3)
        format: Format.px
    }
    SettingRow {
        label: "Density"
        Dropdown {
            options: [[0.9, "Compact"], [1, "Regular"], [1.15, "Roomy"]]
            value: page.preset.density
            onPicked: v => ThemeManager.edit({ density: v })
        }
    }

    SettingSection {
        text: "Motion"
    }
    SettingRow {
        label: "Animation speed"
        Dropdown {
            options: [[0, "Off"], [0.6, "Fast"], [1, "Normal"], [1.5, "Slow"]]
            value: page.preset.motionScale
            onPicked: v => ThemeManager.edit({ motionScale: v })
        }
    }
    ShellNumberRow {
        label: "Panels slide in"
        field: "panelSpeed"
        options: Format.range(60, 400, 20)
        format: v => v + " ms"
    }

    SettingSection {
        text: "Cursor"
    }
    SettingRow {
        label: "Theme"
        Dropdown {
            options: [["", "System default"]].concat(page.cursors.map(c => [c, c]))
            value: page.preset.cursorTheme
            onPicked: v => ThemeManager.edit({ cursorTheme: v })
        }
    }
    ShellNumberRow {
        label: "Size"
        field: "cursorSize"
        options: [16, 20, 24, 28, 32, 36, 40, 48]
        format: Format.px
    }
}
