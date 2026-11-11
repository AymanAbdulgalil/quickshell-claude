pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// Which panel is open. Only one at a time: "power", "brightness", "audio" (volume and microphone),
// "launcher", "settings", "themes" and the other bar panels.
Singleton {
    id: root

    property string name: ""
    property var screen: null
    // Where to centre a small panel, in screen coordinates.
    property real anchorX: 0
    // Each bar icon's centre, so keybinds can open its panel in the right place.
    property var positions: ({})
    // The Settings app's side tab.
    property string settingsTab: "themes"
    // Notes is an ordinary panel since 2026-11-10: one at a time, closes on an outside click, fades windows.
    readonly property bool notesOpen: name === "notes"
    // True while Settings records a key combination, so a bare Super does not also open the launcher.
    property bool capturingKeys: false
    // The Dropdown whose list is open; the Settings window draws that list.
    property var activeDropdown: null
    // True for a moment after a workspace switch: open panels ease their hold on the keyboard (see keyboardMode).
    property bool yieldKeys: false
    readonly property bool anyOpen: name !== ""

    // What an open panel asks for. Panels stay open across workspace switches (2026-11-10). A window that holds the
    // keyboard exclusively keeps Hyprland from recording a window on the new workspace as focused, and closing the
    // panel then returned focus to the old one, which switched back to its workspace. So after a switch, panels yield
    // for a moment while the new workspace's last window is focused, then take the keyboard back.
    function keyboardMode(isOpen) {
        return !isOpen ? WlrKeyboardFocus.None : yieldKeys ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive;
    }

    signal positionsWanted

    function toggle(which, onScreen, x) {
        anchorX = x ?? anchorX;
        if (name === which && screen === onScreen)
            close();
        else {
            screen = onScreen;
            name = which;
        }
    }

    function close() {
        name = "";
        screen = null;
    }

    function focusedScreen() {
        const monitor = Hyprland.focusedMonitor?.name;
        return Quickshell.screens.find(s => s.name === monitor) ?? Quickshell.screens[0];
    }

    function toggleOnFocused(which) {
        toggle(which, focusedScreen());
    }

    // Opens the Settings app, at a side tab if one is given.
    function openSettings(tab) {
        if (tab)
            settingsTab = tab;
        screen = focusedScreen();
        name = "settings";
    }

    // From keybinds: qs ipc call panel toggle volume
    IpcHandler {
        target: "panel"

        function toggle(which: string): void {
            // Volume and microphone share one panel.
            if (which === "volume" || which === "microphone")
                which = "audio";
            // The brightness slider lives in the power panel.
            if (which === "brightness")
                which = "power";
            root.positionsWanted();
            root.toggle(which, root.focusedScreen(), root.positions[which] ?? 0);
        }
    }

    // qs ipc call settings open, or open power. Tab ids are in settings/SettingsWindow.qml.
    IpcHandler {
        target: "settings"

        function open(tab: string): void {
            root.openSettings(tab);
        }

        function toggle(): void {
            if (root.name === "settings")
                root.close();
            else
                root.openSettings("");
        }
    }

    // Set when the workspace changed while something was open.
    property bool switchedWhileOpen: false
    // The workspace a panel closed on. On an empty workspace Hyprland still holds the old window as focused and
    // switches back to it when the panel lets go of the keyboard; for a moment after closing, that is undone.
    property int stayOn: -1

    onAnyOpenChanged: {
        if (!anyOpen && switchedWhileOpen) {
            stayOn = Hyprland.focusedWorkspace?.id ?? -1;
            stayWindow.restart();
        }
        switchedWhileOpen = false;
    }

    Timer {
        id: stayWindow

        // Short, so a switch made on purpose just after closing is left alone.
        interval: 300
        onTriggered: root.stayOn = -1
    }

    Connections {
        target: Hyprland

        function onFocusedWorkspaceChanged() {
            const id = Hyprland.focusedWorkspace?.id ?? -1;
            if (root.anyOpen) {
                root.switchedWhileOpen = true;
                root.yieldKeys = true;
                refocus.restart();
            } else if (stayWindow.running && id !== root.stayOn && root.stayOn > 0) {
                Hyprland.dispatch(`hl.dsp.focus({ workspace = ${root.stayOn} })`);
                root.stayOn = -1;
                stayWindow.stop();
            }
        }
    }

    // Lets the yielded keyboard reach Hyprland first, then focuses the workspace's last window. An empty workspace has
    // none, and Hyprland cannot be told to focus nothing: see stayOn.
    Timer {
        id: refocus

        interval: 60
        onTriggered: {
            refocuser.running = false;
            refocuser.running = true;
        }
    }

    Process {
        id: refocuser

        command: ["hyprctl", "eval", 'local ws = hl.get_active_workspace() local w = ws and ws.last_window if w then hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address })) end']
        onExited: root.yieldKeys = false
    }

    // Flameshot has taken its picture by the time its window opens, so an open panel is still in the screenshot, and
    // closing it here hands the keyboard over.
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "openwindow" && /flameshot/i.test(event.data.split(",")[2] ?? ""))
                root.close();
        }
    }

    // The window-close key, while a panel holds the keyboard (hyprland/generate.py decides).
    GlobalShortcut {
        appid: "quickshell"
        name: "closePanel"
        description: "Close the open panel"
        onPressed: root.close()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "settings"
        description: "Open Settings"
        onPressed: root.name === "settings" ? root.close() : root.openSettings("")
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "notes"
        description: "Open notes"
        onPressed: root.toggleOnFocused("notes")
    }

    IpcHandler {
        target: "notes"

        function toggle(): void {
            root.toggleOnFocused("notes");
        }
    }
}
