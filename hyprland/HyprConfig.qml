pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// The model behind ~/.config/hypr/hyprland.lua: what Settings > Hyprland edits. Saved in hyprland.json; every change
// regenerates the Lua, which Hyprland checks before it replaces the live file. Visual options are in presets instead.
Singleton {
    id: root

    property alias monitors: data.monitors
    property alias env: data.env
    property alias autostart: data.autostart
    property alias options: data.options
    property alias gestures: data.gestures
    property alias devices: data.devices
    property alias binds: data.binds
    property alias workspaceBinds: data.workspaceBinds
    property alias windowRules: data.windowRules

    // Empty, or what Hyprland said was wrong with the last change. The live file is untouched then.
    property string lastError: ""
    property bool applying: false

    // Every option Hyprland has, from `hyprctl descriptions`. Read the first time a page asks.
    property var schema: []
    // What the connected screens can do, from `hyprctl monitors`.
    property var outputs: []

    function loadSchema() {
        if (schema.length === 0)
            schemaReader.running = true;
    }

    function loadOutputs() {
        outputReader.running = true;
    }

    function setOption(name, value) {
        const next = Object.assign({}, options);
        next[name] = value;
        options = next;
        changed();
    }

    function clearOption(name) {
        const next = Object.assign({}, options);
        delete next[name];
        options = next;
        changed();
    }

    // Replaces a list (`binds`, `monitors`...) with one entry changed.
    function replaced(list, index, changes) {
        return list.map((entry, i) => i === index ? Object.assign({}, entry, changes) : entry);
    }

    function removed(list, index) {
        return list.filter((entry, i) => i !== index);
    }

    function changed() {
        applyDelay.restart();
    }

    function model() {
        return {
            monitors: monitors,
            env: env,
            autostart: autostart,
            options: options,
            gestures: gestures,
            devices: devices,
            binds: binds,
            workspaceBinds: workspaceBinds,
            windowRules: windowRules
        };
    }

    Timer {
        id: applyDelay

        interval: 500
        onTriggered: {
            generator.payload = JSON.stringify(root.model()) + "\n";
            generator.running = false;
            generator.running = true;
        }
    }

    Process {
        id: generator

        property string payload

        command: [Quickshell.shellPath("hyprland/generate.py")]
        stdinEnabled: true
        onStarted: {
            root.applying = true;
            root.lastError = "";
            write(payload);
            stdinEnabled = false;
        }
        onExited: {
            stdinEnabled = true;
            root.applying = false;
        }

        stderr: StdioCollector {
            onStreamFinished: root.lastError = text.trim()
        }
    }

    Process {
        id: schemaReader

        command: ["hyprctl", "descriptions", "-j"]

        stdout: StdioCollector {
            onStreamFinished: root.schema = JSON.parse(text)
        }
    }

    Process {
        id: outputReader

        command: ["hyprctl", "monitors", "all", "-j"]

        stdout: StdioCollector {
            onStreamFinished: root.outputs = JSON.parse(text)
        }
    }

    FileView {
        path: Quickshell.shellPath("hyprland.json")
        blockLoading: true
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: data

            property var monitors: []
            property var env: []
            property var autostart: []
            property var options: ({})
            property var gestures: []
            property var devices: []
            property var binds: []
            property var workspaceBinds: ({ enabled: true, focusMod: "SUPER", moveMod: "SUPER + SHIFT" })
            property var windowRules: []
        }
    }
}
