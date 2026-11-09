pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Everything the Settings app controls, saved to settings.json beside this file.
Singleton {
    id: root

    readonly property string hyprDir: Quickshell.env("HOME") + "/.config/hypr"
    readonly property int never: 2000000

    // Seconds. `never` turns a stage off.
    property alias idleDim: data.idleDim
    property alias idleScreenOff: data.idleScreenOff
    property alias idleLock: data.idleLock
    property alias idleSleep: data.idleSleep
    property alias dimPercent: data.dimPercent

    // 0 to 1. A negative normal brightness means not recorded yet.
    property alias normalBrightness: data.normalBrightness
    property alias nightBrightness: data.nightBrightness
    // Kelvin. 6500 means no change to the screen.
    property alias normalTemperature: data.normalTemperature
    property alias nightTemperature: data.nightTemperature
    property alias nightFadeSeconds: data.nightFadeSeconds

    // Minutes since midnight.
    property alias autoNight: data.autoNight
    property alias nightStart: data.nightStart
    property alias nightEnd: data.nightEnd

    // "sleep", "lock" or "nothing"
    property alias lidAction: data.lidAction
    property alias autoSaver: data.autoSaver
    property alias autoSaverPercent: data.autoSaverPercent

    property alias notificationSound: data.notificationSound
    property alias doNotDisturb: data.doNotDisturb
    property alias notificationSeconds: data.notificationSeconds
    property alias notificationSoundName: data.notificationSoundName
    property alias notificationMaxPopups: data.notificationMaxPopups
    property alias clipboardLimit: data.clipboardLimit
    // Per sender: "panel", "popup" or "off". notificationApps is every sender seen, for the settings list.
    property alias notificationRules: data.notificationRules
    property alias notificationApps: data.notificationApps

    // The active theme preset's id; the presets are in presets.json (ThemePresets).
    property alias themePreset: data.themePreset
    property alias themeApps: data.themeApps
    // Colors worked out from wallpapers, by "path|dark" or "path|light".
    property alias wallpaperPalettes: data.wallpaperPalettes
    property alias wallpaperDir: data.wallpaperDir

    property alias terminal: data.terminal
    property alias notesTabs: data.notesTabs
    property alias notesCurrent: data.notesCurrent
    property alias notesWrap: data.notesWrap
    property alias notesLineNumbers: data.notesLineNumbers
    property alias notesImagesWrapped: data.notesImagesWrapped
    property alias notesImagesUnwrapped: data.notesImagesUnwrapped
    property alias notesImageHeight: data.notesImageHeight
    property alias browser: data.browser
    // How often each app and command was launched, to sort the launcher.
    property alias launcherUsage: data.launcherUsage

    function writeIdleTimes() {
        const text = `# Written by Quickshell's settings page. hypridle.conf reads these.
$idleDim = ${idleDim}
$idleScreenOff = ${idleScreenOff}
$idleLock = ${idleLock}
$idleSleep = ${idleSleep}
`;
        Quickshell.execDetached(["sh", "-c", 'printf %s "$1" > "$2" && systemctl --user restart hypridle.service', "sh", text, hyprDir + "/hypridle-times.conf"]);
    }

    FileView {
        id: file

        path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
        blockLoading: true
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: data

            property int idleDim: 60
            property int idleScreenOff: 120
            property int idleLock: 125
            property int idleSleep: 600
            property int dimPercent: 10

            property real normalBrightness: -1
            property real nightBrightness: 0.5
            property int normalTemperature: 6500
            property int nightTemperature: 3500
            property int nightFadeSeconds: 3

            property bool autoNight: false
            property int nightStart: 1200
            property int nightEnd: 420

            property string lidAction: "sleep"
            property bool autoSaver: false
            property int autoSaverPercent: 20

            property bool notificationSound: true
            property bool doNotDisturb: false
            property int notificationSeconds: 6
            property string notificationSoundName: "message-new-instant"
            property int notificationMaxPopups: 5
            property int clipboardLimit: 300
            property var notificationRules: ({})
            property var notificationApps: []

            property string themePreset: "nord"
            property var themeApps: ({})
            property var wallpaperPalettes: ({})
            property string wallpaperDir: Quickshell.env("HOME") + "/.local/share/backgrounds"

            property string terminal: "kitty"
            property var notesTabs: []
            property string notesCurrent: ""
            property bool notesWrap: true
            property string notesLineNumbers: "absolute"   // or "relative"
            property string notesImagesWrapped: "fit"      // or "fixed"
            property string notesImagesUnwrapped: "fit"    // or "fixed", "asis"
            property int notesImageHeight: 200
            property string browser: ""                    // empty: the system default
            property var launcherUsage: ({})
        }
    }

    // Restarting hypridle on every click would be wasteful, so wait for the last change.
    readonly property string idleValues: [idleDim, idleScreenOff, idleLock, idleSleep].join(",")
    property string writtenIdleValues: ""
    onIdleValuesChanged: if (writtenIdleValues !== "" && idleValues !== writtenIdleValues)
        idleWrite.restart()
    Component.onCompleted: writtenIdleValues = idleValues

    Timer {
        id: idleWrite

        interval: 800
        onTriggered: {
            root.writtenIdleValues = root.idleValues;
            root.writeIdleTimes();
        }
    }
}
