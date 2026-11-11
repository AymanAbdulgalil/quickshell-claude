import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import "../theming"
import "../controls/Format.js" as Format

// The bar and the panels of the shell itself, in the active preset: two sections, bar options then panel options
// (2026-11-11). Each has its own font, weight, corners, border, gaps and motion.
ColumnLayout {
    id: page

    readonly property var preset: ThemePresets.active
    readonly property bool vertical: Theme.layout.barVertical
    readonly property var weights: [[300, "Light"], [400, "Regular"], [500, "Medium"], [600, "Semibold"], [700, "Bold"]]

    spacing: Theme.space.xxs

    PageTitle {
        text: "Bar and panels"
    }

    // --- Bar

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
    FontRow {
        label: "Font"
        field: "barFont"
    }
    SettingRow {
        label: "Weight"
        Dropdown {
            options: page.weights
            value: page.preset.barWeight
            onPicked: v => ThemeManager.edit({ barWeight: v })
        }
    }
    ShellNumberRow {
        label: "Text size"
        field: "fontBar"
        options: Format.range(10, 18)
        format: Format.px
    }
    ShellNumberRow {
        label: "Icon size"
        field: "barIconSize"
        options: Format.range(8, 20)
        format: Format.px
    }
    ShellNumberRow {
        label: "Corner radius"
        field: "barRadius"
        options: Format.range(0, 24)
        format: Format.px
    }
    ShellNumberRow {
        label: "Border"
        field: "barBorder"
        options: Format.range(0, 3)
        format: Format.px
    }
    ShellNumberRow {
        label: "Gap from the screen edge"
        field: "barGapEdge"
        options: Format.range(0, 40)
        format: Format.px
    }
    ShellNumberRow {
        label: "Gap toward windows"
        field: "barGapInner"
        options: Format.range(0, 40)
        format: Format.px
    }
    ShellNumberRow {
        label: page.vertical ? "Gap at the top" : "Gap at the left"
        field: "barGapStart"
        options: Format.range(0, 300)
        format: Format.px
    }
    ShellNumberRow {
        label: page.vertical ? "Gap at the bottom" : "Gap at the right"
        field: "barGapEnd"
        options: Format.range(0, 300)
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
    MotionRows {
        prefix: "bar"
        slideLabel: "Slide (in at start, icons that come and go)"
    }

    // --- Panels

    SettingSection {
        Layout.topMargin: Theme.space.l
        text: "Panels"
    }
    FontRow {
        label: "Font"
        field: "panelFont"
    }
    SettingRow {
        label: "Weight of titles"
        Dropdown {
            options: page.weights
            value: page.preset.fontWeight
            onPicked: v => ThemeManager.edit({ fontWeight: v })
        }
    }
    ShellNumberRow {
        label: "Text size"
        field: "fontSmall"
        options: Format.range(9, 16)
        format: Format.px
    }
    ShellNumberRow {
        label: "Large numbers"
        field: "fontDisplay"
        options: Format.range(20, 48, 2)
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
    ShellNumberRow {
        label: "Corner radius"
        field: "widgetRadius"
        options: Format.range(0, 24)
        format: Format.px
    }
    ShellNumberRow {
        label: "Border"
        field: "panelBorder"
        options: Format.range(0, 3)
        format: Format.px
    }
    SettingRow {
        label: "Gaps follow the windows'"
        SettingSwitch {
            checked: page.preset.panelGapsFollow
            onToggled: on => ThemeManager.edit({ panelGapsFollow: on })
        }
    }
    // Following the windows, these show the gaps in use and cannot be changed.
    Repeater {
        model: [["panelBarGap", "Gap from the bar", "panelBarGap"], ["panelGapSide", "Gap from the screen's sides", "panelGapSide"],
            ["panelGapFar", "Gap from the far edge", "panelGapFar"], ["panelGapBetween", "Gap between panels", "panelGap"]]

        ShellNumberRow {
            required property var modelData

            enabled: !page.preset.panelGapsFollow
            opacity: enabled ? 1 : 0.4
            label: modelData[1]
            field: modelData[0]
            options: Format.range(0, 40)
            format: v => Format.px(page.preset.panelGapsFollow ? Theme.layout[modelData[2]] : v)
        }
    }
    MotionRows {
        prefix: "panel"
        slideLabel: "Slide from the bar"
    }
    SettingRow {
        label: "Speed of all shell animations"
        Dropdown {
            options: [[0, "Off"], [0.6, "Fast"], [1, "Normal"], [1.5, "Slow"]]
            value: page.preset.motionScale
            onPicked: v => ThemeManager.edit({ motionScale: v })
        }
    }
}
