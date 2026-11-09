pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import ".."

Singleton {
    id: root

    readonly property bool panelOpen: Panels.name === "power"
    // Survives Quickshell restarting, but not logging out or rebooting: the file is in the login's runtime folder, and only counts for this Hyprland session.
    property bool stayOn: false
    readonly property string sessionId: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ?? ""
    // What logind says: "yes", "challenge", "no" (turned off) or "na" (not supported).
    property string hibernateStatus: "na"
    readonly property bool canHibernate: hibernateStatus === "yes" || hibernateStatus === "challenge"

    function setStayOn(on) {
        stayOn = on;
        stayOnFile.setText(on ? sessionId : "");
    }

    FileView {
        id: stayOnFile

        path: Quickshell.env("XDG_RUNTIME_DIR") + "/quickshell-stay-on"
        blockLoading: true
        printErrors: false
    }

    Component.onCompleted: stayOn = sessionId !== "" && stayOnFile.text().trim() === sessionId

    // Written to the journal so a Stay on that ended early can be traced: journalctl -t quickshell-stay-on
    onStayOnChanged: Quickshell.execDetached(["logger", "-t", "quickshell-stay-on", stayOn ? "on" : "off"])

    // Second lock on idling, beside the bar's Wayland inhibitor: it does not depend on the bar's window surviving
    // sleep or a screen change. hypridle honors it ("systemd idle inhibit active"). Sleep requested by hand still works.
    Process {
        running: root.stayOn
        // Tied to this shell: left behind by a restart, it would keep the screen from ever idling.
        command: ["setpriv", "--pdeathsig", "TERM", "systemd-inhibit", "--what=idle", "--who=Quickshell", "--why=Stay on", "--mode=block", "setpriv", "--pdeathsig", "TERM", "sleep", "infinity"]
    }

    // Lock, wait for the lock screen to settle, then sleep. Suspending while hyprlock
    // is still starting left it stuck after accepting the password (2026-11-05).
    function lockedThen(action) {
        return ["sh", "-c", `
            loginctl lock-session
            for i in $(seq 30); do pidof hyprlock >/dev/null && break; sleep 0.1; done
            sleep 0.4
            ` + action];
    }

    function lidClosed() {
        if (Settings.lidAction === "sleep")
            Quickshell.execDetached(lockedThen("systemctl suspend"));
        else if (Settings.lidAction === "lock")
            Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    // Saver on low battery, and back to the previous profile afterwards.
    property var profileBeforeSaver: null
    // Saver switched on or back by itself (for a notification).
    signal autoSaver(bool on)
    readonly property bool wantsSaver: Settings.autoSaver && PowerInfo.discharging && PowerInfo.percent <= Settings.autoSaverPercent
    onWantsSaverChanged: {
        if (wantsSaver) {
            profileBeforeSaver = PowerProfiles.profile;
            PowerProfiles.profile = PowerProfile.PowerSaver;
            autoSaver(true);
        } else if (profileBeforeSaver !== null) {
            PowerProfiles.profile = profileBeforeSaver;
            profileBeforeSaver = null;
            autoSaver(false);
        }
    }

    onPanelOpenChanged: {
        PowerInfo.detailed = panelOpen;
        if (panelOpen) {
            NightMode.verify();
            readCanHibernate.running = true;
        }
    }

    Process {
        id: readCanHibernate

        command: ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", "CanHibernate"]

        stdout: StdioCollector {
            onStreamFinished: root.hibernateStatus = (text.match(/"(.*)"/) ?? [])[1] ?? "na"
        }
    }

    // From keybinds: qs ipc call power toggle
    IpcHandler {
        target: "power"

        // qs ipc call power stayOn true
        function stayOn(on: bool): void {
            root.setStayOn(on);
        }

        function lid(): void {
            root.lidClosed();
        }

        function toggleNight(): void {
            NightMode.set(!NightMode.enabled);
        }

        function toggle(): void {
            Panels.toggleOnFocused("power");
        }
    }
}
