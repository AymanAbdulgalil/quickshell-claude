import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import ".."
import "../controls"

// This laptop's Bluetooth settings. Pairing and connecting stay in the bar's Bluetooth panel.
ColumnLayout {
    id: page

    readonly property var adapter: Bluetooth.defaultAdapter

    spacing: Theme.space.xs

    PageTitle {
        text: "Bluetooth"
    }

    Label {
        Layout.fillWidth: true
        visible: !page.adapter
        text: "No Bluetooth adapter found."
        color: Theme.colors.muted
    }

    SettingRow {
        visible: !!page.adapter
        label: "Bluetooth"
        SettingSwitch {
            checked: page.adapter?.enabled ?? false
            onToggled: on => page.adapter.enabled = on
        }
    }

    InfoRow {
        label: "Name"
        value: page.adapter?.name ?? ""
    }
    InfoRow {
        label: "Adapter"
        value: page.adapter?.adapterId ?? ""
    }

    SettingRow {
        visible: !!page.adapter
        label: "Visible to others, 3 min"
        SettingSwitch {
            checked: page.adapter?.discoverable ?? false
            onToggled: on => {
                page.adapter.discoverableTimeout = 180;
                page.adapter.discoverable = on;
            }
        }
    }

    SettingRow {
        visible: !!page.adapter
        label: "Accept pairing"
        SettingSwitch {
            checked: page.adapter?.pairable ?? false
            onToggled: on => page.adapter.pairable = on
        }
    }
}
