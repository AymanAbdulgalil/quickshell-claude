import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../controls"

BarPanel {
    id: panel

    name: "clipboard"
    placement: "center"
    cardWidth: Theme.layout.clipboardWidth
    keyboardWhenOpen: WlrKeyboardFocus.Exclusive


    readonly property string query: search.text.toLowerCase()
    // Pinned first, then newest. Searching only looks at text.
    readonly property var results: {
        const q = query;
        const found = ClipboardState.entries.filter(e => q === "" || (e.text ?? "").toLowerCase().includes(q));
        return found.filter(e => e.pinned).concat(found.filter(e => !e.pinned));
    }
    property string qrContent: ""

    function copyAndClose(entry) {
        if (!entry)
            return;
        ClipboardState.copy(entry);
        Panels.close();
    }

    onPanelOpened: {
        search.text = "";
        qrContent = "";
        list.currentIndex = 0;
        search.focusNow();
    }
    onQueryChanged: list.currentIndex = 0


    RowLayout {
        Layout.fillWidth: true

        Label {
            Layout.fillWidth: true
            text: "Clipboard"
        font.family: Theme.fonts.familyTitle
            color: Theme.colors.foregroundStrong
            font.pixelSize: Theme.fonts.body
            font.weight: Theme.fonts.weight
        }

        ActionButton {
            Layout.fillWidth: false
            Layout.preferredWidth: 80
            visible: ClipboardState.entries.some(e => !e.pinned)
            label: "Clear"
            confirm: true
            onActivated: ClipboardState.clear()
        }
    }

    Label {
        Layout.fillWidth: true
        visible: !ClipboardState.persistInstalled
        wrapMode: Text.WordWrap
        text: "Copies still vanish when their window closes. To fix that: sudo pacman -S wl-clip-persist"
        color: Theme.colors.warning
    }

    TextField {
        id: search

        placeholder: "Search"
        onAccepted: panel.copyAndClose(panel.results[list.currentIndex])
        onNavigate: by => list.currentIndex = Math.max(0, Math.min(list.count - 1, list.currentIndex + by))
        onEscaped: Panels.close()
    }

    QrCode {
        visible: panel.qrContent !== ""
        content: panel.qrContent
        caption: panel.qrContent
        onClosed: panel.qrContent = ""
    }

    Label {
        Layout.fillWidth: true
        Layout.margins: Theme.space.m
        visible: panel.results.length === 0
        text: panel.query === "" ? "Nothing copied yet." : "No matches."
        color: Theme.colors.muted
    }

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, Theme.layout.listMaxHeight)
        visible: panel.results.length > 0
        model: panel.results
        clip: true
        spacing: Theme.space.xxs
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 0

        delegate: ClipboardRow {
            required property var modelData
            required property int index

            width: ListView.view.width
            entry: modelData
            selected: ListView.isCurrentItem
            onCopied: panel.copyAndClose(modelData)
            onShowQr: panel.qrContent = modelData.text.trim()
        }
    }
}
