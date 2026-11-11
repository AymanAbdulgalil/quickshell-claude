import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import "../theming"
import "../controls/Format.js" as Format

// How the bar or the panels animate, in the active preset: curve, duration, and fading and sliding on or off.
// `prefix` is "bar" or "panel"; the fields are prefix + Curve, Speed, Fade, Slide. A curve is one of the preset's
// named curves, the same list window animations use, and its graph below edits that curve.
ColumnLayout {
    id: rows

    required property string prefix
    property string slideLabel: "Slide"
    readonly property var preset: ThemePresets.active
    readonly property string curveName: preset[prefix + "Curve"] ?? "default"
    readonly property int curveIndex: preset.curves.findIndex(c => c.name === curveName)
    readonly property var curve: curveIndex >= 0 ? preset.curves[curveIndex] : null

    function set(field, value) {
        const changes = {};
        changes[prefix + field] = value;
        ThemeManager.edit(changes);
    }

    Layout.fillWidth: true
    spacing: Theme.space.xxs

    SettingRow {
        label: "Fade"
        SettingSwitch {
            checked: rows.preset[rows.prefix + "Fade"]
            onToggled: on => rows.set("Fade", on)
        }
    }
    SettingRow {
        label: rows.slideLabel
        SettingSwitch {
            checked: rows.preset[rows.prefix + "Slide"]
            onToggled: on => rows.set("Slide", on)
        }
    }
    SettingRow {
        label: "Duration"
        SettingStepper {
            options: Format.range(40, 600, 20)
            value: rows.preset[rows.prefix + "Speed"]
            format: v => v + " ms"
            onPicked: v => rows.set("Speed", v)
        }
    }
    SettingRow {
        label: "Curve"
        Dropdown {
            options: [["default", "Ease out"]].concat(rows.preset.curves.map(c => [c.name, c.name]))
            value: rows.curveName
            onPicked: v => rows.set("Curve", v)
        }
    }
    CurveEditor {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.space.xs
        Layout.bottomMargin: Theme.space.m
        visible: rows.curve !== null
        x1: rows.curve?.x1 ?? 0
        y1: rows.curve?.y1 ?? 0
        x2: rows.curve?.x2 ?? 1
        y2: rows.curve?.y2 ?? 1
        onEdited: (ax, ay, bx, by) => ThemeManager.edit({
                curves: rows.preset.curves.map((c, i) => i === rows.curveIndex ? Object.assign({}, c, { x1: ax, y1: ay, x2: bx, y2: by }) : c)
            })
    }
}
