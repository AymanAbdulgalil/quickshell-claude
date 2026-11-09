import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../controls"

BarPanel {
    id: panel

    name: "notifications"
    cardWidth: Theme.layout.notificationWidth


    RowLayout {
        Layout.fillWidth: true

        Label {
            Layout.fillWidth: true
            text: "Notifications"
        font.family: Theme.fonts.familyTitle
            color: Theme.colors.foregroundStrong
            font.pixelSize: Theme.fonts.body
            font.weight: Theme.fonts.weight
        }

        ActionButton {
            Layout.fillWidth: false
            Layout.preferredWidth: 80
            visible: Notifications.history.length > 0
            label: "Clear all"
            onActivated: Notifications.clearHistory()
        }

    }

    Label {
        Layout.fillWidth: true
        Layout.margins: Theme.space.m
        visible: Notifications.history.length === 0
        text: "Nothing new."
        color: Theme.colors.muted
    }

    Flickable {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(list.implicitHeight, Theme.layout.listMaxHeight)
        visible: Notifications.history.length > 0
        contentHeight: list.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: list

            width: parent.width
            spacing: Theme.layout.panelGap

            Repeater {
                model: Notifications.history

                NotificationCard {
                    required property var modelData

                    width: parent.width
                    notification: modelData
                }
            }
        }
    }
}
