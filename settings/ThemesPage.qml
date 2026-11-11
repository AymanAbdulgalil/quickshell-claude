import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell.Io
import Quickshell.Widgets
import ".."
import "../controls"
import "../theming"
import "../controls/Format.js" as Format
import "../parts/accent/shapes.js" as Shapes

// Theme presets. Clicking a preset switches to it; everything below edits the active one.
ColumnLayout {
    id: page

    readonly property var preset: ThemePresets.active
    // The custom color a wallpaper swatch goes to.
    property string editing: ""
    property var cursors: []

    spacing: Theme.space.xs

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space.s

        PageTitle {
            text: "Themes"
        }

        ActionButton {
            Layout.fillWidth: false
            Layout.preferredWidth: 110
            label: "New preset"
            onActivated: ThemeManager.newPreset()
        }

        ActionButton {
            Layout.fillWidth: false
            Layout.preferredWidth: 80
            label: "Delete"
            confirm: true
            enabled: ThemePresets.list.length > 1
            onActivated: ThemeManager.deletePreset(page.preset.id)
        }
    }


    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: Theme.space.m
        columns: 4
        columnSpacing: Theme.space.ml
        rowSpacing: Theme.space.ml

        Repeater {
            model: ThemePresets.all

            PresetCard {
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                preset: modelData
                selected: modelData.id === page.preset.id
                onClicked: ThemeManager.apply(modelData.id)
            }
        }
    }

    // --- Editing the active preset

    SettingSection {
        Layout.topMargin: Theme.space.xl
        text: "Name"
    }
    TextField {
        id: nameField

        text: page.preset.name
        placeholder: "Preset name"
        onFinished: {
            if (text.trim() !== "" && text.trim() !== page.preset.name)
                ThemeManager.edit({ name: text.trim() });
            text = Qt.binding(() => page.preset.name);
        }
    }

    SettingSection {
        text: "Wallpaper"
    }
    WallpaperGrid {
        selected: page.preset.wallpaper
        onPicked: path => ThemeManager.edit({ wallpaper: path })
    }

    // The login screen can have a wallpaper of its own (2026-11-10). Off, it shows the desktop's.
    SettingRow {
        label: "Separate login wallpaper"
        SettingSwitch {
            checked: (page.preset.loginWallpaper ?? "") !== ""
            onToggled: on => ThemeManager.edit({ loginWallpaper: on ? page.preset.wallpaper : "" })
        }
    }
    WallpaperGrid {
        visible: (page.preset.loginWallpaper ?? "") !== ""
        selected: page.preset.loginWallpaper ?? ""
        onPicked: path => ThemeManager.edit({ loginWallpaper: path })
    }

    SettingSection {
        text: "Colors"
    }
    SettingRow {
        label: "Colors from"
        Dropdown {
            options: [["palette", "Palette"], ["wallpaper", "Wallpaper"], ["custom", "Custom"]]
            value: page.preset.colors
            onPicked: v => ThemeManager.setColors(v)
        }
    }

    // Palette
    GridLayout {
        Layout.fillWidth: true
        visible: page.preset.colors === "palette"
        columns: 2
        columnSpacing: Theme.space.xs
        rowSpacing: Theme.space.xxs

        Repeater {
            model: Theme.palettes

            PresetRow {
                required property var modelData

                Layout.preferredWidth: 1
                preset: modelData
                selected: page.preset.palette === modelData.id
                onClicked: ThemeManager.edit({ palette: modelData.id })
            }
        }
    }

    // From the wallpaper
    SettingRow {
        visible: page.preset.colors === "wallpaper"
        label: "Style"
        Dropdown {
            options: [[true, "Dark"], [false, "Light"]]
            value: page.preset.dark
            onPicked: v => ThemeManager.edit({ dark: v })
        }
    }

    // Custom
    Label {
        Layout.fillWidth: true
        visible: page.preset.colors === "custom"
        wrapMode: Text.WordWrap
        text: "Type a color like #88c0d0 and press Enter, or pick a role's square, then a wallpaper color."
        color: Theme.colors.muted
    }
    Flow {
        Layout.fillWidth: true
        visible: page.preset.colors === "custom" && ThemeManager.swatches.length > 0
        spacing: 3

        Repeater {
            model: ThemeManager.swatches.slice(0, 24)

            Rectangle {
                required property var modelData

                width: 20
                height: 20
                radius: 4
                color: modelData.hex
                border.width: 1
                border.color: Theme.colors.border

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (page.editing !== "")
                        ThemeManager.setCustomColor(page.editing, parent.modelData.hex)
                }
            }
        }
    }
    GridLayout {
        Layout.fillWidth: true
        visible: page.preset.colors === "custom"
        columns: 2
        columnSpacing: 20
        rowSpacing: Theme.space.xxs

        Repeater {
            model: Theme.roles

            ColorRow {
                required property var modelData

                Layout.preferredWidth: 1
                role: modelData[0]
                label: modelData[1]
                selected: page.editing === modelData[0]
                onPicked: page.editing = modelData[0]
            }
        }
    }

    SettingSection {
        text: "Fonts"
    }
    FontRow {
        label: "Text"
        field: "font"
    }
    FontRow {
        label: "Titles"
        field: "fontTitle"
    }
    FontRow {
        label: "Monospace"
        field: "fontMono"
    }

    // Cursor themes installed for everyone or for this user, read when the page opens.
    Process {
        running: true
        command: ["sh", "-c", "for d in /usr/share/icons/*/cursors \"$HOME\"/.local/share/icons/*/cursors; do [ -d \"$d\" ] && basename \"$(dirname \"$d\")\"; done | sort -u"]

        stdout: StdioCollector {
            onStreamFinished: page.cursors = text.split("\n").filter(t => t !== "")
        }
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

    // Icons and the accent element (2026-11-11).
    SettingSection {
        text: "Icons"
    }
    SettingRow {
        label: "Style"
        Dropdown {
            options: [["thin", "Thin lines"], ["thick", "Thick lines"], ["filled", "Filled"]]
            value: page.preset.iconStyle
            onPicked: v => ThemeManager.edit({ iconStyle: v })
        }
    }
    SettingRow {
        label: "Accent element"

        Row {
            spacing: Theme.space.xs

            Repeater {
                model: Shapes.kinds

                InteractiveSurface {
                    id: tile

                    required property var modelData

                    width: 34
                    height: 34
                    selected: page.preset.accentMark === modelData[0]
                    onClicked: ThemeManager.edit({ accentMark: modelData[0] })

                    AccentMark {
                        anchors.centerIn: parent
                        kind: tile.modelData[0]
                        size: 16
                        color: tile.contentColor

                        Behavior on color {
                            ColorMotion {
                                preset: Theme.motion.quick
                            }
                        }
                    }
                }
            }
        }
    }

    SettingSection {
        text: "Other apps"
    }
    Repeater {
        model: [["kitty", "Kitty", "Open windows"], ["gtk", "GTK apps", "Right away"], ["icons", "File and folder icons", "Right away"],
            ["qt", "Qt apps", "About 3 seconds"], ["btop", "btop", "Right away"],
            ["hyprland", "Windows: borders, corners, gaps, fading", "Right away"], ["hyprlock", "Lock screen", "Next lock"],
            ["sddm", "Login screen", "Next login"]]

        SettingRow {
            id: appRow

            required property var modelData

            label: modelData[1] + "  ·  " + modelData[2]
            SettingSwitch {
                checked: Settings.themeApps[appRow.modelData[0]] !== false
                onToggled: on => {
                    const apps = Object.assign({}, Settings.themeApps);
                    apps[appRow.modelData[0]] = on;
                    Settings.themeApps = apps;
                }
            }
        }
    }
    Label {
        Layout.fillWidth: true
        Layout.topMargin: Theme.space.s
        visible: !ThemeManager.qtToolInstalled
        wrapMode: Text.WordWrap
        text: "Qt apps need one tool: sudo pacman -S qt6ct qt5ct, then log out and in."
        color: Theme.colors.warning
    }
}
