import QtQuick
import QtQuick.Layouts
import ".."
import "../controls/Format.js" as Format
import "../controls"

ColumnLayout {
    id: page

    readonly property var idleOptions: [15, 30, 60, 90, 120, 125, 180, 300, 600, 900, 1800, 3600, Settings.never]

    spacing: Theme.space.xxs

    PageTitle {
        text: "Power"
    }

    SettingSection {
        text: "When idle"
    }
    SettingRow {
        label: "Dim screen"
        SettingStepper {
            options: page.idleOptions
            value: Settings.idleDim
            format: v => Format.duration(v, Settings.never)
            onPicked: v => Settings.idleDim = v
        }
    }
    SettingRow {
        label: "Dim to"
        SettingStepper {
            options: Format.range(5, 50, 5)
            value: Settings.dimPercent
            format: v => v + "%"
            onPicked: v => Settings.dimPercent = v
        }
    }
    SettingRow {
        label: "Screen off"
        SettingStepper {
            options: page.idleOptions
            value: Settings.idleScreenOff
            format: v => Format.duration(v, Settings.never)
            onPicked: v => Settings.idleScreenOff = v
        }
    }
    SettingRow {
        label: "Lock"
        SettingStepper {
            options: page.idleOptions
            value: Settings.idleLock
            format: v => Format.duration(v, Settings.never)
            onPicked: v => Settings.idleLock = v
        }
    }
    SettingRow {
        label: "Sleep"
        SettingStepper {
            options: page.idleOptions
            value: Settings.idleSleep
            format: v => Format.duration(v, Settings.never)
            onPicked: v => Settings.idleSleep = v
        }
    }
    SettingRow {
        label: "Closing the lid"
        Dropdown {
            options: [["sleep", "Sleep"], ["lock", "Lock"], ["nothing", "None"]]
            value: Settings.lidAction
            onPicked: v => Settings.lidAction = v
        }
    }

    SettingSection {
        text: "Battery"
    }
    SettingRow {
        label: "Saver when low"
        SettingSwitch {
            checked: Settings.autoSaver
            onToggled: on => Settings.autoSaver = on
        }
    }
    SettingRow {
        label: "Low means"
        opacity: Settings.autoSaver ? 1 : 0.5
        SettingStepper {
            options: Format.range(5, 50, 5)
            value: Settings.autoSaverPercent
            format: v => v + "%"
            onPicked: v => Settings.autoSaverPercent = v
        }
    }
}
