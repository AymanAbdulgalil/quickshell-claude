import QtQuick
import QtQuick.Layouts
import ".."

// A text button. With `confirm`, the first click arms it and a second click runs it.
InteractiveSurface {
    id: root

    property string label
    property bool confirm: false
    property bool busy: false

    signal activated

    function press() {
        if (!enabled || busy)
            return;
        if (confirm && !armed) {
            armed = true;
            return;
        }
        armed = false;
        activated();
    }

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: Theme.control.regular
    implicitWidth: buttonText.implicitWidth + 2 * Theme.space.l
    onClicked: press()

    Label {
        id: buttonText

        anchors.centerIn: parent
        text: root.armed ? root.label + "?" : root.label
        color: root.contentColor
    }

    Timer {
        interval: Theme.motion.confirm
        running: root.armed
        onTriggered: root.armed = false
    }
}
