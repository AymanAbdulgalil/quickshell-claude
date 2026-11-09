import QtQuick
import ".."

// Minus, value, plus. `options` lists the values; `format` turns one into text. Holding a button repeats.
Row {
    id: root

    property var options: []
    property var value
    property var format: v => String(v)

    signal picked(var value)

    readonly property int index: {
        let best = 0;
        for (let i = 0; i < options.length; i++) {
            if (Math.abs(options[i] - value) < Math.abs(options[best] - value))
                best = i;
        }
        return best;
    }

    function move(by) {
        const next = Math.max(0, Math.min(options.length - 1, index + by));
        if (next !== index)
            picked(options[next]);
    }

    spacing: Theme.space.xxs

    SettingStepButton {
        symbol: "-"
        atLimit: root.index <= 0
        onStep: root.move(-1)
    }

    Label {
        width: 58
        height: Theme.control.small
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.format(root.options[root.index])
        color: Theme.colors.foregroundStrong
    }

    SettingStepButton {
        symbol: "+"
        atLimit: root.index >= root.options.length - 1
        onStep: root.move(1)
    }
}
