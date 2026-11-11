import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"

// The stopwatch and the timers, shown in the launcher's place when the time panel's clock is clicked (2026-11-11).
// Stopwatch: start and stop as often as needed, snapshots (laps) while it runs, and a history of earlier sessions.
// Timers: a length or a time of day, picked with steppers; each rings with a notification. TimerStore keeps both.
Rectangle {
    id: panel

    // "stopwatch" or "timers"; kept while the launcher is closed.
    property string view: "stopwatch"
    // The timer picker: "in" a length or "at" a time of day, each in minutes (a time of day from midnight).
    property string mode: "in"
    property int inMinutes: 10
    property int atMinutes: 0
    readonly property int picked: mode === "in" ? inMinutes : atMinutes
    // Now, for what is on screen. Ticks only while shown: for the stopwatch only while it runs; the timers' countdowns and the
    // picker's "rings at" always.
    property real now: Date.now()
    readonly property bool counting: view === "stopwatch" ? TimerStore.running : true

    readonly property real elapsed: {
        TimerStore.runs;
        return TimerStore.elapsed(now);
    }

    signal back

    function focusNow() {
        now = Date.now();
        panel.forceActiveFocus();
    }

    // Moves the pick by minutes, round the clock (a length stays under 24 hours).
    function nudge(by) {
        const next = ((picked + by) % 1440 + 1440) % 1440;
        if (mode === "in")
            inMinutes = next;
        else
            atMinutes = next;
    }

    // A time of day to start "At" from: ten minutes on, rounded up to five.
    function soon() {
        const d = new Date(Date.now() + 10 * 60000);
        return Math.ceil((d.getHours() * 60 + d.getMinutes()) / 5) * 5 % 1440;
    }

    // From now to the picked time of day, the next one to come.
    function untilAt() {
        const at = new Date(now);
        at.setHours(Math.floor(atMinutes / 60), atMinutes % 60, 0, 0);
        if (at.getTime() <= now)
            at.setDate(at.getDate() + 1);
        return Math.ceil((at.getTime() - now) / 60000) * 60000;
    }

    function addPicked() {
        if (mode === "in") {
            if (inMinutes <= 0)
                return;
            TimerStore.addLength(inMinutes * 60000, labelField.text);
        } else {
            TimerStore.addAt(atMinutes, labelField.text);
        }
        labelField.text = "";
        panel.forceActiveFocus();
    }

    // The stopwatch's list: this session's snapshots, newest first, then earlier sessions.
    readonly property var stopwatchRows: {
        const rows = [];
        const snaps = TimerStore.snapshots;
        for (let i = snaps.length - 1; i >= 0; i--) {
            const laps = snaps.slice(0, i + 1).filter(s => s.kind === "lap").length;
            rows.push({ type: "snap", kind: snaps[i].kind, number: laps, elapsed: snaps[i].elapsed, delta: snaps[i].elapsed - (i > 0 ? snaps[i - 1].elapsed : 0), at: snaps[i].at });
        }
        if (TimerStore.history.length > 0) {
            rows.push({ type: "head" });
            for (const h of TimerStore.history)
                rows.push({ type: "history", started: h.started, total: h.total, count: h.snapshots.filter(s => s.kind === "lap").length });
        }
        return rows;
    }

    // Waiting timers by when they ring, then those that rang, latest first.
    readonly property var timerRows: {
        const waiting = TimerStore.timers.filter(t => !t.rang).sort((a, b) => a.at - b.at);
        const rang = TimerStore.timers.filter(t => t.rang).sort((a, b) => b.at - a.at);
        return waiting.concat(rang);
    }

    onViewChanged: Qt.callLater(focusNow)

    radius: Theme.shape.panelRadius
    color: Theme.colors.surface
    border.color: Theme.colors.border
    border.width: Theme.shape.borderWidth

    Keys.onEscapePressed: Panels.close()
    Keys.onSpacePressed: if (view === "stopwatch")
        TimerStore.startStop()
    Keys.onPressed: event => {
        if (view !== "timers")
            return;
        const steps = { [Qt.Key_Up]: 1, [Qt.Key_Down]: -1, [Qt.Key_PageUp]: 60, [Qt.Key_PageDown]: -60 };
        if (event.key in steps) {
            nudge(steps[event.key]);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            addPicked();
            event.accepted = true;
        }
    }

    Timer {
        interval: panel.view === "stopwatch" ? 100 : 1000
        repeat: true
        running: panel.visible && panel.counting
        triggeredOnStart: true
        onTriggered: panel.now = Date.now()
    }

    // Clicks inside must not reach the overlay, which closes it.
    MouseArea {
        anchors.fill: parent
        onClicked: panel.focusNow()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.layout.panelPadding
        spacing: Theme.space.ml

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.s

            IconButton {
                glyph: "back"
                onClicked: panel.back()
            }

            Tabs {
                options: [["stopwatch", "Stopwatch"], ["timers", "Timers"]]
                value: panel.view
                onPicked: v => panel.view = v
            }
        }

        // --- Stopwatch

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: panel.view === "stopwatch"
            spacing: Theme.space.ml

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Theme.space.xs
                text: TimerStore.stopwatchText(panel.elapsed)
                color: TimerStore.running ? Theme.colors.foregroundStrong : Theme.colors.foreground
                font.family: Theme.fonts.familyMono
                font.pixelSize: Theme.fonts.display
                font.weight: Theme.fonts.weight

                Behavior on color {
                    ColorMotion {}
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.s

                ActionButton {
                    label: TimerStore.running ? "Stop" : panel.elapsed > 0 ? "Resume" : "Start"
                    selected: true
                    onActivated: TimerStore.startStop()
                }

                ActionButton {
                    label: "Lap"
                    enabled: TimerStore.running
                    opacity: enabled ? 1 : 0.4
                    onActivated: TimerStore.lap()
                }

                ActionButton {
                    label: "Reset"
                    enabled: TimerStore.runs.length > 0
                    opacity: enabled ? 1 : 0.4
                    onActivated: TimerStore.reset()
                }
            }

            ListView {
                id: stopwatchList

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Theme.space.xxs
                boundsBehavior: Flickable.StopAtBounds
                model: panel.stopwatchRows

                delegate: Item {
                    id: srow

                    required property var modelData

                    width: ListView.view.width
                    height: modelData.type === "head" ? Theme.control.regular + Theme.space.s : Theme.control.small

                    // History heading, with a way to clear it.
                    RowLayout {
                        anchors.fill: parent
                        anchors.topMargin: Theme.space.s
                        visible: srow.modelData.type === "head"
                        spacing: Theme.space.s

                        Label {
                            Layout.fillWidth: true
                            text: "History"
                            color: Theme.colors.muted
                            font.weight: Theme.fonts.weight
                        }

                        ActionButton {
                            Layout.fillWidth: false
                            Layout.preferredWidth: implicitWidth
                            implicitHeight: Theme.control.small
                            label: "Clear"
                            confirm: true
                            onActivated: TimerStore.clearHistory()
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.space.s
                        anchors.rightMargin: Theme.space.s
                        visible: srow.modelData.type !== "head"
                        spacing: Theme.space.l

                        Label {
                            Layout.preferredWidth: 64
                            text: srow.modelData.type === "history" ? Qt.formatDateTime(new Date(srow.modelData.started), "ddd HH:mm") : srow.modelData.kind === "lap" ? "Lap " + srow.modelData.number : "Stop"
                            color: srow.modelData.kind === "stop" ? Theme.colors.muted : Theme.colors.foreground
                        }

                        Label {
                            Layout.preferredWidth: 96
                            text: TimerStore.stopwatchText(srow.modelData.type === "history" ? srow.modelData.total : srow.modelData.elapsed)
                            color: Theme.colors.foregroundStrong
                            font.family: Theme.fonts.familyMono
                        }

                        Label {
                            Layout.fillWidth: true
                            text: srow.modelData.type === "history" ? (srow.modelData.count > 0 ? srow.modelData.count + (srow.modelData.count === 1 ? " lap" : " laps") : "") : "+" + TimerStore.stopwatchText(srow.modelData.delta)
                            color: Theme.colors.muted
                            font.family: srow.modelData.type === "history" ? Theme.fonts.family : Theme.fonts.familyMono
                        }

                        Label {
                            visible: srow.modelData.type === "snap"
                            text: srow.modelData.at ? TimerStore.clockText(srow.modelData.at) : ""
                            color: Theme.colors.muted
                        }
                    }
                }

                Hint {
                    anchors.centerIn: parent
                    visible: stopwatchList.count === 0
                    text: "Space starts and stops. Lap keeps a time while it runs."
                }
            }
        }

        // --- Timers
        // Picked, not typed (2026-11-11): "In" a length, or "At" a time of day (24-hour). Hours and minutes step with their
        // buttons, the wheel, Up and Down (minutes) or Page Up and Page Down (hours); Enter adds.

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: panel.view === "timers"
            spacing: Theme.space.s

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.l

                Row {
                    spacing: Theme.space.xs

                    TimeWheel {
                        text: TimerStore.twoDigits(Math.floor(panel.picked / 60))
                        onStep: by => panel.nudge(by * 60)
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ":"
                        color: Theme.colors.muted
                        font.family: Theme.fonts.familyMono
                        font.pixelSize: Theme.fonts.display
                    }

                    TimeWheel {
                        text: TimerStore.twoDigits(panel.picked % 60)
                        onStep: by => panel.nudge(by)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space.s

                    Tabs {
                        options: [["in", "In"], ["at", "At"]]
                        value: panel.mode
                        onPicked: v => {
                            panel.mode = v;
                            if (v === "at")
                                panel.atMinutes = panel.soon();
                            panel.focusNow();
                        }
                    }

                    TextField {
                        id: labelField

                        placeholder: "Label"
                        onAccepted: panel.addPicked()
                        onEscaped: Panels.close()
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space.s

                        // What the pick means in the other terms: when a length rings, or how long until a time.
                        Label {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: panel.mode === "in" ? (panel.picked > 0 ? "Rings at " + TimerStore.clockText(panel.now + panel.picked * 60000) : "Pick a length") : "In " + (TimerStore.lengthText(panel.untilAt()) || "a moment")
                            color: Theme.colors.muted
                        }

                        ActionButton {
                            Layout.fillWidth: false
                            Layout.preferredWidth: implicitWidth
                            label: "Add"
                            selected: true
                            enabled: panel.mode === "at" || panel.picked > 0
                            opacity: enabled ? 1 : 0.4
                            onActivated: panel.addPicked()
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.s

                Repeater {
                    model: TimerStore.quickLengths

                    InteractiveSurface {
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: Theme.control.small
                        onClicked: TimerStore.addLength(modelData[1], labelField.text)

                        Label {
                            anchors.centerIn: parent
                            text: parent.modelData[0]
                            color: parent.contentColor
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space.xs
                implicitHeight: 1
                color: Theme.colors.border
            }

            ListView {
                id: timerList

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Theme.space.xxs
                boundsBehavior: Flickable.StopAtBounds
                model: panel.timerRows

                delegate: Rectangle {
                    id: trow

                    required property var modelData

                    width: ListView.view.width
                    height: Theme.control.regular + Theme.space.xs
                    radius: Theme.shape.controlRadius
                    color: thover.hovered ? Theme.colors.surfaceRaised : Theme.colors.clear

                    Behavior on color {
                        ColorMotion {
                            preset: Theme.motion.quick
                        }
                    }

                    HoverHandler {
                        id: thover
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.space.s
                        anchors.rightMargin: Theme.space.xs
                        spacing: Theme.space.m

                        // Time left, or that it rang.
                        Label {
                            Layout.preferredWidth: 72
                            text: trow.modelData.rang ? "Rang" : TimerStore.remainingText(trow.modelData.at - panel.now)
                            color: trow.modelData.rang ? Theme.colors.muted : Theme.colors.foregroundStrong
                            font.family: Theme.fonts.familyMono
                            font.pixelSize: Theme.fonts.body
                        }

                        Label {
                            text: "at " + TimerStore.clockText(trow.modelData.at)
                            color: Theme.colors.muted
                        }

                        Label {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: trow.modelData.label !== "" ? trow.modelData.label : trow.modelData.kind === "duration" ? TimerStore.lengthText(trow.modelData.length) : "Alarm"
                            color: trow.modelData.rang ? Theme.colors.muted : Theme.colors.foreground
                        }

                        IconButton {
                            visible: trow.modelData.rang
                            glyph: "reboot"
                            onClicked: TimerStore.again(trow.modelData.id)
                        }

                        IconButton {
                            id: ttrash

                            glyph: "trash"
                            opacity: thover.hovered || armed ? 1 : 0
                            onClicked: {
                                if (armed) {
                                    armed = false;
                                    TimerStore.remove(trow.modelData.id);
                                } else {
                                    armed = true;
                                    tdisarm.restart();
                                }
                            }

                            Behavior on opacity {
                                Motion {
                                    preset: Theme.motion.quick
                                }
                            }

                            Timer {
                                id: tdisarm

                                interval: Theme.motion.confirm
                                onTriggered: ttrash.armed = false
                            }
                        }
                    }
                }

                Hint {
                    anchors.centerIn: parent
                    visible: timerList.count === 0
                    text: "Each timer rings with a notification."
                }
            }
        }
    }
}
