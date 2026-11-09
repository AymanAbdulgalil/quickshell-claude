import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import ".."
import "../controls"

// One notification. Click runs its default action; right click dismisses it.
Rectangle {
    id: card

    property var notification
    // Popups time out; cards in the history list do not.
    property bool timed: false

    signal timedOut

    readonly property bool critical: Notifications.isCritical(notification)
    // Named icons that the theme does not have must not show a placeholder.
    function resolveIcon(icon) {
        if (!icon)
            return "";
        if (icon.startsWith("image://icon/"))
            return Quickshell.iconPath(icon.slice(13), true);
        if (icon.startsWith("/") || icon.includes("://"))
            return icon;
        return Quickshell.iconPath(icon, true);
    }

    readonly property string iconSource: resolveIcon(notification.image) || resolveIcon(notification.appIcon)
    // With one action a click runs it, so a button would only repeat that. With several, every one gets a button.
    readonly property var buttons: notification.actions.length > 1 ? notification.actions : []

    radius: Theme.shape.panelRadius
    color: Theme.colors.surface
    border.width: Theme.shape.borderWidth
    border.color: critical ? Theme.colors.error : Theme.colors.border
    implicitHeight: body.implicitHeight + 20

    Timer {
        // expireTimeout is in seconds; zero or less means the app left it to us.
        interval: (card.notification.expireTimeout > 0 ? card.notification.expireTimeout : Settings.notificationSeconds) * 1000
        running: card.timed && !card.critical && !area.containsMouse
        onTriggered: card.timedOut()
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                card.notification.dismiss();
            else
                Notifications.activate(card.notification);
        }
    }

    ColumnLayout {
        id: body

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.space.ml
        spacing: Theme.space.m

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.ml

            Image {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                visible: card.iconSource !== ""
                sourceSize.width: 64
                sourceSize.height: 64
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                source: card.iconSource
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.space.xxs

                Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: card.notification.summary
                    textFormat: Text.PlainText
                    color: Theme.colors.foregroundStrong
                    font.pixelSize: Theme.fonts.body
                    font.weight: Theme.fonts.weight
                }

                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 5
                    elide: Text.ElideRight
                    text: card.notification.body
                    textFormat: Text.StyledText
                    color: Theme.colors.foreground
                    linkColor: Theme.colors.accent
                    onLinkActivated: link => Quickshell.execDetached(["xdg-open", link])
                }

                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    elide: Text.ElideRight
                    text: card.notification.appName
                    color: Theme.colors.muted
                }
            }

            IconButton {
                Layout.alignment: Qt.AlignTop
                glyph: "close"
                onClicked: card.notification.dismiss()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: card.buttons.length > 0
            spacing: Theme.space.s

            Repeater {
                model: card.buttons

                ActionButton {
                    required property var modelData

                    label: modelData.text || "Open"
                    onActivated: modelData.invoke()
                }
            }
        }
    }
}
