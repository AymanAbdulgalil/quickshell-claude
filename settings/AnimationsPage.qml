import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import "../theming"
import "../controls/Format.js" as Format

// Hyprland's animations and the curves they follow, in the active preset.
ColumnLayout {
    id: page

    readonly property var preset: ThemePresets.active
    readonly property var curveNames: ["default"].concat(preset.curves.map(c => c.name))
    readonly property var leaves: Object.keys(preset.animations)
    property int openCurve: -1

    function setCurve(index, changes) {
        ThemeManager.edit({ curves: preset.curves.map((c, i) => i === index ? Object.assign({}, c, changes) : c) });
    }

    spacing: Theme.space.xxs

    PageTitle {
        text: "Animations"
    }
    ErrorNote {
        text: ThemeManager.lastError
    }

    HyprSwitchRow {
        label: "Animate windows and workspaces"
        option: "animations:enabled"
    }

    SettingSection {
        text: "What animates"
    }

    Repeater {
        model: page.leaves

        RowLayout {
            id: leafRow

            required property string modelData
            readonly property var leaf: page.preset.animations[modelData]

            Layout.fillWidth: true
            Layout.minimumHeight: Theme.control.settingRow
            spacing: Theme.space.m

            Label {
                Layout.fillWidth: true
                text: leafRow.modelData
                elide: Text.ElideRight
            }

            TextField {
                Layout.fillWidth: false
                Layout.preferredWidth: 96
                implicitHeight: Theme.control.small
                visible: /^(windows|layers|workspaces|specialWorkspace)/.test(leafRow.modelData)
                placeholder: "Style"
                text: leafRow.leaf.style
                onFinished: if (text !== leafRow.leaf.style)
                    ThemeManager.editAnimation(leafRow.modelData, { style: text })
            }

            Dropdown {
                controlWidth: 130
                options: page.curveNames.map(n => [n, n])
                value: leafRow.leaf.curve
                onPicked: v => ThemeManager.editAnimation(leafRow.modelData, { curve: v })
            }

            SettingStepper {
                options: Format.range(0.1, 12, 0.1)
                value: leafRow.leaf.speed
                format: v => v.toFixed(1)
                onPicked: v => ThemeManager.editAnimation(leafRow.modelData, { speed: v })
            }

            SettingSwitch {
                checked: leafRow.leaf.enabled
                onToggled: on => ThemeManager.editAnimation(leafRow.modelData, { enabled: on })
            }
        }
    }

    SettingSection {
        text: "Curves"
    }

    Repeater {
        model: page.preset.curves

        ColumnLayout {
            id: curveRow

            required property var modelData
            required property int index
            readonly property bool open: page.openCurve === index

            Layout.fillWidth: true
            spacing: Theme.space.s

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.s

                IconButton {
                    glyph: "chevron"
                    rotation: curveRow.open ? 180 : 0
                    onClicked: page.openCurve = curveRow.open ? -1 : curveRow.index
                }

                TextField {
                    text: curveRow.modelData.name
                    placeholder: "Name"
                    onFinished: if (text.trim() !== "" && text !== curveRow.modelData.name)
                        page.setCurve(curveRow.index, { name: text.trim() })
                }

                Repeater {
                    model: ["x1", "y1", "x2", "y2"]

                    TextField {
                        required property string modelData

                        Layout.fillWidth: false
                        Layout.preferredWidth: 58
                        text: curveRow.modelData[modelData]
                        onFinished: {
                            const v = parseFloat(text);
                            if (!isNaN(v) && v !== curveRow.modelData[modelData]) {
                                const changes = {};
                                changes[modelData] = v;
                                page.setCurve(curveRow.index, changes);
                            }
                        }
                    }
                }

                IconButton {
                    glyph: "trash"
                    onClicked: {
                        page.openCurve = -1;
                        ThemeManager.edit({ curves: page.preset.curves.filter((c, i) => i !== curveRow.index) });
                    }
                }
            }

            CurveEditor {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: Theme.space.m
                visible: curveRow.open
                x1: curveRow.modelData.x1
                y1: curveRow.modelData.y1
                x2: curveRow.modelData.x2
                y2: curveRow.modelData.y2
                onEdited: (ax, ay, bx, by) => page.setCurve(curveRow.index, { x1: ax, y1: ay, x2: bx, y2: by })
            }
        }
    }

    ActionButton {
        Layout.topMargin: Theme.space.s
        label: "Add a curve"
        onActivated: ThemeManager.edit({ curves: page.preset.curves.concat([{ name: "curve" + (page.preset.curves.length + 1), x1: 0.25, y1: 0.1, x2: 0.25, y2: 1 }]) })
    }
}
