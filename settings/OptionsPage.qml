import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import "../hyprland"
import "../theming"
import "../hyprland/schema.js" as Schema

// Every Hyprland option the shell allows, found by search. Each is edited by what kind of value it is.
ColumnLayout {
    id: page

    property string scope: "visual"
    readonly property string query: search.text.trim().toLowerCase()
    readonly property var shown: HyprConfig.schema.filter(o => !Schema.isHidden(o.name) && Schema.isVisual(o.name) === (scope === "visual") && Schema.matches(o, query))

    function stored(name) {
        return scope === "visual" ? ThemePresets.active.hypr[name] : HyprConfig.options[name];
    }

    function write(o, value) {
        if (scope === "visual")
            ThemeManager.editHypr(o.name, value, Schema.defaultOf(o));
        else
            HyprConfig.setOption(o.name, value);
    }

    Component.onCompleted: HyprConfig.loadSchema()
    spacing: Theme.space.s

    PageTitle {
        text: "All options"
    }
    Tabs {
        options: [["visual", "Look, saved in the preset"], ["system", "Behaviour, saved once"]]
        value: page.scope
        onPicked: v => page.scope = v
    }
    TextField {
        id: search

        placeholder: "Search " + page.shown.length + " options"
    }
    ErrorNote {
        text: page.scope === "visual" ? ThemeManager.lastError : HyprConfig.lastError
    }

    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.layout.settingsHeight - 170
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        spacing: Theme.space.xs
        cacheBuffer: 200
        model: page.shown

        delegate: RowLayout {
            id: row

            required property var modelData
            readonly property string kind: Schema.kindOf(modelData)
            readonly property var override: page.stored(modelData.name)
            readonly property var value: override ?? Schema.shown(modelData)

            width: ListView.view.width
            spacing: Theme.space.l

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: Schema.title(row.modelData.name) + (Schema.isHeavy(row.modelData.name) ? "  ·  uses more GPU" : "")
                    color: Theme.colors.foregroundStrong
                }

                Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: Schema.section(row.modelData.name) + ": " + (row.modelData.description ?? "")
                    color: Theme.colors.muted
                    font.pixelSize: Theme.fonts.caption
                }
            }

            SettingSwitch {
                visible: row.kind === "switch"
                checked: row.kind === "switch" && row.value === true
                onToggled: on => page.write(row.modelData, on)
            }

            Dropdown {
                visible: row.kind === "choice"
                controlWidth: 150
                options: row.kind === "choice" ? Schema.choices(row.modelData) : []
                value: row.value
                onPicked: v => page.write(row.modelData, v)
            }

            TextField {
                visible: row.kind === "number" || row.kind === "gap" || row.kind === "text"
                Layout.fillWidth: false
                Layout.preferredWidth: row.kind === "text" ? 190 : 80
                text: visible ? String(row.value ?? "") : ""
                onFinished: {
                    if (text === String(row.value ?? ""))
                        return;
                    if (row.kind === "text") {
                        page.write(row.modelData, text);
                        return;
                    }
                    const parsed = parseFloat(text);
                    if (isNaN(parsed)) {
                        text = String(row.value ?? "");
                        return;
                    }
                    const low = row.modelData.min ?? -Infinity;
                    const high = row.modelData.max ?? Infinity;
                    page.write(row.modelData, Math.max(low, Math.min(high, parsed)));
                }
            }
        }
    }
}
