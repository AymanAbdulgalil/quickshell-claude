import QtQuick
import ".."
import "../controls"

// One number of the timer picker: plus above, minus below (holding repeats), and the mouse wheel. It only asks for steps;
// the panel keeps the time, so minutes running past 59 carry into the hours.
Column {
    id: root

    property string text
    signal step(int by)

    spacing: Theme.space.xxs

    SettingStepButton {
        anchors.horizontalCenter: parent.horizontalCenter
        symbol: "+"
        onStep: root.step(1)
    }

    Label {
        width: 56
        horizontalAlignment: Text.AlignHCenter
        text: root.text
        color: Theme.colors.foregroundStrong
        font.family: Theme.fonts.familyMono
        font.pixelSize: Theme.fonts.display
        font.weight: Theme.fonts.weight

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => root.step(event.angleDelta.y > 0 ? 1 : -1)
        }
    }

    SettingStepButton {
        anchors.horizontalCenter: parent.horizontalCenter
        symbol: "-"
        onStep: root.step(-1)
    }
}
