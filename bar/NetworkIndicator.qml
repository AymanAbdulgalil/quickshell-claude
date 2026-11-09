import QtQuick
import Quickshell.Io
import Quickshell.Networking
import ".."

Part {
    id: root

    slot: "networkIcon"

    readonly property var devices: Networking.devices.values
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    // nmManaged filters out docker's veth pairs, which also report as wired.
    readonly property var wired: devices.filter(d => d.type === DeviceType.Wired && d.nmManaged)
    readonly property bool wiredUp: wired.some(d => d.connected)
    readonly property bool wiredChanging: wired.some(d => d.state === ConnectionState.Connecting || d.state === ConnectionState.Disconnecting)
    readonly property var wifiNetwork: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property bool wifiUp: wifiNetwork !== null
    readonly property bool wifiChanging: wifi !== null && (wifi.state === ConnectionState.Connecting || wifi.state === ConnectionState.Disconnecting)
    readonly property bool wifiIdle: wifi !== null && Networking.wifiEnabled && Networking.wifiHardwareEnabled && !wifiUp && !wifiChanging

    // Empty when the link has working internet, otherwise the suffix for the state name.
    readonly property string problem: {
        if (!Networking.canCheckConnectivity)
            return "";
        switch (Networking.connectivity) {
        case NetworkConnectivity.Portal:
            return "-firewall";
        case NetworkConnectivity.None:
        case NetworkConnectivity.Limited:
            return "-no-internet";
        }
        return "";
    }

    property bool monitorMode: false
    property bool vpnActive: false

    readonly property string netState: {
        if (monitorMode)
            return "monitor";
        if (wiredUp)
            return "ethernet" + problem;
        if (wiredChanging)
            return "ethernet-connecting";
        if (!Networking.wifiHardwareEnabled)
            return "hardware-off";
        if (!Networking.wifiEnabled)
            return "software-off";
        if (wifi?.mode === WifiDeviceMode.AccessPoint)
            return "hotspot";
        if (wifiUp)
            return "wifi" + problem;
        if (wifiChanging)
            return "connecting";
        return searchWindow.running ? "searching" : "disconnected";
    }
    readonly property real signalStrength: wifiNetwork?.signalStrength ?? 0
    readonly property bool vpn: vpnActive

    // NetworkManager does not report when it is scanning, so "searching" is the
    // window after losing a link or enabling the radio; after that it settles.
    onWifiIdleChanged: if (wifiIdle)
        searchWindow.restart()
    Component.onCompleted: if (wifiIdle)
        searchWindow.restart()

    Timer {
        id: searchWindow

        interval: 20000
    }

    // VPN and monitor mode are not exposed by Quickshell.Networking. Re-check on change, no polling.
    Process {
        id: probe

        running: true
        command: ["sh", "-c", `
            mon=0; vpn=0
            grep -qsx 803 /sys/class/net/*/type && mon=1
            nmcli -t -f TYPE connection show --active | grep -qE '^(vpn|wireguard|tun)$' && vpn=1
            ls -d /sys/class/net/*/tun_flags >/dev/null 2>&1 && vpn=1
            grep -qs DEVTYPE=wireguard /sys/class/net/*/uevent && vpn=1
            echo $mon $vpn`]

        stdout: StdioCollector {
            onStreamFinished: {
                const flags = text.trim().split(" ");
                root.monitorMode = flags[0] === "1";
                root.vpnActive = flags[1] === "1";
            }
        }
    }

    Timer {
        id: probeDelay

        interval: 300
        onTriggered: probe.running = true
    }

    Process {
        running: true
        command: ["ip", "monitor", "link"]

        stdout: SplitParser {
            onRead: probeDelay.restart()
        }
    }

    Process {
        running: true
        command: ["nmcli", "monitor"]

        stdout: SplitParser {
            onRead: probeDelay.restart()
        }
    }

    property var barScreen

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: Panels.toggle("network", root.barScreen)
    }
}
