import QtQuick
import ".."

InteractiveSurface {
    id: root

    property string glyph
    property bool spinning: false
    // A moment after spinning stops, shows a check mark for "done".
    property bool justDone: false

    onSpinningChanged: {
        if (spinning) {
            justDone = false;
            done.stop();
        } else {
            spinner.rotation = 0;
            justDone = true;
            done.restart();
        }
    }

    implicitWidth: Theme.control.iconButton
    implicitHeight: Theme.control.iconButton
    restColor: Theme.colors.clear

    Timer {
        id: done

        interval: 1200
        onTriggered: root.justDone = false
    }

    Part {
        id: spinner

        anchors.centerIn: parent
        slot: "powerGlyph"

        readonly property string glyph: root.justDone ? "check" : root.glyph
        readonly property color tint: root.justDone ? Theme.colors.accent : Theme.colors.foreground
        readonly property int iconSize: 16

        // The arrow points anticlockwise, so it turns that way.
        RotationAnimation on rotation {
            running: root.spinning
            loops: Animation.Infinite
            direction: RotationAnimation.Counterclockwise
            from: 360
            to: 0
            duration: 1000
        }
    }
}
