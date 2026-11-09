import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import ".."
import "../controls"

ColumnLayout {
    id: page

    property string expanded
    property bool picking: false

    signal toggled(string id)

    // Latest used first.
    readonly property var vpns: NetworkState.saved.filter(c => c.vpn).sort((a, b) => b.lastUsed - a.lastUsed)
    readonly property string home: Quickshell.env("HOME")

    Layout.fillWidth: true
    spacing: Theme.space.xs

    Label {
        Layout.fillWidth: true
        visible: !NetworkState.openvpnAvailable
        wrapMode: Text.WordWrap
        text: "WireGuard works. For OpenVPN files, install support: sudo pacman -S networkmanager-openvpn"
        color: Theme.colors.warning
    }

    Label {
        Layout.fillWidth: true
        Layout.margins: Theme.space.m
        visible: page.vpns.length === 0 && !page.picking
        text: "No VPNs yet. Add an .ovpn or .conf file."
        color: Theme.colors.muted
    }

    // --- Set-up connections
    Repeater {
        model: page.vpns

        ColumnLayout {
            id: row

            required property var modelData

            readonly property bool open: page.expanded === modelData.uuid

            Layout.fillWidth: true
            spacing: Theme.space.s

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Theme.control.row
                radius: Theme.shape.controlRadius
                color: vpnArea.containsMouse || row.open ? Theme.colors.surfaceRaised : Theme.colors.clear

                Behavior on color {
                    ColorMotion {
                        preset: Theme.motion.quick
                    }
                }

                MouseArea {
                    id: vpnArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.toggled(row.modelData.uuid)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.space.m
                    anchors.rightMargin: Theme.space.m
                    spacing: Theme.space.ml

                    Column {
                        Layout.fillWidth: true

                        Label {
                            width: parent.width
                            elide: Text.ElideRight
                            text: row.modelData.name
                            color: Theme.colors.foregroundStrong
                            font.pixelSize: Theme.fonts.body
                        }

                        Label {
                            width: parent.width
                            text: row.modelData.typeLabel + (row.modelData.active ? ", connected" : "")
                            color: Theme.colors.muted
                        }
                    }

                    SettingSwitch {
                        checked: row.modelData.active
                        onToggled: on => on ? NetworkState.bringUp(row.modelData.uuid) : NetworkState.bringDown(row.modelData.uuid)
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.space.m
                Layout.rightMargin: Theme.space.m
                Layout.bottomMargin: Theme.space.s
                visible: row.open
                spacing: Theme.space.s

                SavedControls {
                    connection: row.modelData
                }

                // OpenVPN servers often need an account; WireGuard never does.
                TextField {
                    id: user

                    visible: row.modelData.type === "vpn"
                    placeholder: "Username, if needed"
                }

                TextField {
                    id: pass

                    visible: row.modelData.type === "vpn"
                    placeholder: "Password, if needed"
                    secret: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space.s

                    ActionButton {
                        visible: row.modelData.type === "vpn"
                        label: "Save login"
                        enabled: pass.text !== ""
                        onActivated: {
                            NetworkState.setVpnLogin(row.modelData.uuid, user.text, pass.text);
                            pass.text = "";
                        }
                    }

                    ActionButton {
                        label: "Remove"
                        confirm: true
                        onActivated: NetworkState.forget(row.modelData.uuid)
                    }
                }
            }
        }
    }

    ActionButton {
        Layout.topMargin: Theme.space.s
        visible: !page.picking
        label: "Add from file"
        onActivated: page.picking = true
    }

    // --- Files already copied to the VPN folder. They stay there when the original is deleted.
    // Latest used first: a file is touched when imported and whenever its VPN connects.
    SettingSection {
        visible: !page.picking && recent.count > 0
        text: "Imported files"
    }
    Repeater {
        model: FolderListModel {
            id: recent

            folder: "file://" + NetworkState.vpnDir
            nameFilters: ["*.ovpn", "*.conf"]
            showDirs: false
            showHidden: false
            sortField: FolderListModel.Time
        }

        FileRow {
            required property string fileName
            required property string filePath

            visible: !page.picking
            glyph: "file"
            label: fileName
            editable: true
            onClicked: NetworkState.importVpn(filePath)
            onRenamed: name => NetworkState.renameVpnFile(filePath, name)
            onRemoved: NetworkState.deleteVpnFile(filePath)
        }
    }

    // --- Choosing a new file
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Theme.space.s
        visible: page.picking
        spacing: Theme.space.xxs

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.s

            IconButton {
                glyph: "back"
                enabled: browser.parentFolder.toString() !== ""
                onClicked: browser.folder = browser.parentFolder
            }

            Label {
                Layout.fillWidth: true
                elide: Text.ElideLeft
                text: browser.folder.toString().replace("file://", "").replace(page.home, "~")
                color: Theme.colors.muted
            }

            ActionButton {
                Layout.fillWidth: false
                Layout.preferredWidth: 64
                label: "Cancel"
                onActivated: page.picking = false
            }
        }

        Repeater {
            model: FolderListModel {
                id: browser

                folder: "file://" + page.home + "/Downloads"
                nameFilters: ["*.ovpn", "*.conf"]
                showDirsFirst: true
                showHidden: false
            }

            FileRow {
                required property string fileName
                required property string filePath
                required property bool fileIsDir

                glyph: fileIsDir ? "folder" : "file"
                label: fileName
                onClicked: {
                    if (fileIsDir) {
                        browser.folder = "file://" + filePath;
                    } else {
                        NetworkState.importVpn(filePath);
                        page.picking = false;
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            Layout.margins: Theme.space.m
            visible: browser.count === 0
            text: "No .ovpn or .conf files here."
            color: Theme.colors.muted
        }
    }
}
