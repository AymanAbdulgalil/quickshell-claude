import QtQuick
import Quickshell
import ".."

// Builds a panel the first time it opens and releases it a minute after it closes, so closed panels cost nothing.
Item {
    id: root

    property string panelName
    default required property Component panel

    property bool wanted: Panels.name === panelName
    // Built a few seconds after start and kept, for the panels whose first open was slow.
    property bool keep: false
    property bool held: false

    onWantedChanged: {
        if (wanted) {
            release.stop();
            held = true;
        } else {
            if (!root.keep)
                release.restart();
        }
    }

    Timer {
        running: root.keep
        interval: 4000
        onTriggered: root.held = true
    }

    Timer {
        id: release

        interval: 60000
        onTriggered: root.held = false
    }

    LazyLoader {
        active: root.held || root.wanted
        component: root.panel
    }
}
