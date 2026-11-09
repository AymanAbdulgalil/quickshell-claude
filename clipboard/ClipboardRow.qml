import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"

// One copy. Click copies it again; the buttons show on hover or when selected.
Rectangle {
    id: row

    property var entry
    property bool selected: false

    signal copied
    signal showQr

    readonly property bool isLink: ClipboardState.isLink(entry)
    readonly property bool active: selected || hover.hovered

    function age(seconds) {
        const d = Date.now() / 1000 - seconds;
        if (d < 60)
            return "now";
        if (d < 3600)
            return Math.floor(d / 60) + " min";
        if (d < 86400)
            return Math.floor(d / 3600) + " h";
        return Math.floor(d / 86400) + " d";
    }

    implicitHeight: entry.kind === "image" ? 94 : Math.max(44, body.implicitHeight + 14)
    radius: Theme.shape.controlRadius
    color: selected ? Theme.colors.surfaceHover : hover.hovered ? Theme.colors.surfaceRaised : Theme.colors.clear

    Behavior on color {
        ColorMotion {
            preset: Theme.motion.quick
        }
    }

    // Passive: a MouseArea lost the hover to the buttons, which then hid themselves and flickered.
    HoverHandler {
        id: hover
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.copied()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.space.m
        anchors.rightMargin: Theme.space.s
        spacing: Theme.space.m

        Image {
            Layout.preferredWidth: 130
            Layout.preferredHeight: 80
            visible: row.entry.kind === "image"
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            sourceSize.width: 260
            sourceSize.height: 160
            source: row.entry.kind === "image" ? ClipboardState.fileUrl(row.entry) : ""
        }

        Column {
            id: body

            Layout.fillWidth: true
            spacing: Theme.space.xxs

            Label {
                width: parent.width
                visible: row.entry.kind === "text"
                text: row.entry.text ?? ""
                textFormat: Text.PlainText
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 3
                elide: Text.ElideRight
                color: row.isLink ? Theme.colors.accent : Theme.colors.foreground
            }

            Label {
                width: parent.width
                text: (row.entry.kind === "image" ? "Image, " + Math.ceil(row.entry.size / 1024) + " KB, " : "") + row.age(row.entry.time)
                color: Theme.colors.muted
                font.pixelSize: Theme.fonts.caption
            }
        }

        // Always takes its space, so rows do not reflow under the cursor.
        Row {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: Theme.space.xs
            spacing: 0
            opacity: row.active || row.entry.pinned ? 1 : 0

            IconButton {
                visible: row.isLink
                glyph: "qr"
                onClicked: row.showQr()
            }

            IconButton {
                glyph: row.entry.pinned ? "pinned" : "pin"
                onClicked: ClipboardState.togglePin(row.entry)
            }

            IconButton {
                glyph: "close"
                onClicked: ClipboardState.remove(row.entry)
            }
        }
    }
}
