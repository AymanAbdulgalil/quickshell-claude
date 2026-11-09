import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../controls"

Rectangle {
    id: panel

    // "apps" or "commands"
    property string column: "apps"

    readonly property string raw: input.text.trim()
    // A leading ! runs in the terminal.
    readonly property bool terminal: raw.startsWith("!")
    readonly property string line: (terminal ? raw.slice(1) : raw).trim()
    readonly property string firstWord: line.split(/\s+/)[0]
    readonly property string rest: line.slice(firstWord.length).trim()

    // App names can have spaces; if the whole line matches none, treat the rest as arguments.
    readonly property var appsFull: LauncherState.searchApps(line)
    readonly property bool appsUseArgs: appsFull.length === 0 && rest !== ""
    readonly property var appResults: appsUseArgs ? LauncherState.searchApps(firstWord) : appsFull
    readonly property var binResults: LauncherState.searchBinaries(firstWord)

    function reset() {
        input.text = "";
        column = "apps";
        appList.currentIndex = 0;
        binList.currentIndex = 0;
        input.forceActiveFocus();
    }

    function move(by) {
        const list = column === "apps" ? appList : binList;
        if (list.count > 0)
            list.currentIndex = Math.max(0, Math.min(list.count - 1, list.currentIndex + by));
    }

    function launch() {
        const useApps = (column === "apps" && appResults.length > 0) || (binResults.length === 0 && appResults.length > 0);
        if (useApps)
            LauncherState.runApp(appResults[appList.currentIndex] ?? appResults[0], appsUseArgs ? rest : "", terminal);
        else if (binResults.length > 0)
            LauncherState.runCommand((binResults[binList.currentIndex] ?? binResults[0]) + (rest ? " " + rest : ""), terminal);
        else if (line !== "")
            LauncherState.runCommand(line, terminal);
        else
            return;
        Panels.close();
    }

    onAppResultsChanged: appList.currentIndex = 0
    onBinResultsChanged: binList.currentIndex = 0

    radius: Theme.shape.panelRadius
    color: Theme.colors.surface
    border.color: Theme.colors.border
    border.width: Theme.shape.borderWidth

    // Clicks inside must not reach the overlay, which closes it.
    MouseArea {
        anchors.fill: parent
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.layout.panelPadding
        spacing: Theme.space.ml

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.s

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: Theme.shape.controlRadius
                color: Theme.colors.surfaceRaised

                TextInput {
                    id: input

                    anchors.fill: parent
                    anchors.leftMargin: Theme.space.ml
                    anchors.rightMargin: Theme.space.ml
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    color: Theme.colors.foregroundStrong
                    selectionColor: Theme.colors.accent
                    selectedTextColor: Theme.colors.onAccent
                    font.family: Theme.fonts.family
                    font.pixelSize: Theme.fonts.body
                    focus: true

                    Keys.onEscapePressed: Panels.close()
                    Keys.onUpPressed: panel.move(-1)
                    Keys.onDownPressed: panel.move(1)
                    Keys.onLeftPressed: panel.column = "apps"
                    Keys.onRightPressed: panel.column = "commands"
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_PageDown) {
                            panel.move(8);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageUp) {
                            panel.move(-8);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            panel.launch();
                            event.accepted = true;
                        }
                    }
                }

                Label {
                    anchors.fill: input
                    verticalAlignment: Text.AlignVCenter
                    visible: input.text.length === 0
                    text: "Search, or ! for terminal"
                    color: Theme.colors.muted
                    font.pixelSize: Theme.fonts.body
                }
            }

        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.space.m

            LauncherList {
                id: appList

                active: panel.column === "apps"
                model: panel.appResults
                isApps: true
                onPicked: index => {
                    panel.column = "apps";
                    currentIndex = index;
                    panel.launch();
                }
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 1
                color: Theme.colors.border
            }

            LauncherList {
                id: binList

                active: panel.column === "commands"
                model: panel.binResults
                onPicked: index => {
                    panel.column = "commands";
                    currentIndex = index;
                    panel.launch();
                }
            }
        }
    }
}
