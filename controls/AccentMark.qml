import QtQuick
import ".."
import "../parts/accent/shapes.js" as Shapes

// One accent element (Theme.icons.mark unless `kind` says otherwise), `size` across, filled with `color`.
Canvas {
    property string kind: Theme.icons.mark
    property color color: Theme.colors.accent
    property real size: 6

    implicitWidth: Math.ceil(size * 1.3) + 2
    implicitHeight: implicitWidth
    onKindChanged: requestPaint()
    onColorChanged: requestPaint()
    onSizeChanged: requestPaint()
    onWidthChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        Shapes.fill(ctx, kind, width / 2, height / 2, size / 2, color);
    }
}
