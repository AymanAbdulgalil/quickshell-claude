pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import ".."

// Battery facts. UPower covers the live state; sysfs adds cycles and
// instant power, and is only read while `detailed` is true (the panel is open).
Singleton {
    id: root

    property bool detailed: false

    readonly property var device: UPower.displayDevice
    readonly property var battery: UPower.devices.values.find(d => d.isLaptopBattery) ?? null

    readonly property bool present: device.isPresent
    readonly property int percent: Math.round(device.percentage * 100)
    readonly property bool discharging: device.state === UPowerDeviceState.Discharging
    readonly property bool full: device.state === UPowerDeviceState.FullyCharged || (!discharging && percent >= 100)
    readonly property bool charging: !full && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge)
    readonly property bool low: !full && !charging && percent < 20
    readonly property string mode: full ? "full" : charging ? "charging" : low ? "low" : "normal"
    readonly property color tint: full ? Theme.colors.success : charging ? Theme.colors.warning : low ? Theme.colors.error : Theme.colors.foreground

    readonly property real energy: device.energy
    readonly property real energyFull: device.energyCapacity
    // Fraction of the capacity it had when new.
    readonly property real health: battery && battery.healthSupported ? battery.healthPercentage / 100 : 1
    readonly property real energyNew: energyFull / (health || 1)
    readonly property real timeRemaining: charging ? device.timeToFull : device.timeToEmpty

    // From sysfs.
    property var fields: ({})
    property real uptime: 0
    property var powerSamples: []

    readonly property string technology: fields.POWER_SUPPLY_TECHNOLOGY ?? ""
    readonly property int cycles: parseInt(fields.POWER_SUPPLY_CYCLE_COUNT) || 0
    readonly property real voltage: (parseInt(fields.POWER_SUPPLY_VOLTAGE_NOW) || 0) / 1e6
    readonly property real current: (parseInt(fields.POWER_SUPPLY_CURRENT_NOW) || 0) / 1e6
    // Averaged over the last 10 seconds: instant readings spike a lot.
    readonly property real power: powerSamples.length ? powerSamples.reduce((a, b) => a + b) / powerSamples.length : device.changeRate

    function samplePower() {
        // Some batteries report power directly, others voltage and current.
        const direct = parseInt(fields.POWER_SUPPLY_POWER_NOW);
        const watts = direct ? direct / 1e6 : voltage * current;
        if (watts > 0)
            powerSamples = powerSamples.concat([watts]).slice(-5);
    }

    function refresh() {
        uevent.reload();
        procUptime.reload();
    }

    onDetailedChanged: {
        powerSamples = [];
        if (detailed)
            refresh();
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.detailed
        onTriggered: root.refresh()
    }

    FileView {
        id: uevent

        path: "/sys/class/power_supply/" + (root.battery?.nativePath ?? "BAT0") + "/uevent"
        onLoaded: {
            const parsed = {};
            for (const line of text().split("\n")) {
                const at = line.indexOf("=");
                if (at > 0)
                    parsed[line.slice(0, at)] = line.slice(at + 1);
            }
            root.fields = parsed;
            root.samplePower();
        }
    }

    FileView {
        id: procUptime

        path: "/proc/uptime"
        onLoaded: root.uptime = parseFloat(text()) || 0
    }
}
