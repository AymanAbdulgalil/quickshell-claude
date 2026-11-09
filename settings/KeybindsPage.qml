import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import "../hyprland"
import "../controls/Format.js" as Format
import "../hyprland/schema.js" as Schema

ColumnLayout {
    id: page

    property int expanded: -1
    readonly property string query: search.text.trim().toLowerCase()
    // How many binds use each key combination, to mark clashes.
    readonly property var counts: {
        const seen = {};
        for (const b of HyprConfig.binds) {
            const k = Format.normalizeKeys(b.keys);
            seen[k] = (seen[k] ?? 0) + 1;
        }
        return seen;
    }

    function update(index, changes) {
        HyprConfig.binds = HyprConfig.replaced(HyprConfig.binds, index, changes);
        HyprConfig.changed();
    }

    spacing: Theme.space.xs

    PageTitle {
        text: "Keybinds"
    }
    ErrorNote {
        text: HyprConfig.lastError
    }
    TextField {
        id: search

        placeholder: "Search by key or action"
    }

    Repeater {
        model: HyprConfig.binds

        ColumnLayout {
            id: row

            required property var modelData
            required property int index
            readonly property bool open: page.expanded === index
            readonly property bool clash: (page.counts[Format.normalizeKeys(modelData.keys)] ?? 0) > 1
            readonly property string description: Schema.describeBind(modelData)

            Layout.fillWidth: true
            visible: page.query === "" || modelData.keys.toLowerCase().includes(page.query) || description.toLowerCase().includes(page.query)
            spacing: Theme.space.xs

            InteractiveSurface {
                Layout.fillWidth: true
                implicitHeight: Theme.control.regular + 4
                restColor: row.open ? Theme.colors.surfaceRaised : Theme.colors.clear
                hoverColor: Theme.colors.surfaceRaised
                onClicked: page.expanded = row.open ? -1 : row.index

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.space.m
                    anchors.rightMargin: Theme.space.m
                    spacing: Theme.space.l

                    Label {
                        Layout.preferredWidth: 210
                        elide: Text.ElideRight
                        text: row.modelData.keys
                        color: row.clash ? Theme.colors.warning : Theme.colors.foregroundStrong
                        font.family: Theme.fonts.familyMono
                    }

                    Label {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: row.description
                        color: Theme.colors.muted
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.space.m
                Layout.rightMargin: Theme.space.m
                Layout.bottomMargin: Theme.space.m
                visible: row.open
                spacing: Theme.space.xs

                Hint {
                    visible: row.clash
                    color: Theme.colors.warning
                    text: "Another bind uses these keys too."
                }

                SettingRow {
                    label: "Keys"
                    KeyCapture {
                        keys: row.modelData.keys
                        onCaptured: (k, onRelease) => page.update(row.index, onRelease ? { keys: k, release: true } : { keys: k })
                    }
                }

                SettingRow {
                    label: "Action"
                    Dropdown {
                        controlWidth: 230
                        options: Schema.actions.map(a => [a[0], a[1]])
                        value: row.modelData.kind
                        onPicked: v => page.update(row.index, { kind: v })
                    }
                }

                SettingRow {
                    readonly property string argHint: Schema.actionOf(row.modelData.kind)[2]

                    visible: argHint !== ""
                    label: argHint
                    TextField {
                        width: 300
                        text: row.modelData.arg
                        onFinished: if (text !== row.modelData.arg)
                            page.update(row.index, { arg: text })
                    }
                }

                Repeater {
                    model: [["repeating", "Repeat while held"], ["locked", "Works on the lock screen"], ["release", "Runs on key release"], ["mouse", "Mouse button drag"]]

                    SettingRow {
                        id: flagRow

                        required property var modelData

                        label: modelData[1]
                        SettingSwitch {
                            checked: row.modelData[flagRow.modelData[0]] === true
                            onToggled: on => {
                                const changes = {};
                                changes[flagRow.modelData[0]] = on;
                                page.update(row.index, changes);
                            }
                        }
                    }
                }

                ActionButton {
                    label: "Remove this bind"
                    confirm: true
                    onActivated: {
                        page.expanded = -1;
                        HyprConfig.binds = HyprConfig.removed(HyprConfig.binds, row.index);
                        HyprConfig.changed();
                    }
                }
            }
        }
    }

    ActionButton {
        Layout.topMargin: Theme.space.s
        label: "Add a bind"
        onActivated: {
            HyprConfig.binds = HyprConfig.binds.concat([{ keys: "SUPER + ", kind: "exec", arg: "" }]);
            page.expanded = HyprConfig.binds.length - 1;
        }
    }

    SettingSection {
        text: "Workspaces"
    }
    SettingRow {
        label: "Number keys go to workspaces 1 to 10"
        SettingSwitch {
            checked: HyprConfig.workspaceBinds.enabled
            onToggled: on => {
                HyprConfig.workspaceBinds = Object.assign({}, HyprConfig.workspaceBinds, { enabled: on });
                HyprConfig.changed();
            }
        }
    }
    SettingRow {
        label: "Go to workspace with"
        TextField {
            width: 190
            text: HyprConfig.workspaceBinds.focusMod
            onFinished: if (text !== "" && text !== HyprConfig.workspaceBinds.focusMod) {
                HyprConfig.workspaceBinds = Object.assign({}, HyprConfig.workspaceBinds, { focusMod: text });
                HyprConfig.changed();
            }
        }
    }
    SettingRow {
        label: "Move window with"
        TextField {
            width: 190
            text: HyprConfig.workspaceBinds.moveMod
            onFinished: if (text !== "" && text !== HyprConfig.workspaceBinds.moveMod) {
                HyprConfig.workspaceBinds = Object.assign({}, HyprConfig.workspaceBinds, { moveMod: text });
                HyprConfig.changed();
            }
        }
    }
}
