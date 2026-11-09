import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"

ColumnLayout {
    spacing: Theme.space.xxs

    PageTitle {
        text: "General"
    }

    SettingSection {
        text: "Launcher"
    }
    SettingRow {
        label: "Terminal for ! commands"
        TextField {
            width: 160
            text: Settings.terminal
            placeholder: "kitty"
            onFinished: if (text.trim() !== "")
                Settings.terminal = text.trim()
        }
    }

    SettingSection {
        text: "Notes"
    }
    SettingRow {
        label: "Browser for links"
        TextField {
            width: 160
            text: Settings.browser
            placeholder: "System default"
            onFinished: Settings.browser = text.trim()
        }
    }
    SettingRow {
        label: "Line numbers"
        Dropdown {
            options: [["absolute", "Absolute"], ["relative", "Relative"]]
            value: Settings.notesLineNumbers
            onPicked: v => Settings.notesLineNumbers = v
        }
    }
    SettingRow {
        label: "Images, wrapped text"
        Dropdown {
            options: [["fit", "Fit the width"], ["fixed", "Fixed height, scrolls"]]
            value: Settings.notesImagesWrapped
            onPicked: v => Settings.notesImagesWrapped = v
        }
    }
    SettingRow {
        label: "Images, unwrapped text"
        Dropdown {
            options: [["fit", "Fit the width"], ["fixed", "Fixed height"], ["asis", "Actual size"]]
            value: Settings.notesImagesUnwrapped
            onPicked: v => Settings.notesImagesUnwrapped = v
        }
    }
    SettingRow {
        label: "Fixed image height"
        SettingStepper {
            options: [100, 150, 200, 250, 300, 400, 500]
            value: Settings.notesImageHeight
            onPicked: v => Settings.notesImageHeight = v
        }
    }

    SettingSection {
        text: "Clipboard"
    }
    SettingRow {
        label: "Entries kept"
        SettingStepper {
            options: [50, 100, 200, 300, 500, 1000, 2000]
            value: Settings.clipboardLimit
            onPicked: v => Settings.clipboardLimit = v
        }
    }
}
