import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"

// A file or folder in a list. With `editable`, rename and delete buttons show on hover; delete takes two clicks.
Rectangle {
    id: root

    property string glyph
    property string label
    property bool editable: false
    property bool renaming: false
    property bool armed: false

    signal clicked
    signal renamed(string name)
    signal removed

    readonly property string stem: label.replace(/\.[^.]*$/, "")

    Layout.fillWidth: true
    implicitHeight: 30
    radius: Theme.shape.controlRadius
    color: hover.hovered || renaming ? Theme.colors.surfaceRaised : Theme.colors.clear

    Behavior on color {
        ColorMotion {
            preset: Theme.motion.quick
        }
    }

    // Passive, so it still counts as hovering while the pointer is over the buttons.
    HoverHandler {
        id: hover
    }

    Timer {
        id: disarm

        interval: Theme.motion.confirm
        onTriggered: root.armed = false
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (!root.renaming)
            root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.space.m
        anchors.rightMargin: Theme.space.xs
        spacing: Theme.space.m

        Part {
            slot: "powerGlyph"

            readonly property string glyph: root.glyph
            readonly property color tint: Theme.colors.foreground
            readonly property int iconSize: 14
        }

        Label {
            Layout.fillWidth: true
            visible: !root.renaming
            elide: Text.ElideMiddle
            text: root.armed ? "Delete " + root.label + "?" : root.label
            color: root.armed ? Theme.colors.error : Theme.colors.foreground

            Behavior on color {
                ColorMotion {
                    preset: Theme.motion.quick
                }
            }
        }

        TextField {
            id: nameField

            visible: root.renaming
            implicitHeight: 24
            placeholder: "New name"
            onAccepted: {
                root.renaming = false;
                if (text.trim() !== "" && text.trim() !== root.stem)
                    root.renamed(text.trim());
            }
            onEscaped: root.renaming = false
        }

        IconButton {
            visible: root.editable && !root.renaming && (hover.hovered || root.armed)
            implicitWidth: 22
            implicitHeight: 22
            glyph: "pencil"
            onClicked: {
                root.armed = false;
                nameField.text = root.stem;
                root.renaming = true;
                nameField.focusNow();
            }
        }

        IconButton {
            visible: root.editable && !root.renaming && (hover.hovered || root.armed)
            implicitWidth: 22
            implicitHeight: 22
            glyph: "trash"
            onClicked: {
                if (root.armed) {
                    root.armed = false;
                    root.removed();
                } else {
                    root.armed = true;
                    disarm.restart();
                }
            }
        }
    }
}
