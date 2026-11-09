pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

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
    // Notes opens beside other panels, so it is not `name`.
    property bool notesOpen: false
    // True while Settings records a key combination, so a bare Super does not also open the launcher.
    property bool capturingKeys: false
    // The Dropdown whose list is open; the Settings window draws that list.
    property var activeDropdown: null

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

    // Moving to another workspace closes whatever is open. Otherwise the launcher, closing later, handed focus back
    // to a window on the old workspace and Hyprland jumped back there.
    Connections {
        target: Hyprland

        function onFocusedWorkspaceChanged() {
            if (root.name !== "")
                root.close();
        }
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
        onPressed: root.notesOpen = !root.notesOpen
    }

    IpcHandler {
        target: "notes"

        function toggle(): void {
            root.notesOpen = !root.notesOpen;
        }
    }
}
