import QtQuick
import ".."

// Stays enabled at its limit. Disabling it while held left the repeat timer running, which kept pulling the value back.
InteractiveSurface {
    id: root

    property string symbol
    property bool atLimit: false

    signal step

    width: Theme.control.small
    height: Theme.control.small
    opacity: atLimit ? 0.4 : 1
    hoverColor: atLimit ? restColor : Theme.colors.surfaceHover
    onAtLimitChanged: if (atLimit)
        repeat.stop()
    onPressedChanged: {
        if (pressed && !atLimit) {
            step();
            repeat.interval = 350;
            repeat.start();
        } else {
            repeat.stop();
        }
    }

    Timer {
        id: repeat

        repeat: true
        onTriggered: {
            interval = 60;
            root.step();
        }
    }

    // Drawn, not a font glyph, so plus and minus sit exactly centred.
    Rectangle {
        anchors.centerIn: parent
        width: 9
        height: 1.5
        color: Theme.colors.foreground
    }

    Rectangle {
        anchors.centerIn: parent
        visible: root.symbol === "+"
        width: 1.5
        height: 9
        color: Theme.colors.foreground
    }
}
