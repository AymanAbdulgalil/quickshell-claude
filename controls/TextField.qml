import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property string placeholder
    property bool secret: false
    property bool arrowsMove: false
    property alias text: input.text
    readonly property bool activeFocusInside: input.activeFocus

    signal accepted
    // Enter, or focus moving away.
    signal finished
    signal navigate(int by)
    // Left and right, with arrowsMove (lists that run sideways).
    signal sideways(int by)
    signal escaped

    // The modifiers held with the last Enter, so Shift+Enter can mean something else (back, in a search).
    property int enterModifiers: 0

    function enter(modifiers) {
        root.enterModifiers = modifiers ?? 0;
        root.accepted();
        root.finished();
    }

    function focusNow() {
        input.forceActiveFocus();
    }

    function selectAll() {
        input.selectAll();
    }

    Layout.fillWidth: true
    implicitHeight: Theme.control.regular
    radius: Theme.shape.controlRadius
    color: Theme.colors.surfaceRaised
    border.width: Theme.shape.borderWidth
    border.color: input.activeFocus ? Theme.colors.accent : Theme.colors.clear

    Behavior on border.color {
        ColorMotion {
            preset: Theme.motion.quick
        }
    }

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: Theme.space.m
        anchors.rightMargin: Theme.space.m
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        echoMode: root.secret ? TextInput.Password : TextInput.Normal
        color: Theme.colors.foregroundStrong
        selectionColor: Theme.colors.accent
        selectedTextColor: Theme.colors.onAccent
        font.family: Theme.fonts.family
        font.pixelSize: Theme.fonts.small
        // Enter is read as a key, not through TextInput's accepted: with Wayland's text-input protocol in
        // between, accepted did not always arrive (the clipboard's Enter did nothing).
        Keys.onReturnPressed: event => root.enter(event.modifiers)
        Keys.onEnterPressed: event => root.enter(event.modifiers)
        onEditingFinished: root.finished()
        Keys.onLeftPressed: event => {
            if (root.arrowsMove)
                root.sideways(-1);
            else
                event.accepted = false;
        }
        Keys.onRightPressed: event => {
            if (root.arrowsMove)
                root.sideways(1);
            else
                event.accepted = false;
        }
        Keys.onUpPressed: root.navigate(-1)
        Keys.onDownPressed: root.navigate(1)
        Keys.onEscapePressed: event => {
            root.escaped();
            event.accepted = false;
        }
    }

    Label {
        anchors.fill: input
        verticalAlignment: Text.AlignVCenter
        visible: input.text.length === 0
        text: root.placeholder
        color: Theme.colors.muted
    }
}
