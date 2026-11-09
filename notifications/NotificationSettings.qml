import QtQuick
import QtQuick.Layouts
import ".."
import "../controls/Format.js" as Format
import "../controls"

ColumnLayout {
    id: page

    readonly property var sounds: [["message-new-instant", "Chime"], ["message", "Message"], ["bell", "Bell"], ["complete", "Complete"]]

    Layout.fillWidth: true
    spacing: Theme.space.xs

    SettingRow {
        label: "Do not disturb"
        SettingSwitch {
            checked: Settings.doNotDisturb
            onToggled: on => Settings.doNotDisturb = on
        }
    }


    SettingSection {
        text: "Sound"
    }
    SettingRow {
        label: "Play a sound"
        SettingSwitch {
            checked: Settings.notificationSound
            onToggled: on => Settings.notificationSound = on
        }
    }
    SettingRow {
        label: "Sound"
        Dropdown {
            options: page.sounds
            value: Settings.notificationSoundName
            onPicked: v => {
                Settings.notificationSoundName = v;
                Notifications.preview(v);
            }
        }
    }

    SettingSection {
        text: "Popups"
    }
    SettingRow {
        label: "Time on screen"
        SettingStepper {
            options: Format.range(2, 30)
            value: Settings.notificationSeconds
            format: v => v + " s"
            onPicked: v => Settings.notificationSeconds = v
        }
    }
    SettingRow {
        label: "Most at once"
        SettingStepper {
            options: Format.range(1, 8)
            value: Settings.notificationMaxPopups
            onPicked: v => Settings.notificationMaxPopups = v
        }
    }

    SettingSection {
        text: "By sender"
    }
    Repeater {
        model: Notifications.kinds

        SettingRow {
            required property string modelData

            label: modelData
            Dropdown {
                options: [["panel", "Show and keep"], ["popup", "Show only"], ["off", "Don't show"]]
                value: Notifications.ruleFor(parent.parent.modelData)
                onPicked: v => Notifications.setRule(parent.parent.modelData, v)
            }
        }
    }
}
