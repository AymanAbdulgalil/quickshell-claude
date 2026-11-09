import QtQuick
import QtQuick.Layouts
import ".."
import "../controls/Format.js" as Format
import "../controls"

ColumnLayout {
    id: page

    spacing: Theme.space.xxs

    PageTitle {
        text: "Display"
    }

    SettingSection {
        text: "Screen"
    }
    SettingRow {
        label: "Normal brightness"
        SettingStepper {
            options: Format.range(5, 100, 5)
            value: Math.max(0, Settings.normalBrightness) * 100
            format: v => v + "%"
            onPicked: v => Settings.normalBrightness = v / 100
        }
    }
    SettingRow {
        label: "Normal temperature"
        SettingStepper {
            options: Format.range(2500, 6500, 250)
            value: Settings.normalTemperature
            format: v => v + " K"
            onPicked: v => Settings.normalTemperature = v
        }
    }
    SettingRow {
        label: "Night brightness"
        SettingStepper {
            options: Format.range(5, 100, 5)
            value: Settings.nightBrightness * 100
            format: v => v + "%"
            onPicked: v => Settings.nightBrightness = v / 100
        }
    }
    SettingRow {
        label: "Night temperature"
        SettingStepper {
            options: Format.range(2500, 6500, 250)
            value: Settings.nightTemperature
            format: v => v + " K"
            onPicked: v => Settings.nightTemperature = v
        }
    }

    SettingSection {
        text: "Night mode"
    }
    SettingRow {
        label: "Automatic"
        SettingSwitch {
            checked: Settings.autoNight
            onToggled: on => Settings.autoNight = on
        }
    }
    SettingRow {
        label: "Starts"
        opacity: Settings.autoNight ? 1 : 0.5
        SettingStepper {
            options: Format.range(0, 1425, 15)
            value: Settings.nightStart
            format: Format.minutesOfDay
            onPicked: v => Settings.nightStart = v
        }
    }
    SettingRow {
        label: "Ends"
        opacity: Settings.autoNight ? 1 : 0.5
        SettingStepper {
            options: Format.range(0, 1425, 15)
            value: Settings.nightEnd
            format: Format.minutesOfDay
            onPicked: v => Settings.nightEnd = v
        }
    }
    SettingRow {
        label: "Fade length"
        SettingStepper {
            options: Format.range(1, 30, 1)
            value: Settings.nightFadeSeconds
            format: v => v + " s"
            onPicked: v => Settings.nightFadeSeconds = v
        }
    }

}
