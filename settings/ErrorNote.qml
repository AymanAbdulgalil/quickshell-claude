import QtQuick
import QtQuick.Layouts
import ".."

// What Hyprland said was wrong. Nothing was replaced when this shows.
Label {
    Layout.fillWidth: true
    visible: text !== ""
    wrapMode: Text.WrapAnywhere
    color: Theme.colors.error
}
