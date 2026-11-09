import QtQuick
import ".."
import "../notifications"

Part {
    id: root

    slot: "notificationIcon"

    property var barScreen

    readonly property int count: Notifications.history.length
    readonly property bool off: Settings.doNotDisturb
    readonly property color tint: Theme.colors.foreground
    readonly property int iconSize: Theme.layout.barIconSize

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: Panels.toggle("notifications", root.barScreen)
    }
}
