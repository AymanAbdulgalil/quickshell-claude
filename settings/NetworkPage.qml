import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import "../network"

// Network settings: VPN, hotspot and the adapter. Joining networks stays in the bar's network panel.
ColumnLayout {
    id: page

    property string tab: "vpn"
    property string expanded: ""

    spacing: Theme.space.m

    PageTitle {
        text: "Network"
    }

    Tabs {
        options: [["vpn", "VPN"], ["hotspot", "Hotspot"], ["adapter", "Adapter"]]
        value: page.tab
        onPicked: v => {
            page.tab = v;
            page.expanded = "";
        }
    }

    Label {
        Layout.fillWidth: true
        visible: NetworkState.lastError !== ""
        wrapMode: Text.WordWrap
        text: NetworkState.lastError
        color: Theme.colors.error
    }

    VpnPage {
        visible: page.tab === "vpn"
        expanded: page.expanded
        onToggled: id => page.expanded = page.expanded === id ? "" : id
    }

    HotspotPage {
        visible: page.tab === "hotspot"
    }

    // --- The hardware
    ColumnLayout {
        Layout.fillWidth: true
        visible: page.tab === "adapter"
        spacing: 5

        InfoRow {
            label: "Internet"
            value: NetworkState.connectivity
        }
        InfoRow {
            label: "Adapter"
            value: NetworkState.wifi?.name ?? "None"
        }
        InfoRow {
            label: "Hardware address"
            value: NetworkState.details["GENERAL.HWADDR"] ?? ""
        }
        InfoRow {
            label: "Address"
            value: NetworkState.details["IP4.ADDRESS"] ?? ""
        }
        InfoRow {
            label: "Gateway"
            value: NetworkState.details["IP4.GATEWAY"] ?? ""
        }
        InfoRow {
            label: "DNS"
            value: NetworkState.details["IP4.DNS"] ?? ""
        }
        InfoRow {
            label: "IPv6"
            value: NetworkState.details["IP6.ADDRESS"] ?? ""
        }

        SettingRow {
            label: "Connect automatically"
            visible: NetworkState.wifi !== null
            SettingSwitch {
                checked: NetworkState.wifi?.autoconnect ?? false
                onToggled: on => NetworkState.wifi.autoconnect = on
            }
        }

        SettingSection {
            visible: NetworkState.wired.length > 0
            text: "Ethernet"
        }
        Repeater {
            model: NetworkState.wired

            SettingRow {
                required property var modelData

                label: modelData.name + (modelData.hasLink ? "" : ", no cable")
                SettingSwitch {
                    checked: modelData.connected
                    onToggled: on => NetworkState.deviceConnect(modelData.name, on)
                }
            }
        }
    }
}
