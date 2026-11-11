import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"

// One day's tasks, shown in the launcher's place when a day is clicked in the time panel. Add, edit, tick off and
// delete (two clicks); a task with a time can remind ahead of it (TaskStore sends the notification).
Rectangle {
    id: panel

    // The day, as TaskStore.dateKey gives it.
    property string day: ""
    // The task being edited: its id, "new", or "" while only the list shows.
    property var editing: ""
    property string timeError: ""
    property int remind: -1

    readonly property var dayTasks: {
        TaskStore.tasks;
        return day === "" ? [] : TaskStore.on(day);
    }

    signal back

    function focusNow() {
        if (editing === "")
            panel.forceActiveFocus();
        else
            titleField.focusNow();
    }

    function startNew() {
        editing = "new";
        titleField.text = "";
        timeField.text = "";
        remind = -1;
        timeError = "";
        titleField.focusNow();
    }

    function startEdit(task) {
        editing = task.id;
        titleField.text = task.title;
        timeField.text = task.time;
        remind = task.remind;
        timeError = "";
        titleField.focusNow();
    }

    function cancel() {
        editing = "";
        panel.forceActiveFocus();
    }

    // Time is optional, 24-hour; a reminder needs one.
    function save() {
        const title = titleField.text.trim();
        let time = timeField.text.trim();
        if (title === "")
            return titleField.focusNow();
        if (time !== "") {
            const m = time.match(/^(\d{1,2})[:.]?(\d{2})$/);
            if (!m || Number(m[1]) > 23 || Number(m[2]) > 59) {
                timeError = "Time is 24-hour, like 14:30";
                return timeField.focusNow();
            }
            time = m[1].padStart(2, "0") + ":" + m[2];
        }
        const fields = { title: title, time: time, remind: time === "" ? -1 : remind };
        if (editing === "new")
            TaskStore.add(Object.assign({ date: day }, fields));
        else
            TaskStore.update(editing, fields);
        cancel();
    }

    onDayChanged: editing = ""

    radius: Theme.shape.panelRadius
    color: Theme.colors.surface
    border.color: Theme.colors.border
    border.width: Theme.shape.borderWidth

    Keys.onEscapePressed: Panels.close()

    // Clicks inside must not reach the overlay, which closes it.
    MouseArea {
        anchors.fill: parent
        onClicked: panel.focusNow()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.layout.panelPadding
        spacing: Theme.space.ml

        // Back to the launcher, the day, and a new task.
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.s

            IconButton {
                glyph: "back"
                onClicked: panel.back()
            }

            Label {
                Layout.fillWidth: true
                text: panel.day === "" ? "" : Qt.formatDate(TaskStore.dateOf(panel.day), "dddd, d MMMM")
                color: Theme.colors.foregroundStrong
                font.family: Theme.fonts.familyTitle
                font.pixelSize: Theme.fonts.title
                font.weight: Theme.fonts.weight
            }

            IconButton {
                glyph: "plus"
                onClicked: panel.startNew()
            }
        }

        // Adding or editing.
        ColumnLayout {
            Layout.fillWidth: true
            visible: panel.editing !== ""
            spacing: Theme.space.s

            TextField {
                id: titleField

                placeholder: "Task"
                onAccepted: panel.save()
                onEscaped: panel.cancel()
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.s

                TextField {
                    id: timeField

                    Layout.fillWidth: false
                    Layout.preferredWidth: 110
                    placeholder: "Time, 14:30"
                    onAccepted: panel.save()
                    onEscaped: panel.cancel()
                    onTextChanged: panel.timeError = ""
                }

                // Reminder, before the time. Only with a time.
                Repeater {
                    model: TaskStore.remindChoices

                    InteractiveSurface {
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: Theme.control.small
                        restColor: Theme.colors.surfaceRaised
                        selected: panel.remind === modelData[0]
                        enabled: timeField.text.trim() !== ""
                        opacity: enabled ? 1 : 0.4
                        onClicked: panel.remind = modelData[0]

                        Label {
                            anchors.centerIn: parent
                            text: parent.modelData[1]
                            color: parent.contentColor
                        }
                    }
                }
            }

            Label {
                visible: panel.timeError !== ""
                text: panel.timeError
                color: Theme.colors.error
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.s

                ActionButton {
                    label: panel.editing === "new" ? "Add" : "Save"
                    selected: true
                    onActivated: panel.save()
                }

                ActionButton {
                    label: "Cancel"
                    onActivated: panel.cancel()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.colors.border
            }
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.space.xxs
            boundsBehavior: Flickable.StopAtBounds
            model: panel.dayTasks

            delegate: Rectangle {
                id: row

                required property var modelData

                width: ListView.view.width
                height: Theme.control.regular + Theme.space.xs
                radius: Theme.shape.controlRadius
                color: hover.hovered || panel.editing === modelData.id ? Theme.colors.surfaceRaised : Theme.colors.clear

                Behavior on color {
                    ColorMotion {
                        preset: Theme.motion.quick
                    }
                }

                HoverHandler {
                    id: hover
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.space.s
                    anchors.rightMargin: Theme.space.xs
                    spacing: Theme.space.m

                    // Done or not.
                    Rectangle {
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: Math.min(3, Theme.shape.innerRadius)
                        color: row.modelData.done ? Theme.colors.accent : Theme.colors.clear
                        border.width: 1
                        border.color: row.modelData.done ? Theme.colors.accent : Theme.colors.muted

                        Behavior on color {
                            ColorMotion {}
                        }

                        Part {
                            anchors.centerIn: parent
                            visible: row.modelData.done
                            slot: "powerGlyph"

                            readonly property string glyph: "check"
                            readonly property color tint: Theme.colors.onAccent
                            readonly property int iconSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: TaskStore.update(row.modelData.id, { done: !row.modelData.done })
                        }
                    }

                    Label {
                        visible: row.modelData.time !== ""
                        text: row.modelData.time
                        font.family: Theme.fonts.familyMono
                        color: Theme.colors.muted
                    }

                    Label {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: row.modelData.title
                        font.pixelSize: Theme.fonts.body
                        font.strikeout: row.modelData.done
                        color: row.modelData.done ? Theme.colors.muted : Theme.colors.foreground

                        Behavior on color {
                            ColorMotion {}
                        }
                    }

                    // With a reminder: how long before the time.
                    Label {
                        visible: row.modelData.remind >= 0 && row.modelData.time !== "" && !row.modelData.done
                        text: row.modelData.remind === 0 ? "at time" : (TaskStore.remindChoices.find(c => c[0] === row.modelData.remind)?.[1] ?? "") + " before"
                        color: row.modelData.reminded ? Theme.colors.inactive : Theme.colors.muted
                        font.pixelSize: Theme.fonts.caption
                    }

                    IconButton {
                        glyph: "pencil"
                        opacity: hover.hovered ? 1 : 0
                        onClicked: panel.startEdit(row.modelData)

                        Behavior on opacity {
                            Motion {
                                preset: Theme.motion.quick
                            }
                        }
                    }

                    IconButton {
                        id: trash

                        glyph: "trash"
                        opacity: hover.hovered || armed ? 1 : 0
                        onClicked: {
                            if (armed) {
                                armed = false;
                                TaskStore.remove(row.modelData.id);
                            } else {
                                armed = true;
                                disarm.restart();
                            }
                        }

                        Behavior on opacity {
                            Motion {
                                preset: Theme.motion.quick
                            }
                        }

                        Timer {
                            id: disarm

                            interval: Theme.motion.confirm
                            onTriggered: trash.armed = false
                        }
                    }
                }
            }

            Hint {
                anchors.centerIn: parent
                visible: list.count === 0 && panel.editing === ""
                text: "Nothing on this day. + adds a task."
            }
        }
    }
}
