import QtQuick
import ".."

// A bezier curve with two handles to drag. Time runs left to right and progress bottom to top; room above and
// below allows overshoot. Reports only when a handle is let go, so a drag does not rewrite the preset on every move.
Item {
    id: root

    property real x1: 0
    property real y1: 0
    property real x2: 1
    property real y2: 1
    readonly property real side: 220
    readonly property real overshoot: 0.5
    // Where the handles are during a drag; the inputs otherwise.
    property var drag: null
    readonly property var p: drag ?? [x1, y1, x2, y2]

    signal edited(real x1, real y1, real x2, real y2)

    function toX(v) {
        return v * side;
    }

    function toY(v) {
        return (1 + overshoot - v) * side / (1 + 2 * overshoot);
    }

    function fromX(px) {
        return Math.round(Math.max(0, Math.min(1, px / side)) * 100) / 100;
    }

    function fromY(py) {
        const v = 1 + overshoot - Math.max(0, Math.min(side, py)) * (1 + 2 * overshoot) / side;
        return Math.round(v * 100) / 100;
    }

    implicitWidth: side
    implicitHeight: side
    onPChanged: plot.requestPaint()

    Rectangle {
        anchors.fill: parent
        radius: Theme.shape.controlRadius
        color: Theme.colors.surfaceRaised
    }

    Canvas {
        id: plot

        readonly property var themeWatch: Theme.palette

        anchors.fill: parent
        onThemeWatchChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const line = (ax, ay, bx, by, color, w) => {
                ctx.strokeStyle = color;
                ctx.lineWidth = w;
                ctx.beginPath();
                ctx.moveTo(ax, ay);
                ctx.lineTo(bx, by);
                ctx.stroke();
            };
            const startY = root.toY(0);
            const endY = root.toY(1);
            line(0, startY, root.side, startY, Theme.colors.border, 1);
            line(0, endY, root.side, endY, Theme.colors.border, 1);
            const p = root.p;
            line(0, startY, root.toX(p[0]), root.toY(p[1]), Theme.colors.muted, 1);
            line(root.side, endY, root.toX(p[2]), root.toY(p[3]), Theme.colors.muted, 1);
            ctx.strokeStyle = Theme.colors.accent;
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.moveTo(0, startY);
            ctx.bezierCurveTo(root.toX(p[0]), root.toY(p[1]), root.toX(p[2]), root.toY(p[3]), root.side, endY);
            ctx.stroke();
        }
    }

    Repeater {
        model: 2

        Rectangle {
            id: handle

            required property int index

            x: root.toX(root.p[index * 2]) - width / 2
            y: root.toY(root.p[index * 2 + 1]) - height / 2
            width: 12
            height: 12
            radius: 6
            color: area.containsMouse || area.pressed ? Theme.colors.accent : Theme.colors.foregroundStrong
            border.color: Theme.colors.surface
            border.width: 2

            Behavior on color {
                ColorMotion {
                    preset: Theme.motion.quick
                }
            }

            MouseArea {
                id: area

                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                preventStealing: true

                function move(mouse) {
                    const at = mapToItem(root, mouse.x, mouse.y);
                    const next = root.p.slice();
                    next[handle.index * 2] = root.fromX(at.x);
                    next[handle.index * 2 + 1] = root.fromY(at.y);
                    root.drag = next;
                }

                onPressed: mouse => move(mouse)
                onPositionChanged: mouse => {
                    if (pressed)
                        move(mouse);
                }
                onReleased: {
                    const done = root.drag;
                    root.drag = null;
                    if (done)
                        root.edited(done[0], done[1], done[2], done[3]);
                }
            }
        }
    }
}
