import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"

// Preferences of one saved connection. Inputs: connection (an entry from NetworkState.saved)
ColumnLayout {
    id: root

    property var connection

    Layout.fillWidth: true
    spacing: Theme.space.xs

    SettingRow {
        label: "Connect automatically"
        SettingSwitch {
            checked: root.connection?.autoconnect ?? false
            onToggled: on => NetworkState.setAutoconnect(root.connection.uuid, on)
        }
    }

    SettingRow {
        label: "Preference"
        visible: root.connection?.wifi ?? false
        SettingStepper {
            options: {
                const list = [];
                for (let i = 0; i <= 20; i++)
                    list.push(i);
                return list;
            }
            value: root.connection?.priority ?? 0
            onPicked: v => NetworkState.setPriority(root.connection.uuid, v)
        }
    }
}
