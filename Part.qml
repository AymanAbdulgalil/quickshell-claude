import QtQuick
// Parts load by path, so nothing else makes Quickshell include these folders.
import "parts/workspace"
import "parts/network"
import "parts/bluetooth"
import "parts/battery"
import "parts/clock"
import "parts/language"
import "parts/power"
import "parts/volume"
import "parts/microphone"
import "parts/camera"
import "parts/clipboard"
import "parts/notifications"
import "parts/logo"

// A swappable element. `slot` names an entry in Theme.parts. Declare the part's
// inputs as extra properties here; the loaded part reads them from `parent`.
Loader {
    property string slot

    source: Qt.resolvedUrl("parts/" + Theme.parts[slot] + ".qml")
}
