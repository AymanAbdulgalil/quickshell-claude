import QtQuick
import Quickshell
import ".."
import "../power"

// Notifications for things the system does by itself: joining or switching networks, a VPN going up or down,
// Bluetooth devices connecting, night mode and battery saver following their rules, low battery.
// Nothing is sent for a change made in that thing's own open panel, or in the first seconds after start.
// Inputs: network (NetworkIndicator), bluetooth (BluetoothIndicator)
Item {
    id: root

    property var network
    property var bluetooth
    property bool ready: false

    function send(app, title, body, urgent) {
        const args = ["notify-send", "-a", app, "-u", urgent ? "critical" : "low"];
        if (!urgent)
            args.push("-h", "boolean:suppress-sound:true");
        Quickshell.execDetached(args.concat([title, body ?? ""]));
    }

    // Starting up connects everything at once; none of that is news.
    Timer {
        running: true
        interval: 8000
        onTriggered: {
            root.lastNetwork = root.currentNetwork;
            root.lastVpn = root.network?.vpn ?? false;
            root.lastDevices = root.currentDevices;
            root.ready = true;
        }
    }

    // --- Network. Settles for 2 seconds first, so a switch reads as one change.
    readonly property string currentNetwork: network?.wiredUp ? "Ethernet" : (network?.wifiNetwork?.name ?? "")
    property string lastNetwork: ""

    onCurrentNetworkChanged: if (ready)
        networkSettle.restart()

    Timer {
        id: networkSettle

        interval: 2000
        onTriggered: {
            const now = root.currentNetwork;
            const before = root.lastNetwork;
            if (now === before)
                return;
            root.lastNetwork = now;
            if (Panels.name === "network")
                return;
            if (now === "")
                root.send("Network", "Disconnected", "Lost " + before + ".");
            else if (before === "")
                root.send("Network", "Connected to " + now, "");
            else
                root.send("Network", "Switched to " + now, "Was " + before + ".");
        }
    }

    // --- VPN
    property bool lastVpn: false
    readonly property bool vpnUp: network?.vpn ?? false

    onVpnUpChanged: {
        if (!ready || vpnUp === lastVpn)
            return;
        lastVpn = vpnUp;
        if (Panels.name !== "network" && Panels.name !== "settings")
            send("VPN", vpnUp ? "VPN connected" : "VPN disconnected", "");
    }

    // --- Bluetooth devices
    readonly property var currentDevices: (bluetooth?.linked ?? []).map(d => d.name)
    property var lastDevices: []

    onCurrentDevicesChanged: {
        if (!ready)
            return;
        const now = currentDevices;
        const joined = now.filter(n => !lastDevices.includes(n));
        const left = lastDevices.filter(n => !now.includes(n));
        lastDevices = now;
        if (Panels.name === "bluetooth")
            return;
        for (const name of joined)
            send("Bluetooth", name + " connected", "");
        for (const name of left)
            send("Bluetooth", name + " disconnected", "");
    }

    // --- Night mode and battery saver following their rules
    Connections {
        target: NightMode

        function onScheduled(on) {
            root.send("Night mode", on ? "Night mode on" : "Night mode off", "By the schedule in Settings > Display.");
        }
    }

    Connections {
        target: PowerState

        function onAutoSaver(on) {
            root.send("Battery saver", on ? "Battery saver on" : "Battery saver off",
                      on ? "Battery at " + PowerInfo.percent + "%." : "Back to the previous power profile.");
        }
    }

    // --- Low battery: once at 15% and once at 7% while discharging.
    property int warnedAt: 100

    readonly property int batteryLevel: PowerInfo.discharging ? PowerInfo.percent : 100

    onBatteryLevelChanged: {
        if (batteryLevel > 20) {
            warnedAt = 100;
            return;
        }
        for (const mark of [7, 15]) {
            if (batteryLevel <= mark && warnedAt > mark) {
                warnedAt = mark;
                send("Battery", "Battery at " + batteryLevel + "%", mark === 7 ? "Plug in now." : "Plug in soon.", mark === 7);
                return;
            }
        }
    }
}
