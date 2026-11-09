import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Wayland
import ".."
import "../controls"
import "../bar"

BarPanel {
    id: panel

    name: "power"


    function formatDuration(seconds) {
        const minutes = Math.round(seconds / 60);
        const d = Math.floor(minutes / 1440);
        const h = Math.floor(minutes % 1440 / 60);
        const m = minutes % 60;
        if (d > 0)
            return d + "d " + h + "h";
        return h > 0 ? h + "h " + m + "m" : m + "m";
    }

    function run(command) {
        Panels.close();
        Quickshell.execDetached(command);
    }

    readonly property string remainingText: {
        if (PowerInfo.full)
            return "Fully charged";
        if (PowerInfo.timeRemaining <= 0)
            return PowerInfo.discharging ? "Estimating time left" : "Plugged in";
        return formatDuration(PowerInfo.timeRemaining) + (PowerInfo.charging ? " to full" : " left");
    }


    // Charge and time left.
    RowLayout {
        Layout.fillWidth: true

        Label {
            text: PowerInfo.percent + "%"
            color: PowerInfo.tint
            Behavior on color {
                ColorMotion {}
            }
            font.pixelSize: Theme.fonts.display
            font.weight: Theme.fonts.weight
        }

        // Sits on the same line as the big number's foot.
        Label {
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: Theme.space.xs
            text: PowerInfo.technology
            color: Theme.colors.muted
        }

        Item {
            Layout.fillWidth: true
        }

        Column {
            spacing: Theme.space.xxs

            Label {
                anchors.right: parent.right
                text: panel.remainingText
                color: Theme.colors.foregroundStrong
                font.pixelSize: Theme.fonts.body
                font.weight: Theme.fonts.weight
            }

            Label {
                anchors.right: parent.right
                text: (PowerInfo.charging ? "charging at " : PowerInfo.discharging ? "using " : "") + (PowerInfo.full ? "" : PowerInfo.power.toFixed(1) + " W")
                color: Theme.colors.muted
            }
        }

    }

    // Charge against capacity against capacity when new.
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.space.s

        Part {
            slot: "powerGauge"
            Layout.fillWidth: true

            readonly property real charge: PowerInfo.energyNew > 0 ? PowerInfo.energy / PowerInfo.energyNew : 0
            readonly property real capacity: PowerInfo.health
            readonly property color tint: PowerInfo.tint

            // How much of the battery's life is used, in the part it has lost.
            Item {
                x: parent.width * parent.capacity
                width: parent.width * (1 - parent.capacity)
                height: parent.height
                visible: PowerInfo.battery?.healthSupported ?? false

                Rectangle {
                    anchors.centerIn: parent
                    width: wearText.implicitWidth + Theme.space.xs
                    height: parent.height
                    color: Theme.colors.surface
                }

                Label {
                    id: wearText

                    anchors.centerIn: parent
                    text: Math.round((1 - PowerInfo.health) * 100) + "%"
                    color: Theme.colors.muted
                    font.pixelSize: Theme.fonts.caption
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            component Legend: Label {
                color: Theme.colors.muted
            }

            Legend {
                text: PowerInfo.energy.toFixed(1) + " Wh left"
            }

            Item {
                Layout.fillWidth: true
            }

            Legend {
                text: PowerInfo.energyFull.toFixed(1) + " full"
            }

            Item {
                Layout.fillWidth: true
            }

            Legend {
                text: PowerInfo.energyNew.toFixed(1) + " new"
            }
        }
    }

    // Facts, two by two. Always the same four, so the panel never changes height.
    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: Theme.space.s
        Layout.bottomMargin: Theme.space.s
        columns: 2
        uniformCellWidths: true
        columnSpacing: Theme.space.xxl
        rowSpacing: Theme.space.xs

        Repeater {
            model: [
                ["Voltage", PowerInfo.voltage > 0 ? PowerInfo.voltage.toFixed(2) + " V" : "N/A"],
                ["Current", !PowerInfo.charging && PowerInfo.current > 0 ? PowerInfo.current.toFixed(2) + " A" : "N/A"],
                ["Cycles", PowerInfo.cycles > 0 ? PowerInfo.cycles.toLocaleString(Qt.locale("en_US"), "f", 0) : "N/A"],
                ["Uptime", PowerInfo.uptime > 0 ? panel.formatDuration(PowerInfo.uptime) : "N/A"]
            ]

            RowLayout {
                required property var modelData

                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true
                    text: parent.modelData[0]
                    color: Theme.colors.muted
                }

                Label {
                    text: parent.modelData[1]
                    color: Theme.colors.foreground
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.space.xxs

        SliderRow {
            slot: "brightnessIcon"
            value: Brightness.level
            off: NightMode.enabled
            onMoved: v => Brightness.set(v)
            onIconClicked: NightMode.set(!NightMode.enabled)
        }

        SliderRow {
            slot: "powerGlyph"
            glyph: "temperature"
            readonly property int kelvin: NightMode.enabled ? Settings.nightTemperature : Settings.normalTemperature
            value: (kelvin - 2500) / 4000
            valueText: kelvin
            onMoved: v => {
                const k = 2500 + Math.round(v * 80) * 50;
                if (NightMode.enabled)
                    Settings.nightTemperature = k;
                else
                    Settings.normalTemperature = k;
            }
            onIconClicked: {
                if (NightMode.enabled)
                    Settings.nightTemperature = 4000;
                else
                    Settings.normalTemperature = 6500;
            }
        }
    }

    // Power profile. Equal-width segments.
    Tabs {
        options: [[PowerProfile.PowerSaver, "Saver"], [PowerProfile.Balanced, "Balanced"]].concat(PowerProfiles.hasPerformanceProfile ? [[PowerProfile.Performance, "Turbo"]] : [])
        value: PowerProfiles.profile
        onPicked: v => PowerProfiles.profile = v
    }

    // Toggles and actions, least disruptive first.
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.space.s

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.s

            PanelButton {
                glyph: "night"
                label: "Night mode"
                on: NightMode.enabled
                onActivated: NightMode.set(!on)
            }

            PanelButton {
                glyph: "stayOn"
                label: "Stay on"
                on: PowerState.stayOn
                onActivated: PowerState.setStayOn(!on)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.s

            PanelButton {
                glyph: "lock"
                label: "Lock"
                onActivated: panel.run(["loginctl", "lock-session"])
            }

            PanelButton {
                glyph: "sleep"
                label: "Sleep"
                onActivated: panel.run(PowerState.lockedThen("systemctl suspend"))
            }

            PanelButton {
                glyph: "hibernate"
                label: "Hibernate"
                confirm: true
                available: PowerState.canHibernate
                onActivated: panel.run(PowerState.lockedThen("systemctl hibernate"))
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.s

            PanelButton {
                glyph: "logout"
                label: "Log out"
                confirm: true
                onActivated: {
                    Panels.close();
                    Quickshell.execDetached(["systemctl", "--user", "stop", "hyprpolkitagent"]);
                    Hyprland.dispatch("hl.dsp.exit()");
                }
            }

            PanelButton {
                glyph: "reboot"
                label: "Reboot"
                confirm: true
                onActivated: panel.run(["sh", "-c", "systemctl --user stop hyprpolkitagent; systemctl reboot --no-wall"])
            }

            PanelButton {
                glyph: "power"
                label: "Power off"
                confirm: true
                onActivated: panel.run(["sh", "-c", "systemctl --user stop hyprpolkitagent; systemctl poweroff --no-wall"])
            }
        }
    }
}
