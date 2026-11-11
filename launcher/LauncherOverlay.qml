import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../controls"
import "../tasks"
import "../timer"

// Launcher a little below the middle of the screen, with the time panel above it. Clicking a day in the calendar
// fades the launcher out and that day's tasks in, in the same place; clicking the day again, or back, returns.
// Clicking the clock does the same with the stopwatch and timers (2026-11-11).
PanelWindow {
    id: overlay

    property var homeScreen
    readonly property bool open: Panels.name === "launcher" && Panels.screen === homeScreen

    // Follows `open` a frame later, so it still fades in when built by opening.
    property bool shown: false
    // The day whose tasks show in the launcher's place; "" shows the launcher.
    property string tasksDay: ""
    // The stopwatch and timers show in the launcher's place.
    property bool timerShown: false
    readonly property bool launcherShown: tasksDay === "" && !timerShown

    function showDay(key) {
        timerShown = false;
        tasksDay = tasksDay === key ? "" : key;
        if (tasksDay === "")
            launcher.reset();
        else
            Qt.callLater(() => tasks.focusNow());
    }

    function toggleTimer() {
        tasksDay = "";
        timerShown = !timerShown;
        if (timerShown)
            Qt.callLater(() => timer.focusNow());
        else
            launcher.reset();
    }

    // The tasks keep their last day while fading out, so they are only told about a new one.
    onTasksDayChanged: if (tasksDay !== "")
        tasks.day = tasksDay

    onOpenChanged: shown = open
    onShownChanged: if (shown) {
        tasksDay = "";
        timerShown = false;
        launcher.reset();
    }
    Component.onCompleted: Qt.callLater(() => shown = open)

    screen: homeScreen
    visible: shown || show.progress > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Panels.keyboardMode(open)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Panels.close()
    }

    Column {
        id: stack

        readonly property int shift: Theme.layout.launcherShift

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + shift
        spacing: Theme.layout.panelGap

        opacity: show.fade
        transform: Translate {
            x: show.dx
            y: show.dy
        }

        PanelShow {
            id: show

            shown: overlay.shown
            from: Theme.layout.barEdge === "bottom" ? "bottom" : "top"
            distance: Theme.space.xxl * 2
        }

        TimePanel {
            running: overlay.visible
            width: Theme.layout.launcherWidth
            selectedDay: overlay.tasksDay
            timerOpen: overlay.timerShown
            onDayClicked: key => overlay.showDay(key)
            onClockClicked: overlay.toggleTimer()
        }

        // The launcher and the tasks share one place and cross-fade.
        Item {
            width: Theme.layout.launcherWidth
            height: Theme.layout.launcherHeight

            LauncherPanel {
                id: launcher

                anchors.fill: parent
                opacity: overlay.launcherShown ? 1 : 0
                visible: opacity > 0
                enabled: overlay.launcherShown

                Behavior on opacity {
                    Motion {
                        preset: Theme.motion.panel
                    }
                }
            }

            TasksPanel {
                id: tasks

                anchors.fill: parent
                opacity: overlay.tasksDay !== "" ? 1 : 0
                visible: opacity > 0
                enabled: overlay.tasksDay !== ""
                onBack: overlay.showDay(overlay.tasksDay)

                Behavior on opacity {
                    Motion {
                        preset: Theme.motion.panel
                    }
                }
            }

            TimerPanel {
                id: timer

                anchors.fill: parent
                opacity: overlay.timerShown ? 1 : 0
                visible: opacity > 0
                enabled: overlay.timerShown
                onBack: overlay.toggleTimer()

                Behavior on opacity {
                    Motion {
                        preset: Theme.motion.panel
                    }
                }
            }
        }
    }
}
