pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import ".."

// Everything the network panel reads and does. Live wifi comes from Quickshell.Networking;
// saved connections, addresses and preferences come from nmcli.
Singleton {
    id: root

    // The network panel, or the network tab of Settings.
    readonly property bool active: Panels.name === "network" || (Panels.name === "settings" && Panels.settingsTab === "network")
    readonly property var devices: Networking.devices.values
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: devices.filter(d => d.type === DeviceType.Wired && d.nmManaged)
    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property bool hardwareOn: Networking.wifiHardwareEnabled
    readonly property string connectivity: {
        switch (Networking.connectivity) {
        case NetworkConnectivity.Full:
            return "Working";
        case NetworkConnectivity.Portal:
            return "Needs sign-in";
        case NetworkConnectivity.Limited:
            return "No internet";
        case NetworkConnectivity.None:
            return "Not connected";
        }
        return "";
    }

    // In-range wifi: connected first, then saved, then by signal. Hidden names are skipped.
    readonly property var networks: (wifi?.networks.values ?? []).filter(n => n.name !== "").slice().sort((a, b) => {
        if (a.connected !== b.connected)
            return a.connected ? -1 : 1;
        if (a.known !== b.known)
            return a.known ? -1 : 1;
        return b.signalStrength - a.signalStrength;
    })

    // What was in range last time, shown until the scan that starts on opening has answered.
    property var lastSeen: []
    readonly property var stale: lastSeen.filter(c => !networks.some(n => n.name === c.name))

    property var saved: []
    property var scanInfo: ({})
    property var details: ({})
    property string lastError: ""
    property bool scanning: false

    // From a nmcli terse line, where a colon inside a value is escaped.
    function splitTerse(line) {
        const parts = [];
        let current = "";
        for (let i = 0; i < line.length; i++) {
            if (line[i] === "\\" && i + 1 < line.length) {
                current += line[++i];
            } else if (line[i] === ":") {
                parts.push(current);
                current = "";
            } else {
                current += line[i];
            }
        }
        parts.push(current);
        return parts;
    }

    function savedFor(name) {
        return saved.find(c => c.wifi && c.name === name) ?? null;
    }

    function refresh() {
        savedReader.running = true;
        scanReader.running = true;
        hotspotReader.running = true;
        leaseReader.running = true;
        openvpnCheck.running = true;
        if (wifi) {
            detailReader.command = ["nmcli", "-t", "-f", "GENERAL.HWADDR,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS", "device", "show", wifi.name];
            detailReader.running = true;
        }
    }

    function rescan() {
        scanning = true;
        scanDone.restart();
        run(["nmcli", "device", "wifi", "rescan"]);
    }

    // One command at a time; the error, if any, shows in the panel.
    property var queue: []

    function run(command, env) {
        queue = queue.concat([{ command: command, env: env ?? {} }]);
        next();
    }

    function next() {
        if (runner.running || queue.length === 0)
            return;
        const job = queue[0];
        queue = queue.slice(1);
        lastError = "";
        runner.environment = job.env;
        runner.command = job.command;
        runner.running = true;
    }

    function setAutoconnect(uuid, on) {
        run(["nmcli", "connection", "modify", uuid, "connection.autoconnect", on ? "yes" : "no"]);
    }

    function setPriority(uuid, priority) {
        run(["nmcli", "connection", "modify", uuid, "connection.autoconnect-priority", String(priority)]);
    }

    function forget(uuid) {
        run(["nmcli", "connection", "delete", uuid]);
    }

    function bringUp(uuid) {
        // A VPN's imported file is touched when it connects, so the files list shows the latest used first.
        run(["sh", "-c", `
            nmcli connection up "$UUID" || exit 1
            name=$(nmcli -g connection.id connection show "$UUID")
            for f in "$DIR/$name.conf" "$DIR/$name.ovpn"; do [ -e "$f" ] && touch "$f"; done
            exit 0
        `], { UUID: uuid, DIR: vpnDir });
    }

    function bringDown(uuid) {
        run(["nmcli", "connection", "down", uuid]);
    }

    // Password goes through the environment and a pipe, never the command line, where any
    // process could read it.
    function joinHidden(ssid, password) {
        if (password === "") {
            run(["nmcli", "connection", "add", "type", "wifi", "con-name", ssid, "ssid", ssid, "wifi.hidden", "yes"]);
            run(["nmcli", "connection", "up", ssid]);
            return;
        }
        run(["nmcli", "connection", "add", "type", "wifi", "con-name", ssid, "ssid", ssid, "wifi.hidden", "yes", "wifi-sec.key-mgmt", "wpa-psk"]);
        run(["sh", "-c", 'printf "802-11-wireless-security.psk:%s\\n" "$PSK" | nmcli connection up "$1" passwd-file /dev/stdin', "sh", ssid], { PSK: password });
    }

    function deviceConnect(name, on) {
        run(["nmcli", "device", on ? "connect" : "disconnect", name]);
    }

    // --- Hotspot: one saved profile, edited here and switched on and off.
    readonly property var hotspot: saved.find(c => c.name === "Hotspot") ?? null
    readonly property bool hotspotOn: hotspot?.active ?? false
    property var hotspotConfig: ({ name: "", password: "", hidden: false, band: "" })
    property var hotspotClients: []

    // Passwords go through nmcli's editor on stdin, never the command line.
    function hotspotScript(on) {
        return `
            set -e
            nmcli connection show Hotspot >/dev/null 2>&1 || nmcli connection add type wifi ifname "$IFACE" con-name Hotspot autoconnect no ssid "$SSID" mode ap ipv4.method shared ipv6.method disabled wifi-sec.key-mgmt wpa-psk wifi-sec.proto rsn wifi-sec.pairwise ccmp wifi-sec.group ccmp wifi-sec.psk placeholder-only >/dev/null
            nmcli connection modify Hotspot 802-11-wireless.ssid "$SSID" 802-11-wireless.hidden "$HIDDEN" 802-11-wireless.band "$BAND" 802-11-wireless.channel ""
            printf 'set 802-11-wireless-security.psk %s\nsave persistent\nquit\n' "$PSK" | nmcli connection edit id Hotspot >/dev/null
            ${on ? "nmcli connection up Hotspot" : ""}
        `;
    }

    function randomPassword() {
        const chars = "abcdefghijkmnpqrstuvwxyz23456789";
        let out = "";
        for (let i = 0; i < 12; i++)
            out += chars[Math.floor(Math.random() * chars.length)];
        return out;
    }

    function saveHotspot(name, password, hidden, band, on) {
        run(["sh", "-c", hotspotScript(on)], {
            IFACE: wifi?.name ?? "wlan0",
            SSID: name,
            PSK: password,
            HIDDEN: hidden ? "yes" : "no",
            BAND: band
        });
    }

    function setHotspot(on) {
        if (!on) {
            if (hotspot)
                bringDown(hotspot.uuid);
            return;
        }
        if (hotspot)
            bringUp(hotspot.uuid);
        else
            saveHotspot(hotspotConfig.name || "Ay-lap", hotspotConfig.password || randomPassword(), false, "", true);
    }

    // --- VPN: every imported file is copied here first, which doubles as the recent list.
    readonly property string vpnDir: Quickshell.env("HOME") + "/.local/share/vpn"
    property bool openvpnAvailable: true

    function importVpn(path) {
        run(["sh", "-c", `
            set -e
            # A WireGuard key is 44 characters of base64. Proton puts "*****" there when a configuration is
            # downloaded again after it was created.
            if grep -qi '^\\[Interface' "$FILE"; then
                key=$(sed -n 's/^[[:space:]]*PrivateKey[[:space:]]*=[[:space:]]*//p' "$FILE" | tr -d '\r[:space:]')
                if ! printf %s "$key" | grep -Eq '^[A-Za-z0-9+/]{43}=$'; then
                    if [ "$key" = "*****" ] || printf %s "$key" | grep -q '^\\*'; then
                        echo "This file has its private key hidden (*****). Proton shows the key only when a configuration is first made: create a new one and download it straight away." >&2
                    else
                        echo "This file has no valid WireGuard private key." >&2
                    fi
                    exit 1
                fi
            fi
            mkdir -p "$DIR"
            chmod 700 "$DIR"
            base=$(basename "$FILE")
            stem=$(printf %s "\${base%.*}" | tr -c 'A-Za-z0-9_-' '-' | cut -c1-15)
            ext="\${base##*.}"
            dest="$DIR/$stem.$ext"
            [ "$FILE" = "$dest" ] || cp "$FILE" "$dest"
            chmod 600 "$dest"
            if grep -qi '^\\[Interface' "$dest"; then type=wireguard; else type=openvpn; fi
            if [ "$type" = openvpn ] && [ ! -e /usr/lib/NetworkManager/VPN/nm-openvpn-service.name ]; then
                echo "OpenVPN support is not installed: sudo pacman -S networkmanager-openvpn" >&2
                exit 1
            fi
            out=$(nmcli connection import type "$type" file "$dest")
            touch "$dest"
            # NetworkManager turns auto-connect on for imports, which brought the VPN up by itself at every
            # connection. A VPN only connects when asked.
            uuid=$(printf %s "$out" | sed -n 's/.*(\\([0-9a-f-]\\{36\\}\\)).*/\\1/p')
            [ -z "$uuid" ] || nmcli connection modify "$uuid" connection.autoconnect no
        `], { FILE: path, DIR: vpnDir });
    }

    // Renames an imported file, and the VPN made from it (same name), to at most 15 safe characters.
    function renameVpnFile(path, newName) {
        run(["sh", "-c", `
            set -e
            base=$(basename "$FILE")
            old="\${base%.*}"
            ext="\${base##*.}"
            new=$(printf %s "$NEW" | tr -c 'A-Za-z0-9_-' '-' | cut -c1-15)
            [ -n "$new" ] && [ "$new" != "$old" ] || exit 0
            if [ -e "$DIR/$new.$ext" ]; then echo "A file named $new.$ext already exists." >&2; exit 1; fi
            mv "$FILE" "$DIR/$new.$ext"
            if nmcli -g connection.id connection show "$old" >/dev/null 2>&1; then
                nmcli connection modify "$old" connection.id "$new"
            fi
        `], { FILE: path, NEW: newName, DIR: vpnDir });
    }

    // Deletes an imported file only. A VPN already set up from it stays until removed itself.
    function deleteVpnFile(path) {
        run(["rm", "-f", "--", path]);
    }

    function setVpnLogin(uuid, user, password) {
        run(["sh", "-c", `
            set -e
            [ -z "$VPN_USER" ] || nmcli connection modify "$UUID" +vpn.data "username=$VPN_USER"
            nmcli connection modify "$UUID" +vpn.data password-flags=0
            printf 'set vpn.secrets password=%s\nsave persistent\nquit\n' "$VPN_PASS" | nmcli connection edit uuid "$UUID" >/dev/null
        `], { UUID: uuid, VPN_USER: user, VPN_PASS: password });
    }

    onActiveChanged: {
        if (!active)
            lastSeen = networks.map(n => ({ name: n.name, signalStrength: n.signalStrength }));
        if (wifi)
            wifi.scannerEnabled = active;
        if (active)
            refresh();
    }

    Timer {
        id: scanDone

        interval: 4000
        onTriggered: root.scanning = false
    }

    Timer {
        id: refreshDelay

        interval: 400
        onTriggered: root.refresh()
    }

    Process {
        id: runner

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    root.lastError = text.trim().split("\n").pop().replace(/^Error: /, "");
            }
        }
        onExited: {
            root.next();
            refreshDelay.restart();
        }
    }

    // Keeps the lists current while the panel is open.
    Process {
        running: root.active
        command: ["nmcli", "monitor"]

        stdout: SplitParser {
            onRead: refreshDelay.restart()
        }
    }

    // Network connection types worth showing; docker bridges and loopback are not.
    readonly property var userTypes: ({
            "802-11-wireless": "Wi-Fi",
            "802-3-ethernet": "Ethernet",
            "vpn": "VPN",
            "wireguard": "WireGuard",
            "bluetooth": "Bluetooth",
            "gsm": "Mobile"
        })

    Process {
        id: savedReader

        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,AUTOCONNECT,AUTOCONNECT-PRIORITY,ACTIVE,DEVICE,TIMESTAMP", "connection", "show"]

        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of text.split("\n")) {
                    if (line === "")
                        continue;
                    const f = root.splitTerse(line);
                    const label = root.userTypes[f[2]];
                    if (!label)
                        continue;
                    list.push({
                        name: f[0],
                        uuid: f[1],
                        type: f[2],
                        typeLabel: label,
                        wifi: f[2] === "802-11-wireless",
                        vpn: f[2] === "vpn" || f[2] === "wireguard",
                        autoconnect: f[3] === "yes",
                        priority: parseInt(f[4]) || 0,
                        active: f[5] === "yes",
                        device: f[6],
                        lastUsed: parseInt(f[7]) || 0
                    });
                }
                list.sort((a, b) => b.priority - a.priority || a.name.localeCompare(b.name));
                root.saved = list;
            }
        }
    }

    Process {
        id: scanReader

        command: ["nmcli", "-t", "-f", "SSID,FREQ,RATE,SECURITY", "device", "wifi", "list", "--rescan", "no"]

        stdout: StdioCollector {
            onStreamFinished: {
                const info = {};
                for (const line of text.split("\n")) {
                    const f = root.splitTerse(line);
                    if (f[0] && !info[f[0]])
                        info[f[0]] = { band: parseInt(f[1]) >= 5000 ? "5 GHz" : "2.4 GHz", rate: f[2], security: f[3] };
                }
                root.scanInfo = info;
            }
        }
    }

    Process {
        id: detailReader

        stdout: StdioCollector {
            onStreamFinished: {
                const d = {};
                for (const line of text.split("\n")) {
                    const at = line.indexOf(":");
                    if (at < 0)
                        continue;
                    const key = line.slice(0, at).replace(/\[\d+\]/, "");
                    if (!d[key])
                        d[key] = line.slice(at + 1).replace(/\\/g, "");
                }
                root.details = d;
            }
        }
    }

    Process {
        id: hotspotReader

        command: ["sh", "-c", "nmcli -s -g 802-11-wireless.ssid,802-11-wireless-security.psk,802-11-wireless.hidden,802-11-wireless.band connection show Hotspot 2>/dev/null; hostname"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length >= 5) {
                    root.hotspotConfig = {
                        name: lines[0].replace(/\\/g, ""),
                        password: lines[1].replace(/\\/g, ""),
                        hidden: lines[2] === "yes",
                        band: lines[3]
                    };
                } else {
                    root.hotspotConfig = { name: lines[lines.length - 1] || "Hotspot", password: root.randomPassword(), hidden: false, band: "" };
                }
            }
        }
    }

    Process {
        id: leaseReader

        command: ["sh", "-c", "cat /var/lib/NetworkManager/dnsmasq-*.leases 2>/dev/null || true"]

        stdout: StdioCollector {
            onStreamFinished: root.hotspotClients = text.split("\n").filter(l => l.trim() !== "").map(l => {
                const f = l.split(" ");
                return f[3] && f[3] !== "*" ? f[3] : f[2];
            })
        }
    }

    Process {
        id: openvpnCheck

        command: ["test", "-e", "/usr/lib/NetworkManager/VPN/nm-openvpn-service.name"]
        onExited: code => root.openvpnAvailable = code === 0
    }
}
