import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Qt.labs.folderlistmodel
import ".."
import "../controls"

// Notes: Super+I, slides in from the right at full height. Each tab is a file in ~/Notes, saved as you type.
// It does not close on outside clicks, so files can be dragged in from other windows.
PanelWindow {
    id: panel

    property var homeScreen
    readonly property bool open: Panels.notesOpen
    // Follows `open` a frame later, so it still fades in when built by opening.
    property bool shown: false
    property string view: "editor"   // "editor", "files", "help"
    property bool renaming: false

    readonly property string dir: Quickshell.env("HOME") + "/Notes"
    readonly property var tabs: Settings.notesTabs
    readonly property string current: Settings.notesCurrent

    onOpenChanged: shown = open
    Component.onCompleted: Qt.callLater(() => shown = open)
    onShownChanged: {
        if (shown) {
            if (tabs.length === 0)
                newNote();
            else
                file.reload();
            view = "editor";
            editor.focusNow();
        } else {
            saveNow();
        }
    }

    function saveNow() {
        autosave.stop();
        if (dirty && current !== "") {
            file.setText(editor.markdown());
            dirty = false;
        }
    }

    property bool dirty: false

    function openNote(name) {
        saveNow();
        if (!tabs.includes(name))
            Settings.notesTabs = tabs.concat([name]);
        Settings.notesCurrent = name;
        view = "editor";
        file.path = dir + "/" + name;
        file.reload();
        editor.focusNow();
    }

    function closeTab(name) {
        saveNow();
        const i = tabs.indexOf(name);
        const left = tabs.filter(t => t !== name);
        Settings.notesTabs = left;
        if (name !== current)
            return;
        if (left.length > 0) {
            Settings.notesCurrent = "";
            openNote(left[Math.min(i, left.length - 1)]);
        } else {
            Settings.notesCurrent = "";
            editor.setMarkdown("");
            view = "files";
        }
    }

    function goToTab(number) {
        if (number <= tabs.length)
            openNote(tabs[number - 1]);
    }

    function moveTab(by) {
        if (tabs.length > 1)
            openNote(tabs[(tabs.indexOf(current) + by + tabs.length) % tabs.length]);
    }

    function uniqueName() {
        const taken = name => tabs.includes(name) || files.indexOfName(name) >= 0;
        let n = 1;
        while (taken("Note " + n + ".md"))
            n++;
        return "Note " + n + ".md";
    }

    function newNote() {
        const name = uniqueName();
        ops.start(["sh", "-c", 'mkdir -p "$DIR" && : >> "$DIR/$NEW"'], { DIR: dir, NEW: name }, () => openNote(name));
    }

    function renameCurrent(typed) {
        renaming = false;
        const clean = typed.trim().replace(/\//g, "-");
        if (clean === "" || current === "")
            return;
        const name = /\.[A-Za-z0-9]+$/.test(clean) ? clean : clean + ".md";
        if (name === current)
            return;
        saveNow();
        const old = current;
        ops.start(["sh", "-c", '[ ! -e "$DIR/$NEW" ] && mv "$DIR/$OLD" "$DIR/$NEW"'], { DIR: dir, OLD: old, NEW: name }, () => {
            Settings.notesTabs = tabs.map(t => t === old ? name : t);
            Settings.notesCurrent = name;
            file.path = dir + "/" + name;
            editor.focusNow();
        });
    }

    // To the trash, so a mistake can be undone.
    function deleteCurrent() {
        const old = current;
        dirty = false;
        autosave.stop();
        ops.start(["gio", "trash", dir + "/" + old], {}, () => closeTab(old));
    }

    // Dropped at the cursor: images go into the note (copied beside the notes), any other file as its path.
    function dropped(urls) {
        const images = /\.(png|jpe?g|gif|webp|bmp|svg)$/i;
        const stamp = Date.now();
        const paths = urls.map(u => decodeURIComponent(String(u).replace(/^file:\/\//, "")));
        const list = paths.map((p, i) => ({ from: p, image: images.test(p), name: p.split("/").pop(), to: images.test(p) ? "images/" + stamp + "-" + i + "-" + p.split("/").pop().replace(/\s+/g, "-") : p.split("/").pop() }));
        const pics = list.filter(f => f.image);
        const others = list.filter(f => !f.image).map(f => f.from).join("\n");
        if (others !== "")
            editor.insertPlain(others);
        if (pics.length === 0)
            return;
        const script = 'mkdir -p "$DIR/images"\nwhile IFS= read -r from && IFS= read -r to; do cp -n -- "$from" "$DIR/$to"; done';
        const input = pics.map(f => f.from + "\n" + f.to).join("\n") + "\n";
        ops.start(["sh", "-c", script], { DIR: dir }, () => {
            for (const f of pics)
                editor.insertImage(dir + "/" + f.to);
        }, input);
    }

    // One file operation at a time.
    Process {
        id: ops

        property var after: null
        property string input: ""

        function start(command, env, done, text) {
            after = done;
            input = text ?? "";
            ops.command = command;
            ops.environment = env;
            ops.stdinEnabled = input !== "";
            ops.running = true;
        }

        onStarted: if (input !== "") {
            write(input);
            stdinEnabled = false;
        }
        onExited: code => {
            if (code === 0 && after)
                after();
            after = null;
        }
    }

    FileView {
        id: file

        path: panel.current !== "" ? panel.dir + "/" + panel.current : ""
        blockWrites: true
        printErrors: false
        onLoaded: {
            editor.setMarkdown(text());
            panel.dirty = false;
        }
    }

    Timer {
        id: autosave

        interval: 400
        onTriggered: panel.saveNow()
    }

    FolderListModel {
        id: files

        folder: "file://" + panel.dir
        nameFilters: ["*.md", "*.txt"]
        showDirs: false
        sortField: FolderListModel.Time

        function indexOfName(name) {
            return indexOf("file://" + panel.dir + "/" + name);
        }
    }

    screen: homeScreen
    visible: shown || card.opacity > 0
    implicitWidth: Theme.layout.notesWidth + Theme.layout.barMargin
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        right: Theme.layout.barEdge !== "right"
        left: Theme.layout.barEdge === "right"
    }

    margins.top: Theme.layout.barEdge === "top" ? Theme.layout.barClearance : Theme.layout.barMargin
    margins.bottom: Theme.layout.barEdge === "bottom" ? Theme.layout.barClearance : 0
    margins.left: Theme.layout.barEdge === "right" ? Theme.layout.barMargin : 0
    margins.right: Theme.layout.barEdge === "right" ? Theme.layout.barClearance : 0

    Rectangle {
        id: card

        width: Theme.layout.notesWidth
        height: parent.height - (Theme.layout.barEdge === "bottom" ? 0 : Theme.layout.barMargin)
        radius: Theme.shape.panelRadius
        color: Theme.colors.surface
        border.color: Theme.colors.border
        border.width: Theme.shape.borderWidth

        opacity: panel.shown ? 1 : 0

        Behavior on opacity {
            Motion {
                preset: Theme.motion.panel
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.layout.panelPadding
            spacing: Theme.space.m

            // --- Tabs, then the buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.xs

                ListView {
                    id: tabList

                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    orientation: ListView.Horizontal
                    model: panel.tabs
                    spacing: Theme.space.xxs
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    WheelHandler {
                        onWheel: event => {
                            const most = Math.max(0, tabList.contentWidth - tabList.width);
                            tabList.contentX = Math.max(0, Math.min(most, tabList.contentX - event.angleDelta.y));
                        }
                    }

                    delegate: Rectangle {
                        id: tab

                        required property string modelData

                        readonly property bool isCurrent: modelData === panel.current

                        width: Math.min(170, tabName.implicitWidth + 40)
                        height: 30
                        radius: Theme.shape.controlRadius
                        color: isCurrent ? Theme.colors.surfaceHover : tabHover.hovered ? Theme.colors.surfaceRaised : Theme.colors.clear

                        Behavior on color {
                            ColorMotion {
                                preset: Theme.motion.quick
                            }
                        }

                        HoverHandler {
                            id: tabHover
                        }

                        // Dragging a tab out drops the note's file.
                        DragHandler {
                            id: tabDrag

                            target: null
                        }

                        Item {
                            Drag.active: tabDrag.active
                            Drag.dragType: Drag.Automatic
                            Drag.supportedActions: Qt.CopyAction
                            Drag.mimeData: ({ "text/uri-list": encodeURI("file://" + panel.dir + "/" + tab.modelData) })
                        }

                        TapHandler {
                            onTapped: panel.openNote(tab.modelData)
                        }

                        Label {
                            id: tabName

                            anchors.left: parent.left
                            anchors.leftMargin: Theme.space.ml
                            anchors.right: closeTab.left
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: tab.modelData.replace(/\.md$/, "")
                            color: tab.isCurrent ? Theme.colors.foregroundStrong : Theme.colors.muted
                        }

                        IconButton {
                            id: closeTab

                            anchors.right: parent.right
                            anchors.rightMargin: 3
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 20
                            implicitHeight: 20
                            glyph: "close"
                            onClicked: panel.closeTab(tab.modelData)
                        }
                    }
                }

                IconButton {
                    glyph: "plus"
                    onClicked: panel.newNote()
                }

                IconButton {
                    glyph: "folder"
                    onClicked: panel.view = panel.view === "files" ? "editor" : "files"
                }

                IconButton {
                    glyph: "pencil"
                    enabled: panel.current !== ""
                    onClicked: {
                        renameField.text = panel.current.replace(/\.md$/, "");
                        panel.renaming = true;
                        renameField.focusNow();
                    }
                }

                IconButton {
                    id: deleteButton

                    property bool armed: false

                    glyph: armed ? "check" : "trash"
                    enabled: panel.current !== ""
                    onClicked: {
                        if (armed) {
                            armed = false;
                            panel.deleteCurrent();
                        } else {
                            armed = true;
                            disarm.restart();
                        }
                    }

                    Timer {
                        id: disarm

                        interval: Theme.motion.confirm
                        onTriggered: deleteButton.armed = false
                    }
                }

                IconButton {
                    glyph: "help"
                    onClicked: panel.view = panel.view === "help" ? "editor" : "help"
                }
            }

            // Markdown styling. Each has a key too; the list is under the help button.
            RowLayout {
                Layout.fillWidth: true
                visible: panel.view === "editor" && panel.current !== ""
                spacing: Theme.space.xxs

                // In a table the row holds the table's own actions, at the same height.
                Repeater {
                    model: editor.inTable ? [["addRow", "+ Row"], ["addColumn", "+ Column"], ["deleteRow", "\u2212 Row"], ["deleteColumn", "\u2212 Column"]] : []

                    InteractiveSurface {
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: Theme.control.small
                        restColor: Theme.colors.clear
                        onClicked: editor.tableAction(modelData[0])

                        Label {
                            anchors.centerIn: parent
                            text: parent.modelData[1]
                        }
                    }
                }

                Repeater {
                    model: editor.inTable ? [] : [["bold", "B"], ["italic", "I"], ["strike", "S"], ["code", "`"], ["h1", "H1"], ["h2", "H2"], ["h3", "H3"], ["list", "-"], ["numbered", "1."], ["task", "[ ]"], ["quote", ">"], ["link", ""], ["table", ""]]

                    InteractiveSurface {
                        id: styleButton

                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: Theme.control.small
                        restColor: Theme.colors.clear
                        onClicked: editor.style(modelData[0])

                        Label {
                            anchors.centerIn: parent
                            visible: styleButton.modelData[1] !== ""
                            text: styleButton.modelData[1]
                            font.family: Theme.fonts.familyMono
                            font.bold: styleButton.modelData[0] === "bold"
                            font.italic: styleButton.modelData[0] === "italic"
                            font.strikeout: styleButton.modelData[0] === "strike"
                        }

                        Part {
                            anchors.centerIn: parent
                            visible: styleButton.modelData[1] === ""
                            slot: "powerGlyph"

                            readonly property string glyph: styleButton.modelData[0]
                            readonly property color tint: Theme.colors.foreground
                            readonly property int iconSize: 14
                        }
                    }
                }
            }

            TextField {
                id: renameField

                visible: panel.renaming
                placeholder: "New name"
                onAccepted: panel.renameCurrent(text)
                onEscaped: {
                    panel.renaming = false;
                    editor.focusNow();
                }
            }

            // --- The note, on its own sheet so it stands apart from the bars above it.
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.shape.controlRadius
                color: Theme.colors.surfaceRaised
                border.color: Theme.colors.border
                border.width: Theme.shape.borderWidth

                NoteEditor {
                    id: editor

                    anchors.fill: parent
                    anchors.margins: Theme.space.s
                    visible: panel.view === "editor" && panel.current !== ""
                    notesDir: panel.dir
                    onEdited: {
                        panel.dirty = true;
                        autosave.restart();
                    }
                    onCloseRequested: Panels.notesOpen = false
                    onCycleTabs: panel.moveTab(1)
                    panelKey: event => {
                        if ((event.modifiers & Qt.AltModifier) && !(event.modifiers & Qt.ControlModifier) && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                            panel.goToTab(event.key - Qt.Key_0);
                            return true;
                        }
                        if (!(event.modifiers & Qt.ControlModifier))
                            return false;
                        const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
                        if (event.key === Qt.Key_N && !shift)
                            panel.newNote();
                        else if (event.key === Qt.Key_W)
                            panel.closeTab(panel.current);
                        else if (event.key === Qt.Key_Tab)
                            panel.moveTab(1);
                        else if (event.key === Qt.Key_Backtab)
                            panel.moveTab(-1);
                        else if (event.key === Qt.Key_S)
                            panel.saveNow();
                        else if (event.key === Qt.Key_O)
                            panel.view = "files";
                        else
                            return false;
                        return true;
                    }
                }

                DropArea {
                    anchors.fill: editor
                    onDropped: drop => {
                        editor.placeCursorAt(drop.x, drop.y);
                        if (drop.hasUrls)
                            panel.dropped(drop.urls);
                        else if (drop.hasText)
                            editor.insertPlain(drop.text);
                        drop.accept(Qt.CopyAction);
                    }
                }

                // --- All notes
                ListView {
                    anchors.fill: parent
                    visible: panel.view === "files" || panel.current === "" && panel.view !== "help"
                    model: files
                    clip: true
                    spacing: Theme.space.xxs

                    delegate: Rectangle {
                        required property string fileName

                        width: ListView.view.width
                        height: 34
                        radius: Theme.shape.controlRadius
                        color: rowHover.hovered ? Theme.colors.surfaceRaised : Theme.colors.clear

                        Behavior on color {
                            ColorMotion {
                                preset: Theme.motion.quick
                            }
                        }

                        HoverHandler {
                            id: rowHover
                        }

                        TapHandler {
                            onTapped: panel.openNote(parent.fileName)
                        }

                        Label {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.space.ml
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            text: parent.fileName
                            color: Theme.colors.foreground
                        }
                    }
                }

                // --- Shortcuts
                Flickable {
                    anchors.fill: parent
                    visible: panel.view === "help"
                    clip: true
                    contentHeight: helpColumn.implicitHeight

                    Column {
                        id: helpColumn

                        width: parent.width
                        spacing: 3

                        Repeater {
                            model: [
                                ["Style", ""],
                                ["Ctrl+B  I", "bold, italic"],
                                ["Ctrl+Shift+X", "strikethrough"],
                                ["Ctrl+`", "code"],
                                ["Ctrl+1  2  3", "heading level"],
                                ["Ctrl+Shift+L  N", "list, numbered list"],
                                ["Ctrl+Shift+Q", "quote"],
                                ["Ctrl+K  T", "link, table"],
                                ["Tables", ""],
                                ["Tab, Shift+Tab", "next column (adds one at the end), previous"],
                                ["Enter, Shift+Enter", "next row (adds one at the end), previous row"],
                                ["Ctrl+Alt+R  C", "add a row, a column after this one"],
                                ["Ctrl+Alt+Shift+R  C", "delete this row, column"],
                                ["Lines", ""],
                                ["Enter", "continues a list at the same indent; on an empty item, ends it"],
                                ["Ctrl+Enter", "new line under this one"],
                                ["Alt+Z", "wrap or unwrap lines"],
                                ["Tab", "four spaces, or indents selected lines"],
                                ["Alt+Left  Right", "outdent, indent line or selection"],
                                ["Alt+Up  Down", "move line or selection"],
                                ["Ctrl+L", "select the whole line"],
                                ["Ctrl+Shift+Up  Down", "add a cursor above, below; Esc or a click removes them"],
                                ["Notes", ""],
                                ["Ctrl+N  O  W", "new, open, close the tab"],
                                ["Ctrl+Tab, Shift+Tab", "next tab"],
                                ["Alt+1 to 9", "go to that tab"],
                                ["Ctrl+click", "open a link"],
                                ["Ctrl+S", "save (notes also save as you type)"],
                                ["Ctrl+V", "paste, images too"],
                                ["Esc", "close the panel"],
                                ["Drag", ""],
                                ["Into the note", "images are shown; any other file adds its path"],
                                ["Out of the note", "drag selected text, an image or a tab to any app"]
                            ]

                            Row {
                                required property var modelData

                                spacing: Theme.space.l

                                Label {
                                    width: modelData[1] === "" ? helpColumn.width : 130
                                    text: modelData[0]
                                    color: modelData[1] === "" ? Theme.colors.accent : Theme.colors.foregroundStrong
                                    topPadding: modelData[1] === "" ? 8 : 0
                                }

                                Label {
                                    visible: modelData[1] !== ""
                                    width: helpColumn.width - 142
                                    wrapMode: Text.WordWrap
                                    text: modelData[1]
                                    color: Theme.colors.muted
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
