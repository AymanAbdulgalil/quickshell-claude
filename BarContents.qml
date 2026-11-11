import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "bar"
import "controls"
import "power"
import "network"
import "bluetooth"
import "launcher"
import "notifications"
import "clipboard"
import "theming"
import "settings"
import "notes"
import "tasks"
import "timer"

// Everything inside the bar, plus the power widget. Bar.qml loads this in the background
// so the bar itself appears straight away, even while the system is still starting.
// Inputs: barScreen, barWindow
Item {
    id: root

    readonly property var barScreen: parent.barScreen
    readonly property var barWindow: parent.barWindow
    // Starts the theme manager with the bar: its keybind and passing changes on to other apps.
    readonly property var themeManager: ThemeManager
    // Starts clipboard history with the bar; it has no bar icon (Super+V).
    readonly property var clipboard: ClipboardState
    // Holds the Super shortcut. Singletons only exist once something refers to them, and the panel is built on demand.
    readonly property var launcher: LauncherState
    // Sends task reminders, so it must live whether or not the launcher was opened.
    readonly property var tasks: TaskStore
    // Rings timers, so it must live whether or not the launcher was opened.
    readonly property var timers: TimerStore

    readonly property bool vertical: Theme.layout.barVertical

    // Logo and workspaces. On a vertical bar everything stacks from the top, in the same order.
    Grid {
        anchors.left: root.vertical ? undefined : parent.left
        anchors.leftMargin: Theme.layout.barPadding
        anchors.top: root.vertical ? parent.top : undefined
        anchors.topMargin: Theme.layout.barPadding
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        columns: root.vertical ? 1 : 2
        columnSpacing: Theme.layout.groupSpacing - 2
        rowSpacing: Theme.layout.groupSpacing - 2
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Part {
            slot: "logoIcon"

            readonly property color tint: Theme.colors.foreground
            readonly property int iconSize: Theme.layout.barIconSize

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: Panels.name === "settings" ? Panels.close() : Panels.openSettings("")
            }
        }

        Workspaces {
            screen: root.barScreen
        }
    }

    Clock {
        anchors.centerIn: parent
    }

    // Read from the end: battery | wifi, Bluetooth | brightness, volume, microphone (only while recording),
    // camera (only while in use) | notifications, language. Groups sit further apart than icons in a group.
    // The clipboard has no icon: Super+V opens it in the middle of the screen.
    BarGroup {
        anchors.right: root.vertical ? undefined : parent.right
        // A little closer to the edge than the workspaces, since the battery's text has its own side bearing.
        anchors.rightMargin: Theme.layout.barPadding - 1
        anchors.bottom: root.vertical ? parent.bottom : undefined
        anchors.bottomMargin: Theme.layout.barPadding
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        gap: Theme.layout.groupSpacing

        // Whole pixels wide, so the icons after it never land between pixels and blur. Spaced from the status icons.
        Item {
            implicitWidth: Math.ceil(language.implicitWidth)
            implicitHeight: language.height

            Language {
                id: language

                anchors.centerIn: parent
            }
        }

        BarGroup {
            gap: Theme.layout.itemSpacing

            NotificationIndicator {
                barScreen: root.barScreen
            }

            // Reveal adds its own gap when it opens.
            BarGroup {
                gap: 0

                Reveal {
                    shown: camera.cameraOn

                    CameraIndicator {
                        id: camera
                    }
                }

                // Only while an app records, so the bar stays short the rest of the time.
                Reveal {
                    shown: AudioState.micInUse

                    SliderWidget {
                        panel: "audio"
                        slot: "microphoneIcon"
                        barScreen: root.barScreen
                        level: AudioState.micVolume
                        off: AudioState.micMuted
                        alert: true
                        onScrolled: up => AudioState.setMicVolume(AudioState.micVolume + (up ? 0.05 : -0.05))
                    }
                }

                SliderWidget {
                    panel: "audio"
                    slot: "volumeIcon"
                    barScreen: root.barScreen
                    level: AudioState.volume
                    off: AudioState.muted
                    onScrolled: up => AudioState.setVolume(AudioState.volume + (up ? 0.05 : -0.05))
                }
            }

            // The Bluetooth icon keeps blank room on both sides for its wave and device dots,
            // so this pair sits closer to look as evenly spaced as the other icons.
            BarGroup {
                leftPadding: root.vertical ? 0 : -4
                gap: Theme.layout.itemSpacing - 4

                BluetoothIndicator {
                    id: bluetoothIndicator

                    barScreen: root.barScreen
                }

                NetworkIndicator {
                    id: networkIndicator

                    barScreen: root.barScreen
                }
            }
        }

        Battery {
            onClicked: Panels.toggle("power", root.barScreen)
        }
    }

    SystemEvents {
        network: networkIndicator
        bluetooth: bluetoothIndicator
    }

    IdleInhibitor {
        window: root.barWindow
        enabled: PowerState.stayOn
    }

    // Panels are built when first opened and released after closing. Their state lives in singletons.
    PanelLoader {
        panelName: "power"

        PowerPanel {
            homeScreen: root.barScreen
            barWindow: root.barWindow
        }
    }

    PanelLoader {
        panelName: "launcher"

        LauncherOverlay {
            homeScreen: root.barScreen
        }
    }

    PanelLoader {
        panelName: "settings"

        SettingsWindow {
            homeScreen: root.barScreen
        }
    }

    PanelLoader {
        panelName: "notes"

        NotesPanel {
            homeScreen: root.barScreen
            barWindow: root.barWindow
        }
    }

    PanelLoader {
        panelName: "themes"

        ThemeSwitcher {
            homeScreen: root.barScreen
        }
    }

    PanelLoader {
        panelName: "clipboard"

        ClipboardPanel {
            homeScreen: root.barScreen
            barWindow: root.barWindow
        }
    }

    PanelLoader {
        panelName: "notifications"

        NotificationPanel {
            homeScreen: root.barScreen
            barWindow: root.barWindow
        }
    }

    PanelLoader {
        panelName: "network"
        keep: true

        NetworkPanel {
            homeScreen: root.barScreen
            barWindow: root.barWindow
        }
    }

    PanelLoader {
        panelName: "bluetooth"
        keep: true

        BluetoothPanel {
            homeScreen: root.barScreen
            barWindow: root.barWindow
        }
    }

    PanelLoader {
        panelName: "audio"

        SliderPanel {
            id: audioPanel

            name: "audio"
            homeScreen: root.barScreen
            barWindow: root.barWindow

            SliderRow {
                slot: "volumeIcon"
                value: AudioState.volume
                off: AudioState.muted
                onMoved: v => AudioState.setVolume(v)
                onIconClicked: AudioState.toggleMute()
            }

            DevicePicker {
                panel: audioPanel
                devices: AudioState.sinks
                current: AudioState.sink
                onPicked: node => AudioState.setSink(node)
            }

            SliderRow {
                slot: "microphoneIcon"
                value: AudioState.micVolume
                off: AudioState.micMuted
                alert: AudioState.micInUse
                onMoved: v => AudioState.setMicVolume(v)
                onIconClicked: AudioState.toggleMicMute()
            }

            DevicePicker {
                panel: audioPanel
                devices: AudioState.sources
                current: AudioState.source
                onPicked: node => AudioState.setSource(node)
            }
        }
    }
}
