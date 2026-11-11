import QtQuick
import ".."

// How a panel's card comes and goes, as the preset says (2026-11-11): it fades, slides in from the bar, both, or neither,
// on the panel motion's duration and curve. Put one inside the card and bind the card to it:
//     opacity: show.fade
//     transform: Translate { x: show.dx; y: show.dy }
// `distance` is how far it slides: a panel under the bar slides its whole height, so it comes out from the bar.
Item {
    id: show

    property bool shown: false
    property real distance: 48
    // Where it slides from: "top", "bottom", "left" or "right"; the bar's edge by default.
    property string from: Theme.layout.barEdge

    // 0 hidden, 1 shown. Whatever is off still waits for the other, so the card never vanishes mid-slide.
    property real progress: 0
    readonly property real fade: Theme.motion.panelFade ? progress : progress > 0 ? 1 : 0
    readonly property real away: Theme.motion.panelSlide ? (1 - progress) * distance : 0
    readonly property real dx: from === "left" ? -away : from === "right" ? away : 0
    readonly property real dy: from === "top" ? -away : from === "bottom" ? away : 0

    // Started by hand: a Behavior is skipped on a panel's first open, while the panel is still being built.
    function run() {
        motion.stop();
        if (Theme.motion.panelFade || Theme.motion.panelSlide) {
            motion.to = shown ? 1 : 0;
            motion.start();
        } else {
            progress = shown ? 1 : 0;
        }
    }

    onShownChanged: run()
    Component.onCompleted: if (shown)
        run()
    visible: false

    Motion {
        id: motion

        target: show
        property: "progress"
        preset: Theme.motion.panel
    }
}
