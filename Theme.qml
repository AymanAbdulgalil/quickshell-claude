pragma Singleton
import QtQuick
import Quickshell
import "themes"
import "themes/palettes.js" as Palettes

// What every widget reads. The active theme preset (ThemePresets) decides it.
Singleton {
    id: root

    readonly property var palettes: Palettes.list
    readonly property var roles: Palettes.roles
    readonly property var preset: ThemePresets.active
    readonly property var palette: ThemePresets.paletteOf(preset)

    readonly property RuntimeTheme active: RuntimeTheme {
        palette: root.palette
        preset: root.preset
    }

    readonly property var colors: active.colors
    readonly property var fonts: active.fonts
    readonly property var shape: active.shape
    readonly property var layout: active.layout
    readonly property var space: active.space
    readonly property var control: active.control
    readonly property var motion: active.motion
    readonly property var parts: active.parts

    // Units per pixel for an icon on a 16-unit grid, whose drawing is 14 units tall. A bar icon gets 0.7 px more, because
    // the soft rows at the edges of a curve look shorter than the solid rows of a digit of the same height.
    function iconUnit(canvasHeight) {
        return (canvasHeight - 2 + (canvasHeight === layout.barIconSize ? 0.7 : 0)) / 14;
    }
}
