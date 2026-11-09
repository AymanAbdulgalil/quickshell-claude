import QtQuick

// Heights of controls, scaled by the preset's density.
QtObject {
    property real density: 1
    readonly property int small: Math.round(24 * density)
    readonly property int regular: Math.round(28 * density)
    readonly property int iconButton: Math.round(26 * density)
    readonly property int settingRow: Math.round(30 * density)
    readonly property int row: Math.round(40 * density)
}
