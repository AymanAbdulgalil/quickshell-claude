import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell.Widgets
import ".."

// The wallpapers in Settings.wallpaperDir as thumbnails; the selected one has an accent ring. Used for the desktop and
// for the login screen.
GridView {
    id: root

    property string selected
    signal picked(string path)

    Layout.fillWidth: true
    Layout.preferredHeight: 190
    clip: true
    cellWidth: width / 5
    cellHeight: cellWidth * 0.62
    boundsBehavior: Flickable.StopAtBounds
    cacheBuffer: 200

    model: FolderListModel {
        folder: "file://" + Settings.wallpaperDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
    }

    delegate: Item {
        id: tile

        required property string filePath

        width: GridView.view.cellWidth
        height: GridView.view.cellHeight

        ClippingRectangle {
            id: thumb

            anchors.fill: parent
            anchors.margins: 3
            radius: Math.max(0, Theme.shape.controlRadius - 2)
            color: Theme.colors.surfaceRaised

            Image {
                anchors.fill: parent
                asynchronous: true
                sourceSize.width: 160
                fillMode: Image.PreserveAspectCrop
                source: "file://" + tile.filePath
            }
        }

        Rectangle {
            anchors.fill: thumb
            radius: thumb.radius
            color: "transparent"
            visible: root.selected === tile.filePath
            border.width: 2
            border.color: Theme.colors.accent
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.picked(tile.filePath)
        }
    }
}
