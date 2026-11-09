import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import "../hyprland"
import "../controls/Format.js" as Format

ColumnLayout {
    id: page

    function update(index, changes) {
        HyprConfig.monitors = HyprConfig.replaced(HyprConfig.monitors, index, changes);
        HyprConfig.changed();
    }

    function outputOf(name) {
        return HyprConfig.outputs.find(o => o.name === name) ?? null;
    }

    Component.onCompleted: HyprConfig.loadOutputs()
    spacing: Theme.space.xxs

    PageTitle {
        text: "Monitors"
    }
    ErrorNote {
        text: HyprConfig.lastError
    }

    Repeater {
        model: HyprConfig.monitors

        ColumnLayout {
            id: monitor

            required property var modelData
            required property int index
            readonly property var output: page.outputOf(modelData.output)

            Layout.fillWidth: true
            spacing: Theme.space.xxs

            SettingSection {
                text: monitor.modelData.output + (monitor.output ? "  ·  " + monitor.output.make + " " + monitor.output.model : "  ·  not connected")
            }
            SettingRow {
                label: "Resolution and refresh rate"
                Dropdown {
                    controlWidth: 200
                    options: (monitor.output?.availableModes ?? [monitor.modelData.mode]).map(m => {
                        const short = m.replace(/\.\d+Hz$/, "").replace(/Hz$/, "");
                        return [short, short];
                    })
                    value: monitor.modelData.mode
                    onPicked: v => page.update(monitor.index, { mode: v })
                }
            }
            SettingRow {
                label: "Position"
                TextField {
                    width: 120
                    text: monitor.modelData.position
                    onFinished: if (/^-?\d+x-?\d+$/.test(text) && text !== monitor.modelData.position)
                        page.update(monitor.index, { position: text })
                }
            }
            SettingRow {
                label: "Scale"
                SettingStepper {
                    options: Format.range(0.5, 3, 0.25)
                    value: monitor.modelData.scale
                    format: v => v + "×"
                    onPicked: v => page.update(monitor.index, { scale: v })
                }
            }
        }
    }

    SettingSection {
        visible: page.unconfigured.length > 0
        text: "Connected, using automatic settings"
    }
    Repeater {
        model: page.unconfigured

        SettingRow {
            required property var modelData

            label: modelData.name + "  ·  " + modelData.width + "x" + modelData.height
            ActionButton {
                width: 90
                label: "Configure"
                onActivated: {
                    const o = parent.parent.modelData;
                    HyprConfig.monitors = HyprConfig.monitors.concat([{ output: o.name, mode: o.width + "x" + o.height + "@" + Math.round(o.refreshRate), position: o.x + "x" + o.y, scale: o.scale }]);
                    HyprConfig.changed();
                }
            }
        }
    }

    readonly property var unconfigured: HyprConfig.outputs.filter(o => !HyprConfig.monitors.some(m => m.output === o.name))
}
