import QtQuick
import "../.."

// Draws one Bluetooth state. All state decisions live in bar/BluetoothIndicator.
// The icon uses the foreground color; only marks carry color.
//
// Inputs: discoverable, btState: connected | idle | searching | connecting | changing | off | blocked | none
// dots: one color per connected device, drawn as a vertical column beside the rune.
Canvas {
    // Colors below come from the theme, so repaint when it changes.
    readonly property var themeWatch: Theme.palette
    onThemeWatchChanged: requestPaint()

    id: root

    readonly property string status: parent.btState
    readonly property var dots: parent.dots
    readonly property bool discoverable: parent.discoverable

    readonly property int maxDots: 4
    readonly property var spec: ({
            "connected": {},
            "idle": {},
            "searching": { steps: 4 },
            "connecting": { steps: 2 },
            "changing": { steps: 2 },
            "off": { mark: "slash" },
            "blocked": { mark: "hard-slash" },
            "none": { mark: "cross" }
        })[status] ?? {}

    readonly property int steps: spec.steps ?? 0
    // Steps on a Timer: an endless animation would keep the bar's render loop running for a change it shows four times a second.
    property int step: 0

    onStepsChanged: step = 0

    Timer {
        interval: Theme.motion.iconStep
        repeat: true
        running: root.steps > 0
        onTriggered: root.step = (root.step + 1) % root.steps
    }
    readonly property string mark: spec.mark ?? ""

    // Fades between dim and lit when blinking.
    property real runeLevel: steps === 2 && step === 1 ? 0 : 1
    property real waveLevel: discoverable && !mark ? 1 : 0

    Behavior on runeLevel {
        Motion {
            preset: Theme.motion.quick
        }
    }
    Behavior on waveLevel {
        Motion {}
    }

    // Marks fade out, change, and fade back in.
    property string shownMark: ""
    property real markAlpha: 1

    onMarkChanged: markSwap.restart()
    Component.onCompleted: shownMark = mark

    SequentialAnimation {
        id: markSwap

        Motion {
            target: root
            property: "markAlpha"
            to: 0
            preset: Theme.motion.quick
        }
        ScriptAction {
            script: root.shownMark = root.mark
        }
        Motion {
            target: root
            property: "markAlpha"
            to: 1
            preset: Theme.motion.quick
        }
    }

    // The bar's size unless a list asks for its own. Drawn 14 units tall with a pixel to spare above and below.
    readonly property int canvasHeight: parent.iconSize ?? Theme.layout.barIconSize
    readonly property real unit: Theme.iconUnit(canvasHeight)

    implicitWidth: Math.ceil(20 * unit)
    implicitHeight: canvasHeight

    onStatusChanged: requestPaint()
    onDotsChanged: requestPaint()
    onRuneLevelChanged: requestPaint()
    onWaveLevelChanged: requestPaint()
    onShownMarkChanged: requestPaint()
    onMarkAlphaChanged: requestPaint()
    onStepChanged: requestPaint()

    function mixed(amount) {
        const a = Theme.colors.inactive;
        const b = Theme.colors.foreground;
        return Qt.rgba(a.r + (b.r - a.r) * amount, a.g + (b.g - a.g) * amount, a.b + (b.b - a.b) * amount, 1);
    }

    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.translate(0, canvasHeight / 2 - 8 * unit);
        ctx.scale(unit, unit);
        // Fits this drawing to y 1 to 15, so every bar icon is exactly as tall.
        ctx.translate(8, 8);
        ctx.scale(0.903, 0.903);
        ctx.translate(-8, -8);
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.lineWidth = 1.5;

        const cx = 9;
        ctx.strokeStyle = mixed(runeLevel);
        ctx.beginPath();
        ctx.moveTo(cx - 4, 4.5);
        ctx.lineTo(cx + 4, 11.5);
        ctx.lineTo(cx, 15);
        ctx.lineTo(cx, 1);
        ctx.lineTo(cx + 4, 4.5);
        ctx.lineTo(cx - 4, 11.5);
        ctx.stroke();

        // Visible to other devices: one wave on the left.
        if (waveLevel > 0) {
            ctx.globalAlpha = waveLevel;
            ctx.strokeStyle = Theme.colors.warning;
            ctx.lineWidth = 1.2;
            ctx.beginPath();
            ctx.arc(cx, 8, 8, Math.PI * 0.82, Math.PI * 1.18);
            ctx.stroke();
            ctx.globalAlpha = 1;
        }

        const x = 17.5;
        const pitch = 3.6;
        if (steps === 4) {
            // Searching: one dot travels down the column.
            ctx.fillStyle = Theme.colors.foreground;
            ctx.beginPath();
            ctx.arc(x, 8 + (step - 1.5) * pitch, 1.2, 0, Math.PI * 2);
            ctx.fill();
        } else {
            const count = Math.min(dots.length, maxDots);
            for (let i = 0; i < count; i++) {
                ctx.fillStyle = dots[i];
                ctx.beginPath();
                ctx.arc(x, 8 + (i - (count - 1) / 2) * pitch, 1.2, 0, Math.PI * 2);
                ctx.fill();
            }
        }

        ctx.globalAlpha = markAlpha;
        if (shownMark === "slash" || shownMark === "hard-slash") {
            const color = shownMark === "slash" ? Theme.colors.accent : Theme.colors.error;
            for (const pass of [[Theme.colors.surface, 4], [color, 1.6]]) {
                ctx.strokeStyle = pass[0];
                ctx.lineWidth = pass[1];
                ctx.beginPath();
                ctx.moveTo(3, 2);
                ctx.lineTo(16, 14);
                ctx.stroke();
            }
        } else if (shownMark === "cross") {
            ctx.strokeStyle = Theme.colors.error;
            ctx.lineWidth = 1.4;
            ctx.beginPath();
            ctx.moveTo(14, 9);
            ctx.lineTo(18.5, 13.5);
            ctx.moveTo(18.5, 9);
            ctx.lineTo(14, 13.5);
            ctx.stroke();
        }
        ctx.globalAlpha = 1;
    }
}
