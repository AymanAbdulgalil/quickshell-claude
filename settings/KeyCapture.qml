import QtQuick
import ".."
import "../controls"
import "../hyprland/schema.js" as Schema

// Key combination: type it, or press Record and press it. A modifier pressed and let go alone is recorded too, and runs on
// release. Combinations Hyprland already binds never reach this window, which is why typing stays possible.
Row {
    id: root

    property string keys
    property bool recording: false
    // A modifier is down and nothing else has been pressed since.
    property string lone: ""

    signal captured(string keys, bool onRelease)

    function finish() {
        recording = false;
        lone = "";
        settle.restart();
    }

    onRecordingChanged: if (recording)
        Panels.capturingKeys = true

    spacing: Theme.space.xs

    // Hyprland reports the release of a bare Super a moment later; the launcher must still ignore it.
    Timer {
        id: settle

        interval: 400
        onTriggered: Panels.capturingKeys = false
    }

    TextField {
        width: 210
        visible: !root.recording
        text: root.keys
        onFinished: if (text.trim() !== "" && text !== root.keys)
            root.captured(text.trim(), false)
    }

    InteractiveSurface {
        id: recorder

        width: 210
        height: Theme.control.regular
        visible: root.recording
        restColor: Theme.colors.surfaceHover
        focus: root.recording

        Keys.onPressed: event => {
            event.accepted = true;
            if (event.key === Qt.Key_Escape) {
                root.finish();
                return;
            }
            const alone = Schema.loneModifier(event.key);
            if (alone !== "") {
                root.lone = alone;
                return;
            }
            root.lone = "";
            const chord = Schema.chord(event, { meta: Qt.MetaModifier, control: Qt.ControlModifier, alt: Qt.AltModifier, shift: Qt.ShiftModifier });
            if (chord !== "") {
                root.captured(chord, false);
                root.finish();
            }
        }
        Keys.onReleased: event => {
            event.accepted = true;
            if (root.lone !== "" && Schema.loneModifier(event.key) === root.lone) {
                root.captured(root.lone, true);
                root.finish();
            }
        }

        Label {
            anchors.centerIn: parent
            text: "Press the keys, Esc cancels"
            color: Theme.colors.muted
        }
    }

    ActionButton {
        width: 70
        label: root.recording ? "Cancel" : "Record"
        onActivated: {
            if (root.recording) {
                root.finish();
            } else {
                root.recording = true;
                recorder.forceActiveFocus();
            }
        }
    }
}
