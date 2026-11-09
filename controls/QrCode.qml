import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

// Shows text as a QR code. The text goes through a pipe, never a command line.
Rectangle {
    id: root

    property string content: ""
    property string caption: ""
    // One string per row, "1" for a dark module.
    property var modules: []

    signal closed

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight + 16
    radius: Theme.shape.controlRadius
    color: Theme.colors.surfaceRaised

    // The text is set here, not by a binding: this handler can run before a binding on `environment` has updated,
    // and the encoder then got no text, leaving a blank white square.
    onContentChanged: {
        modules = [];
        if (content === "")
            return;
        encoder.running = false;
        encoder.environment = { QR_TEXT: content };
        encoder.running = true;
    }

    // qrencode's text output: "##" is a dark module.
    Process {
        id: encoder

        command: ["sh", "-c", 'printf %s "$QR_TEXT" | qrencode -t ASCII -m 0']

        stdout: StdioCollector {
            onStreamFinished: root.modules = text.split("\n").filter(l => l.length > 0).map(l => {
                let row = "";
                for (let i = 0; i < l.length; i += 2)
                    row += l[i] === "#" ? "1" : "0";
                return row;
            })
        }
    }

    ColumnLayout {
        id: column

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.space.m
        spacing: Theme.space.s

        // QR codes scan best dark on white, whatever the theme.
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 196
            implicitHeight: 196
            color: "white"
            radius: 4

            // Drawn in whole pixels per module, so it stays sharp.
            Canvas {
                id: grid

                readonly property int count: root.modules.length
                readonly property int cell: count > 0 ? Math.floor((parent.width - 16) / count) : 1

                anchors.centerIn: parent
                width: count * cell
                height: count * cell
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    // Dark on white, whatever the theme, so scanners read it.
                    ctx.fillStyle = "black";
                    for (let y = 0; y < count; y++) {
                        const row = root.modules[y];
                        for (let x = 0; x < row.length; x++) {
                            if (row[x] === "1")
                                ctx.fillRect(x * cell, y * cell, cell, cell);
                        }
                    }
                }
                onCountChanged: requestPaint()
                onCellChanged: requestPaint()

                Connections {
                    target: root

                    function onModulesChanged() {
                        grid.requestPaint();
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: root.caption !== ""
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideMiddle
            text: root.caption
            color: Theme.colors.muted
        }

        ActionButton {
            label: "Close"
            onActivated: root.closed()
        }
    }
}
