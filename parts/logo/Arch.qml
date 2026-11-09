import QtQuick
import "../.."

// The Arch Linux logo. Inputs: tint, iconSize
Canvas {
    readonly property color tint: parent.tint

    implicitWidth: Math.ceil((parent.iconSize - 2) * 24 / 22.79)
    implicitHeight: parent.iconSize
    onTintChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        // The drawing spans 22.79 of its 24 units, from y 0.605; it is fitted exactly like the status icons.
        const unit = Theme.iconUnit(height) * 14 / 22.79;
        ctx.translate(0, height / 2);
        ctx.scale(unit, unit);
        ctx.translate(0, -12);
        ctx.fillStyle = tint;
        ctx.path = "M11.39.605C10.376 3.092 9.764 4.72 8.635 7.132c.693.734 1.543 1.589 2.923 2.554-1.484-.61-2.496-1.224-3.252-1.86C6.86 10.842 4.596 15.138 0 23.395c3.612-2.085 6.412-3.37 9.021-3.862a6.61 6.61 0 0 1-.171-1.547l.003-.115c.058-2.315 1.261-4.095 2.687-3.973 1.426.12 2.534 2.096 2.478 4.409a6.52 6.52 0 0 1-.146 1.243c2.58.505 5.352 1.787 8.914 3.844-.702-1.293-1.33-2.459-1.929-3.57-.943-.73-1.926-1.682-3.933-2.713 1.38.359 2.367.772 3.137 1.234-6.09-11.334-6.582-12.84-8.67-17.74z";
        ctx.fill();
    }
}
