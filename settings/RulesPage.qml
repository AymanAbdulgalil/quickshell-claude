import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import "../hyprland"

ColumnLayout {
    id: page

    function update(index, changes) {
        HyprConfig.windowRules = HyprConfig.replaced(HyprConfig.windowRules, index, changes);
        HyprConfig.changed();
    }

    // The effects are kept as Lua fields in hyprland.json; here each is one row.
    readonly property var knownEffects: ({
            float: "true", tile: "true", pin: "true", center: "true", fullscreen: "true", maximize: "true", no_anim: "true", no_blur: "true",
            no_shadow: "true", no_dim: "true", no_border: "true", no_focus: "true", opaque: "true", border_size: "0", rounding: "0",
            opacity: "1", workspace: "1", monitor: "0", size: "{ 800, 600 }", move: "{ 0, 0 }", idle_inhibit: '"focus"', suppress_event: '"maximize"'
        })

    function effectOptions(current) {
        const names = Object.keys(knownEffects);
        if (!names.includes(current))
            names.push(current);
        return names.sort().map(n => [n, n.replace(/_/g, " ")]);
    }

    function defaultFor(name) {
        return knownEffects[name] ?? "true";
    }

    // "float = true, size = { 1, 2 }" to [["float", "true"], ["size", "{ 1, 2 }"]]; commas inside braces stay.
    function effectsOf(text) {
        const parts = [];
        let depth = 0;
        let current = "";
        for (const c of text) {
            if (c === "{")
                depth++;
            else if (c === "}")
                depth--;
            if (c === "," && depth === 0) {
                parts.push(current);
                current = "";
            } else {
                current += c;
            }
        }
        if (current.trim() !== "")
            parts.push(current);
        return parts.map(p => {
            const at = p.indexOf("=");
            return [p.slice(0, at).trim(), p.slice(at + 1).trim()];
        });
    }

    function joined(list) {
        return list.map(e => e[0] + " = " + e[1]).join(", ");
    }

    function setEffect(ruleIndex, index, value) {
        const list = effectsOf(HyprConfig.windowRules[ruleIndex].effects);
        if (value)
            list[index] = value;
        else
            list.splice(index, 1);
        update(ruleIndex, { effects: joined(list) });
    }

    spacing: Theme.space.xs

    PageTitle {
        text: "Window rules"
    }
    ErrorNote {
        text: HyprConfig.lastError
    }

    Repeater {
        model: HyprConfig.windowRules

        ColumnLayout {
            id: rule

            required property var modelData
            required property int index

            Layout.fillWidth: true
            spacing: Theme.space.xs

            SettingSection {
                text: rule.modelData.name
            }
            SettingRow {
                label: "Name"
                TextField {
                    width: 340
                    text: rule.modelData.name
                    onFinished: if (text.trim() !== "" && text !== rule.modelData.name)
                        page.update(rule.index, { name: text.trim() })
                }
            }
            SettingRow {
                label: "Window class"
                TextField {
                    width: 340
                    placeholder: "Pattern, like .*firefox.*"
                    text: rule.modelData.match.class ?? ""
                    onFinished: if (text !== (rule.modelData.match.class ?? ""))
                        page.update(rule.index, { match: Object.assign({}, rule.modelData.match, { class: text }) })
                }
            }
            SettingRow {
                label: "Window title"
                TextField {
                    width: 340
                    placeholder: "Pattern"
                    text: rule.modelData.match.title ?? ""
                    onFinished: if (text !== (rule.modelData.match.title ?? ""))
                        page.update(rule.index, { match: Object.assign({}, rule.modelData.match, { title: text }) })
                }
            }
            Repeater {
                model: page.effectsOf(rule.modelData.effects)

                RowLayout {
                    id: effect

                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    spacing: Theme.space.s

                    Dropdown {
                        controlWidth: 190
                        options: page.effectOptions(effect.modelData[0])
                        value: effect.modelData[0]
                        onPicked: v => page.setEffect(rule.index, effect.index, [v, page.defaultFor(v)])
                    }

                    TextField {
                        text: effect.modelData[1]
                        onFinished: if (text !== effect.modelData[1])
                            page.setEffect(rule.index, effect.index, [effect.modelData[0], text])
                    }

                    IconButton {
                        glyph: "trash"
                        onClicked: page.setEffect(rule.index, effect.index, null)
                    }
                }
            }
            ActionButton {
                label: "Add an effect"
                onActivated: page.update(rule.index, { effects: page.joined(page.effectsOf(rule.modelData.effects).concat([["float", "true"]])) })
            }
            ActionButton {
                label: "Remove this rule"
                confirm: true
                onActivated: {
                    HyprConfig.windowRules = HyprConfig.removed(HyprConfig.windowRules, rule.index);
                    HyprConfig.changed();
                }
            }
        }
    }

    ActionButton {
        Layout.topMargin: Theme.space.s
        label: "Add a rule"
        onActivated: HyprConfig.windowRules = HyprConfig.windowRules.concat([{ name: "rule-" + (HyprConfig.windowRules.length + 1), match: { class: "" }, effects: "float = true" }])
    }
}
