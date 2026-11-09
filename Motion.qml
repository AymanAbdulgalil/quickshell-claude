import QtQuick

// A NumberAnimation driven by a theme preset (Theme.motion.quick, .standard, .panel).
NumberAnimation {
    property var preset: Theme.motion.standard

    duration: preset.duration
    easing.type: preset.easing
}
