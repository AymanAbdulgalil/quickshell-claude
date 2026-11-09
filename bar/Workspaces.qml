import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".."

Grid {
    id: root

    property var screen

    columns: Theme.layout.barVertical ? 1 : 64

    readonly property var liveIds: Hyprland.workspaces.values.map(w => w.id).filter(id => id > 0)
    readonly property int activeId: Hyprland.monitorFor(screen)?.activeWorkspace?.id ?? 0
    readonly property int lastId: Math.max(1, activeId, ...liveIds)

    Repeater {
        model: root.lastId

        Item {
            id: cell

            required property int index

            readonly property int wsId: index + 1

            width: Theme.layout.barVertical ? Theme.layout.barHeight : 22
            height: Theme.layout.barVertical ? 22 : Theme.layout.barHeight

            Part {
                slot: "workspaceMarker"
                anchors.centerIn: parent

                readonly property bool current: cell.wsId === root.activeId
                readonly property bool occupied: root.liveIds.includes(cell.wsId)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                // This Hyprland uses the Lua config: dispatch takes Lua, not "workspace N".
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + cell.wsId + " })")
            }
        }
    }
}
