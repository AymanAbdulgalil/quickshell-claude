import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import ".."
import "../controls"

// One network in range. Click to open its controls.
ColumnLayout {
    id: root

    property var network
    property bool expanded: false

    signal toggled

    readonly property var connection: NetworkState.savedFor(network.name)
    readonly property var info: NetworkState.scanInfo[network.name] ?? null
    readonly property bool busy: network.stateChanging
    readonly property bool usesPassword: network.security === WifiSecurityType.Wpa2Psk || network.security === WifiSecurityType.WpaPsk || network.security === WifiSecurityType.Sae
    readonly property bool open: network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe
    readonly property bool needsPassword: !network.known && usesPassword
    property string failure: ""

    function connectNow() {
        failure = "";
        if (needsPassword || showPasswordAgain) {
            if (password.text === "")
                return;
            network.connectWithPsk(password.text);
            password.text = "";
            showPasswordAgain = false;
        } else {
            network.connect();
        }
    }

    property bool showPasswordAgain: false
    readonly property bool passwordVisible: expanded && !network.connected && (needsPassword || showPasswordAgain)

    onPasswordVisibleChanged: {
        if (passwordVisible)
            password.focusNow();
    }

    Connections {
        target: root.network

        function onConnectionFailed(reason) {
            root.failure = reason === ConnectionFailReason.NoSecrets ? "Wrong password." : "Could not connect.";
            if (reason === ConnectionFailReason.NoSecrets)
                root.showPasswordAgain = true;
        }
    }

    Layout.fillWidth: true
    spacing: Theme.space.s

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Theme.control.row
        radius: Theme.shape.controlRadius
        color: rowArea.containsMouse || root.expanded ? Theme.colors.surfaceRaised : Theme.colors.clear

        Behavior on color {
            ColorMotion {
                preset: Theme.motion.quick
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.space.m
            anchors.rightMargin: Theme.space.m
            spacing: Theme.space.ml

            Part {
                slot: "networkIcon"

                readonly property string netState: root.busy ? "connecting" : "wifi"
                readonly property real signalStrength: root.network.signalStrength
                readonly property bool vpn: false
                readonly property int iconSize: 16
            }

            Column {
                Layout.fillWidth: true

                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.network.name
                    color: Theme.colors.foregroundStrong
                    font.pixelSize: Theme.fonts.body
                }

                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: {
                        const parts = [];
                        if (root.busy)
                            parts.push("Connecting");
                        else if (root.network.connected)
                            parts.push("Connected");
                        else if (root.network.known)
                            parts.push("Saved");
                        else if (root.open)
                            parts.push("Open");
                        else
                            parts.push("Secured");
                        if (root.info)
                            parts.push(root.info.band);
                        return parts.join(", ");
                    }
                    color: Theme.colors.muted
                }
            }

            Part {
                visible: root.network.connected
                slot: "powerGlyph"

                readonly property string glyph: "check"
                readonly property color tint: Theme.colors.accent
                readonly property int iconSize: 14
            }
        }

        MouseArea {
            id: rowArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.space.m
        Layout.rightMargin: Theme.space.m
        Layout.bottomMargin: Theme.space.s
        visible: root.expanded
        spacing: Theme.space.s

        TextField {
            id: password

            visible: root.passwordVisible
            placeholder: "Password"
            secret: true
            onAccepted: root.connectNow()
        }

        Label {
            Layout.fillWidth: true
            visible: !root.open && !root.usesPassword && !root.network.known
            wrapMode: Text.WordWrap
            text: "This network needs a login certificate or account, which this panel cannot set up. Use nm-connection-editor."
            color: Theme.colors.muted
        }

        Label {
            Layout.fillWidth: true
            visible: root.failure !== ""
            wrapMode: Text.WordWrap
            text: root.failure
            color: Theme.colors.error
        }

        SavedControls {
            visible: root.connection !== null
            connection: root.connection
        }

        InfoRow {
            label: "Security"
            value: root.info?.security ?? ""
        }

        InfoRow {
            label: "Link speed"
            value: root.info?.rate ?? ""
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.s

            ActionButton {
                label: root.network.connected ? "Disconnect" : "Connect"
                enabled: root.open || root.usesPassword || root.network.known
                busy: root.busy
                onActivated: root.network.connected ? root.network.disconnect() : root.connectNow()
            }

            ActionButton {
                visible: root.network.known
                label: "Forget"
                confirm: true
                onActivated: root.network.forget()
            }
        }
    }
}
