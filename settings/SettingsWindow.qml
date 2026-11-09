import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../controls"

// The Settings app: centred, with a grouped sidebar. Appearance is saved per preset; Hyprland and System are saved once.
PanelWindow {
    id: window

    property var homeScreen
    readonly property bool open: Panels.name === "settings" && Panels.screen === homeScreen
    // Follows `open` a frame later, so it still fades in when built by opening.
    property bool shown: false

    readonly property var groups: [
        { title: "Appearance  ·  " + ThemePresets.active.name, tabs: [["themes", "Themes", "ThemesPage"], ["shell", "Bar and panels", "ShellPage"], ["windows", "Windows", "WindowsPage"], ["animations", "Animations", "AnimationsPage"]] },
        { title: "Hyprland", tabs: [["monitors", "Monitors", "MonitorsPage"], ["input", "Input", "InputPage"], ["keybinds", "Keybinds", "KeybindsPage"], ["rules", "Window rules", "RulesPage"], ["startup", "Startup", "StartupPage"], ["options", "All options", "OptionsPage"]] },
        { title: "System", tabs: [["display", "Display", "DisplayPage"], ["power", "Power", "PowerPage"], ["network", "Network", "NetworkPage"], ["bluetooth", "Bluetooth", "BluetoothPage"], ["notifications", "Notifications", "NotificationsPage"], ["general", "General", "GeneralPage"]] }
    ]
    readonly property var allTabs: groups.reduce((all, g) => all.concat(g.tabs), [])
    readonly property var currentTab: allTabs.find(t => t[0] === Panels.settingsTab) ?? allTabs[0]

    function moveTab(by) {
        const i = allTabs.indexOf(currentTab);
        Panels.settingsTab = allTabs[(i + by + allTabs.length) % allTabs.length][0];
    }

    onOpenChanged: shown = open
    onShownChanged: {
        Panels.activeDropdown = null;
        if (shown)
            card.forceActiveFocus();
    }
    Component.onCompleted: Qt.callLater(() => shown = open)

    screen: homeScreen
    visible: shown || card.opacity > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // A click outside the card closes it.
    MouseArea {
        anchors.fill: parent
        onClicked: Panels.close()
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Theme.layout.settingsWidth
        height: Theme.layout.settingsHeight
        radius: Theme.shape.panelRadius
        color: Theme.colors.surface
        border.color: Theme.colors.border
        border.width: Theme.shape.borderWidth
        focus: true

        Keys.onEscapePressed: Panels.close()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ControlModifier) || event.key === Qt.Key_Backtab) {
                window.moveTab(event.key === Qt.Key_Backtab ? -1 : 1);
                event.accepted = true;
            }
        }

        opacity: window.shown ? 1 : 0

        Behavior on opacity {
            Motion {
                preset: Theme.motion.panel
            }
        }

        // Clicks inside must not reach the area that closes the window.
        MouseArea {
            anchors.fill: parent
            onClicked: card.forceActiveFocus()
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.shape.borderWidth
            spacing: 0

            // --- Sidebar
            Flickable {
                Layout.fillHeight: true
                Layout.preferredWidth: Theme.layout.settingsSidebar
                contentHeight: sidebar.implicitHeight + 2 * Theme.space.l
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                ColumnLayout {
                    id: sidebar

                    x: Theme.space.l
                    y: Theme.space.l
                    width: parent.width - 2 * Theme.space.l
                    spacing: Theme.space.xxs

                    Repeater {
                        model: window.groups

                        ColumnLayout {
                            id: group

                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.topMargin: index === 0 ? 0 : Theme.space.l
                            spacing: Theme.space.xxs

                            Label {
                                Layout.leftMargin: Theme.space.m
                                Layout.bottomMargin: Theme.space.xs
                                text: group.modelData.title
                                color: Theme.colors.muted
                                font.weight: Theme.fonts.weight
                            }

                            Repeater {
                                model: group.modelData.tabs

                                SideTab {
                                    required property var modelData

                                    label: modelData[1]
                                    selected: window.currentTab[0] === modelData[0]
                                    onClicked: {
                                        Panels.settingsTab = modelData[0];
                                        card.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 1
                color: Theme.colors.border
            }

            // --- The page
            Flickable {
                id: flick

                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: page.height + 2 * Theme.space.xxl
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Loader {
                    id: page

                    x: Theme.space.xxl
                    y: Theme.space.xxl
                    width: flick.width - 2 * Theme.space.xxl
                    height: item ? item.implicitHeight : 0
                    source: Qt.resolvedUrl(window.currentTab[2] + ".qml")
                    onSourceChanged: {
                        Panels.activeDropdown = null;
                        flick.contentY = 0;
                    }
                }
            }
        }
    }

    // The open Dropdown's list, over everything else in the window. A click anywhere else closes it.
    Loader {
        id: dropdownLayer

        anchors.fill: parent
        active: Panels.activeDropdown !== null

        sourceComponent: Item {
            id: layer

            MouseArea {
                anchors.fill: parent
                onPressed: Panels.activeDropdown = null
                onWheel: Panels.activeDropdown = null
            }

            DropdownList {
                id: list

                options: Panels.activeDropdown?.options ?? []
                value: Panels.activeDropdown?.value
                height: implicitHeight
                onPicked: v => {
                    const owner = Panels.activeDropdown;
                    Panels.activeDropdown = null;
                    owner?.picked(v);
                }
                // Placed once on opening: nothing behind the layer can scroll while it is up.
                Component.onCompleted: {
                    const owner = Panels.activeDropdown;
                    width = owner.width;
                    const at = owner.mapToItem(layer, 0, owner.height + Theme.space.xxs);
                    x = at.x;
                    y = at.y + implicitHeight > window.height - Theme.space.m ? at.y - owner.height - 2 * Theme.space.xxs - implicitHeight : at.y;
                }
            }
        }
    }
}
