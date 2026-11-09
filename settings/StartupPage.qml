import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import "../hyprland"

ColumnLayout {
    id: page

    function setAutostart(list) {
        HyprConfig.autostart = list;
        HyprConfig.changed();
    }

    function setEnv(list) {
        HyprConfig.env = list;
        HyprConfig.changed();
    }

    spacing: Theme.space.xs

    PageTitle {
        text: "Startup"
    }
    ErrorNote {
        text: HyprConfig.lastError
    }

    SettingSection {
        text: "Programs"
    }
    Repeater {
        model: HyprConfig.autostart

        RowLayout {
            id: program

            required property string modelData
            required property int index

            Layout.fillWidth: true
            spacing: Theme.space.s

            TextField {
                text: program.modelData
                onFinished: if (text.trim() !== "" && text !== program.modelData)
                    page.setAutostart(HyprConfig.autostart.map((c, i) => i === program.index ? text.trim() : c))
            }

            IconButton {
                glyph: "trash"
                onClicked: page.setAutostart(HyprConfig.autostart.filter((c, i) => i !== program.index))
            }
        }
    }
    TextField {
        placeholder: "Add a command and press Enter"
        onAccepted: {
            if (text.trim() !== "") {
                page.setAutostart(HyprConfig.autostart.concat([text.trim()]));
                text = "";
            }
        }
    }

    SettingSection {
        text: "Environment variables"
    }
    Repeater {
        model: HyprConfig.env

        RowLayout {
            id: variable

            required property var modelData
            required property int index

            Layout.fillWidth: true
            spacing: Theme.space.s

            TextField {
                text: variable.modelData[0]
                placeholder: "Name"
                onFinished: if (text.trim() !== "" && text !== variable.modelData[0])
                    page.setEnv(HyprConfig.env.map((e, i) => i === variable.index ? [text.trim(), e[1]] : e))
            }

            TextField {
                text: variable.modelData[1]
                placeholder: "Value"
                onFinished: if (text !== variable.modelData[1])
                    page.setEnv(HyprConfig.env.map((e, i) => i === variable.index ? [e[0], text] : e))
            }

            IconButton {
                glyph: "trash"
                onClicked: page.setEnv(HyprConfig.env.filter((e, i) => i !== variable.index))
            }
        }
    }
    ActionButton {
        Layout.topMargin: Theme.space.xs
        label: "Add a variable"
        onActivated: page.setEnv(HyprConfig.env.concat([["NAME", "value"]]))
    }

    SettingSection {
        text: "Your own Lua"
    }
    Hint {
        text: "Anything else goes in ~/.config/hypr/user.lua."
    }
}
