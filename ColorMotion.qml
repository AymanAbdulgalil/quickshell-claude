import QtQuick

// A ColorAnimation driven by a theme preset. Use it for every state-driven color:
// Behavior on color { ColorMotion {} }
ColorAnimation {
    property var preset: Theme.motion.standard

    duration: preset.duration
    easing.type: preset.bezier?.length ? Easing.BezierSpline : preset.easing
    easing.bezierCurve: preset.bezier ?? []
}
