import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import "../hyprland"
import "../controls/Format.js" as Format

ColumnLayout {
    id: page

    function updateGesture(index, changes) {
        HyprConfig.gestures = HyprConfig.replaced(HyprConfig.gestures, index, changes);
        HyprConfig.changed();
    }

    function updateDevice(index, changes) {
        HyprConfig.devices = HyprConfig.replaced(HyprConfig.devices, index, changes);
        HyprConfig.changed();
    }

    spacing: Theme.space.xxs

    PageTitle {
        text: "Input"
    }
    ErrorNote {
        text: HyprConfig.lastError
    }

    SettingSection {
        text: "Keyboard"
    }
    HyprOptionText {
        label: "Layouts"
        option: "input:kb_layout"
    }
    HyprOptionText {
        label: "Variants"
        option: "input:kb_variant"
    }
    HyprOptionText {
        label: "Options"
        option: "input:kb_options"
    }
    HyprOptionNumber {
        label: "Repeat rate"
        option: "input:repeat_rate"
        fallback: 25
        options: Format.range(5, 80, 5)
        format: v => v + " /s"
    }
    HyprOptionNumber {
        label: "Repeat delay"
        option: "input:repeat_delay"
        fallback: 600
        options: Format.range(150, 1000, 50)
        format: v => v + " ms"
    }
    HyprOptionSwitch {
        label: "Num Lock on at start"
        option: "input:numlock_by_default"
    }

    SettingSection {
        text: "Mouse"
    }
    HyprOptionNumber {
        label: "Sensitivity"
        option: "input:sensitivity"
        options: Format.range(-1, 1, 0.1)
        format: v => v.toFixed(1)
    }
    SettingRow {
        label: "Focus follows the mouse"
        Dropdown {
            options: [[0, "Off"], [1, "Always"], [2, "Click"], [3, "Separate"]]
            value: HyprConfig.options["input:follow_mouse"] ?? 1
            onPicked: v => HyprConfig.setOption("input:follow_mouse", v)
        }
    }
    HyprOptionSwitch {
        label: "Natural scrolling"
        option: "input:natural_scroll"
    }

    SettingSection {
        text: "Touchpad"
    }
    HyprOptionSwitch {
        label: "Natural scrolling"
        option: "input:touchpad:natural_scroll"
    }
    HyprOptionSwitch {
        label: "Tap to click"
        option: "input:touchpad:tap-to-click"
        fallback: true
    }
    HyprOptionSwitch {
        label: "Disable while typing"
        option: "input:touchpad:disable_while_typing"
        fallback: true
    }
    HyprOptionNumber {
        label: "Scroll speed"
        option: "input:touchpad:scroll_factor"
        fallback: 1
        options: Format.range(0.1, 3, 0.1)
        format: v => v.toFixed(1)
    }

    SettingSection {
        text: "Gestures"
    }
    Repeater {
        model: HyprConfig.gestures

        RowLayout {
            id: gesture

            required property var modelData
            required property int index

            Layout.fillWidth: true
            spacing: Theme.space.m

            SettingStepper {
                options: [3, 4, 5]
                value: gesture.modelData.fingers
                format: v => v + " fingers"
                onPicked: v => page.updateGesture(gesture.index, { fingers: v })
            }

            Dropdown {
                controlWidth: 130
                options: [["horizontal", "Horizontal"], ["vertical", "Vertical"], ["swipe", "Any swipe"], ["pinch", "Pinch"], ["up", "Up"], ["down", "Down"], ["left", "Left"], ["right", "Right"]]
                value: gesture.modelData.direction
                onPicked: v => page.updateGesture(gesture.index, { direction: v })
            }

            TextField {
                placeholder: "Action, like workspace"
                text: gesture.modelData.action
                onFinished: if (text !== "" && text !== gesture.modelData.action)
                    page.updateGesture(gesture.index, { action: text })
            }

            IconButton {
                glyph: "trash"
                onClicked: {
                    HyprConfig.gestures = HyprConfig.removed(HyprConfig.gestures, gesture.index);
                    HyprConfig.changed();
                }
            }
        }
    }
    ActionButton {
        Layout.topMargin: Theme.space.xs
        label: "Add a gesture"
        onActivated: {
            HyprConfig.gestures = HyprConfig.gestures.concat([{ fingers: 3, direction: "vertical", action: "workspace" }]);
            HyprConfig.changed();
        }
    }

    SettingSection {
        text: "Per device"
    }
    Repeater {
        model: HyprConfig.devices

        RowLayout {
            id: device

            required property var modelData
            required property int index

            Layout.fillWidth: true
            spacing: Theme.space.m

            TextField {
                placeholder: "Device name, from hyprctl devices"
                text: device.modelData.name
                onFinished: if (text !== "" && text !== device.modelData.name)
                    page.updateDevice(device.index, { name: text })
            }

            SettingStepper {
                options: Format.range(-1, 1, 0.1)
                value: device.modelData.sensitivity ?? 0
                format: v => v.toFixed(1)
                onPicked: v => page.updateDevice(device.index, { sensitivity: v })
            }

            IconButton {
                glyph: "trash"
                onClicked: {
                    HyprConfig.devices = HyprConfig.removed(HyprConfig.devices, device.index);
                    HyprConfig.changed();
                }
            }
        }
    }
    ActionButton {
        Layout.topMargin: Theme.space.xs
        label: "Add a device"
        onActivated: {
            HyprConfig.devices = HyprConfig.devices.concat([{ name: "", sensitivity: 0 }]);
        }
    }
}
