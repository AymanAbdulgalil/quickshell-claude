import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"

ColumnLayout {
    id: page

    readonly property var config: NetworkState.hotspotConfig
    property bool hidden: false
    property string band: ""

    // Fields follow the saved profile until edited.
    onConfigChanged: {
        name.text = config.name;
        password.text = config.password;
        hidden = config.hidden;
        band = config.band;
    }

    property string qrText: ""

    // The standard format phones read to join a network directly.
    function wifiCode() {
        const esc = v => v.replace(/([\\;,:"])/g, "\\$1");
        return "WIFI:T:WPA;S:" + esc(name.text) + ";P:" + esc(password.text) + ";" + (page.hidden ? "H:true;" : "") + ";";
    }

    readonly property bool valid: name.text.length > 0 && password.text.length >= 8

    Layout.fillWidth: true
    spacing: Theme.space.s

    SettingRow {
        label: NetworkState.hotspotOn ? "Hotspot is on" : "Hotspot is off"
        SettingSwitch {
            checked: NetworkState.hotspotOn
            onToggled: on => NetworkState.setHotspot(on)
        }
    }

    Label {
        Layout.fillWidth: true
        visible: !NetworkState.hotspotOn
        wrapMode: Text.WordWrap
        text: "Turning this on disconnects Wi-Fi, because the card can only do one at a time."
        color: Theme.colors.muted
    }

    SettingSection {
        text: "Name"
    }
    TextField {
        id: name

        placeholder: "Network name"
    }

    SettingSection {
        text: "Password"
    }
    TextField {
        id: password

        placeholder: "At least 8 characters"
    }

    SettingRow {
        Layout.topMargin: Theme.space.s
        label: "Visible to everyone"
        SettingSwitch {
            checked: !page.hidden
            onToggled: on => page.hidden = !on
        }
    }

    SettingRow {
        label: "Band"
        Dropdown {
            options: [["", "Auto"], ["bg", "2.4"], ["a", "5"]]
            value: page.band
            onPicked: v => page.band = v
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Theme.space.xs
        spacing: Theme.space.s

        ActionButton {
            label: NetworkState.hotspotOn ? "Save and restart hotspot" : "Save"
            enabled: page.valid
            onActivated: NetworkState.saveHotspot(name.text, password.text, page.hidden, page.band, NetworkState.hotspotOn)
        }

        ActionButton {
            label: page.qrText === "" ? "Show QR code" : "Hide QR code"
            enabled: page.valid
            onActivated: page.qrText = page.qrText === "" ? page.wifiCode() : ""
        }
    }

    QrCode {
        visible: page.qrText !== ""
        content: page.qrText
        caption: "Scan to join " + name.text
        onClosed: page.qrText = ""
    }

    SettingSection {
        visible: NetworkState.hotspotClients.length > 0
        text: "Connected devices"
    }
    Repeater {
        model: NetworkState.hotspotClients

        Label {
            required property string modelData

            text: modelData
            color: Theme.colors.foreground
        }
    }
}
