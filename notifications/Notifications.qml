pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import ".."

// Replaces dunst: receives every desktop notification, shows popups, plays a sound, keeps history.
Singleton {
    id: root

    property var popups: []
    // Shown as a popup but kept out of the panel ("Show only"); dismissed when the popup goes.
    property var popupOnly: []
    readonly property var history: server.trackedNotifications.values.filter(n => !popupOnly.includes(n)).reverse()
    // Things the shell itself notifies about; other apps are added as they are seen.
    readonly property var builtInKinds: ["Network", "VPN", "Bluetooth", "Night mode", "Battery saver", "Battery"]
    readonly property var kinds: builtInKinds.concat(Settings.notificationApps.filter(a => !builtInKinds.includes(a)))

    // "panel" shows it and keeps it, "popup" shows it without keeping it, "off" does neither.
    function ruleFor(app) {
        return Settings.notificationRules[app] ?? "panel";
    }

    function setRule(app, rule) {
        const next = Object.assign({}, Settings.notificationRules);
        next[app] = rule;
        Settings.notificationRules = next;
    }

    function remember(app) {
        if (app !== "" && !Settings.notificationApps.includes(app))
            Settings.notificationApps = Settings.notificationApps.concat([app]);
    }

    function isCritical(n) {
        return n.urgency === NotificationUrgency.Critical;
    }

    function removePopup(n) {
        popups = popups.filter(p => p !== n);
        if (popupOnly.includes(n)) {
            popupOnly = popupOnly.filter(p => p !== n);
            n.dismiss();
        }
    }

    function clearHistory() {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
    }

    // The action a plain click means: the app's default one, if it has one.
    function defaultAction(n) {
        return n.actions.find(a => a.identifier === "default") ?? null;
    }

    // A click runs the app's default action, or its only action. An app that offers none is brought forward.
    function activate(n) {
        const action = defaultAction(n) ?? (n.actions.length === 1 ? n.actions[0] : null);
        if (action) {
            action.invoke();
            return;
        }
        if (n.desktopEntry !== "")
            Hyprland.dispatch(`hl.dsp.focus({ window = "class:^(?i)${n.desktopEntry}$" })`);
        n.dismiss();
    }

    function soundPath(name) {
        return "/usr/share/sounds/freedesktop/stereo/" + name + ".oga";
    }

    function preview(name) {
        Quickshell.execDetached(["pw-play", "--volume", "0.8", soundPath(name)]);
    }

    function playSound(n) {
        if (!Settings.notificationSound || n.hints["suppress-sound"] === true)
            return;
        const custom = n.hints["sound-file"];
        const file = custom ? custom : soundPath(isCritical(n) ? "dialog-warning" : Settings.notificationSoundName);
        Quickshell.execDetached(["pw-play", "--volume", "0.8", file]);
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        actionIconsSupported: false
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: false
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            root.remember(n.appName);
            const rule = root.ruleFor(n.appName);
            if (rule === "off")
                return;
            n.tracked = true;
            if (rule === "popup")
                root.popupOnly = root.popupOnly.concat([n]);
            const quiet = Settings.doNotDisturb && !root.isCritical(n);
            if (!quiet) {
                root.popups = root.popups.filter(p => p !== n).concat([n]);
                root.playSound(n);
            }
            n.closed.connect(() => root.removePopup(n));
        }
    }

    // From keybinds.
    IpcHandler {
        target: "notifications"

        // Runs the newest notification's first action.
        function act(): void {
            const n = root.history[0];
            if (!n)
                return;
            const action = root.defaultAction(n) ?? n.actions[0];
            if (action)
                action.invoke();
        }

        function dismiss(): void {
            const n = root.history[0];
            if (n)
                n.dismiss();
        }

        function toggleQuiet(): void {
            Settings.doNotDisturb = !Settings.doNotDisturb;
        }
    }
}
