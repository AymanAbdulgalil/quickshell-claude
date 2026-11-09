import QtQuick

// Spacing steps, scaled by the preset's density. The bar's own spacing is in Layout and does not scale.
QtObject {
    property real density: 1
    readonly property int xxs: 2
    readonly property int xs: 4
    readonly property int s: Math.round(6 * density)
    readonly property int m: Math.round(8 * density)
    readonly property int ml: Math.round(10 * density)
    readonly property int l: Math.round(12 * density)
    readonly property int xl: Math.round(16 * density)
    readonly property int xxl: Math.round(24 * density)
}
