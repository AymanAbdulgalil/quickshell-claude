import QtQuick
import Quickshell.Bluetooth
import ".."

Part {
    id: root

    slot: "bluetoothIcon"

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var known: adapter?.devices.values ?? []
    readonly property var linked: known.filter(d => d.connected)
    readonly property bool changing: known.some(d => d.pairing || d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting)

    readonly property string btState: {
        if (!adapter)
            return "none";
        switch (adapter.state) {
        case BluetoothAdapterState.Blocked:
            return "blocked";
        case BluetoothAdapterState.Disabled:
            return "off";
        case BluetoothAdapterState.Enabling:
        case BluetoothAdapterState.Disabling:
            return "changing";
        }
        if (changing)
            return "connecting";
        if (adapter.discovering)
            return "searching";
        return linked.length > 0 ? "connected" : "idle";
    }
    readonly property bool discoverable: adapter?.discoverable ?? false
    // A device reporting low battery gets a red dot.
    readonly property var dots: linked.map(d => d.batteryAvailable && d.battery < 0.2 ? Theme.colors.error : Theme.colors.accent)

    property var barScreen

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: Panels.toggle("bluetooth", root.barScreen)
    }
}
