import QtQuick
import QtQuick.Layouts
import ".."

// A square action or toggle. With `confirm`, the first click arms it and a second
// click within a few seconds runs it, so a stray click cannot power off the laptop.
Rectangle {
    id: root

    property string glyph
    property string label
    property bool on: false
    property bool confirm: false
    property bool available: true
    property bool armed: false

    signal activated

    function press() {
        if (!available)
            return;
        if (confirm && !armed) {
            armed = true;
            return;
        }
        armed = false;
        activated();
    }

    property color contentColor: !available ? Theme.colors.inactive : (armed || on) ? Theme.colors.onAccent : Theme.colors.foreground

    // Equal preferred widths make every button in a row the same size.
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: 54
    radius: Theme.shape.controlRadius
    color: armed ? Theme.colors.error : on ? Theme.colors.accent : (area.containsMouse && available) ? Theme.colors.surfaceHover : Theme.colors.surfaceRaised

    Behavior on color {
        ColorMotion {
            preset: Theme.motion.quick
        }
    }

    Behavior on contentColor {
        ColorMotion {
            preset: Theme.motion.quick
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 5

        Part {
            slot: "powerGlyph"
            anchors.horizontalCenter: parent.horizontalCenter

            readonly property string glyph: root.glyph
            readonly property color tint: root.contentColor
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.armed ? root.label + "?" : root.label
            color: root.contentColor
        }
    }

    Timer {
        interval: Theme.motion.confirm
        running: root.armed
        onTriggered: root.armed = false
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.available ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.press()
    }
}
