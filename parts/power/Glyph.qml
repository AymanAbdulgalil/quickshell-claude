import QtQuick
import "../.."

// Inputs: glyph, tint, optionally iconSize. Glyphs are drawn on an 18 by 18 grid.
Canvas {
    id: root

    readonly property string glyph: parent.glyph
    readonly property color tint: parent.tint

    implicitWidth: parent.iconSize ?? 18
    implicitHeight: parent.iconSize ?? 18
    onGlyphChanged: requestPaint()
    onTintChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.scale(width / 18, height / 18);
        ctx.strokeStyle = tint;
        ctx.fillStyle = tint;
        ctx.lineWidth = 1.5;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.beginPath();

        switch (glyph) {
        case "night":
            ctx.arc(9, 9, 6.5, Math.PI * 0.2, Math.PI * 1.45);
            ctx.quadraticCurveTo(6.5, 8, 14.2, 12.8);
            break;
        case "stayOn":
            ctx.moveTo(1.5, 9);
            ctx.quadraticCurveTo(9, 1.5, 16.5, 9);
            ctx.quadraticCurveTo(9, 16.5, 1.5, 9);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(9, 9, 2.2, 0, Math.PI * 2);
            ctx.fill();
            return;
        case "lock":
            ctx.moveTo(3.5, 8.5);
            ctx.lineTo(14.5, 8.5);
            ctx.lineTo(14.5, 16);
            ctx.lineTo(3.5, 16);
            ctx.closePath();
            ctx.moveTo(6, 8.5);
            ctx.lineTo(6, 5.5);
            ctx.arc(9, 5.5, 3, Math.PI, 0);
            ctx.lineTo(12, 8.5);
            break;
        case "sleep":
            ctx.moveTo(3, 7);
            ctx.lineTo(9, 7);
            ctx.lineTo(3, 14);
            ctx.lineTo(9, 14);
            ctx.moveTo(11, 2.5);
            ctx.lineTo(15.5, 2.5);
            ctx.lineTo(11, 7.5);
            ctx.lineTo(15.5, 7.5);
            break;
        case "hibernate":
            for (let i = 0; i < 3; i++) {
                const a = Math.PI * i / 3 + Math.PI / 2;
                const c = Math.cos(a);
                const s = Math.sin(a);
                ctx.moveTo(9 - 7.5 * c, 9 - 7.5 * s);
                ctx.lineTo(9 + 7.5 * c, 9 + 7.5 * s);
                for (const dir of [-1, 1]) {
                    const px = -s * dir * 2.2;
                    const py = c * dir * 2.2;
                    ctx.moveTo(9 + 5.2 * c + px, 9 + 5.2 * s + py);
                    ctx.lineTo(9 + 3.2 * c, 9 + 3.2 * s);
                    ctx.moveTo(9 - 5.2 * c + px, 9 - 5.2 * s + py);
                    ctx.lineTo(9 - 3.2 * c, 9 - 3.2 * s);
                }
            }
            break;
        case "logout":
            ctx.moveTo(8, 2.5);
            ctx.lineTo(3, 2.5);
            ctx.lineTo(3, 15.5);
            ctx.lineTo(8, 15.5);
            ctx.moveTo(7.5, 9);
            ctx.lineTo(16, 9);
            ctx.moveTo(12.5, 5.5);
            ctx.lineTo(16, 9);
            ctx.lineTo(12.5, 12.5);
            break;
        case "reboot":
            ctx.arc(9, 9.5, 6.5, -Math.PI * 0.35, Math.PI * 1.35);
            ctx.moveTo(11.8, 1.5);
            ctx.lineTo(12.2, 3.9);
            ctx.lineTo(14.8, 3.2);
            break;
        case "qr":
            ctx.moveTo(3, 3);
            ctx.lineTo(7, 3);
            ctx.lineTo(7, 7);
            ctx.lineTo(3, 7);
            ctx.closePath();
            ctx.moveTo(11, 3);
            ctx.lineTo(15, 3);
            ctx.lineTo(15, 7);
            ctx.lineTo(11, 7);
            ctx.closePath();
            ctx.moveTo(3, 11);
            ctx.lineTo(7, 11);
            ctx.lineTo(7, 15);
            ctx.lineTo(3, 15);
            ctx.closePath();
            ctx.moveTo(11, 11);
            ctx.lineTo(11, 15);
            ctx.moveTo(15, 11);
            ctx.lineTo(15, 15);
            ctx.moveTo(11, 13);
            ctx.lineTo(15, 13);
            break;
        case "pin":
        case "pinned":
            ctx.moveTo(6.5, 2.5);
            ctx.lineTo(11.5, 2.5);
            ctx.lineTo(11, 7.5);
            ctx.lineTo(13, 10.5);
            ctx.lineTo(5, 10.5);
            ctx.lineTo(7, 7.5);
            ctx.closePath();
            if (glyph === "pinned")
                ctx.fill();
            ctx.moveTo(9, 10.5);
            ctx.lineTo(9, 15.5);
            break;
        case "close":
            ctx.moveTo(5, 5);
            ctx.lineTo(13, 13);
            ctx.moveTo(13, 5);
            ctx.lineTo(5, 13);
            break;
        case "forward":
            ctx.moveTo(7, 4);
            ctx.lineTo(12, 9);
            ctx.lineTo(7, 14);
            break;
        case "folder":
            ctx.moveTo(2, 14.5);
            ctx.lineTo(2, 4);
            ctx.lineTo(7, 4);
            ctx.lineTo(9, 6);
            ctx.lineTo(16, 6);
            ctx.lineTo(16, 14.5);
            ctx.closePath();
            break;
        case "file":
            ctx.moveTo(4, 2);
            ctx.lineTo(11, 2);
            ctx.lineTo(14, 5.5);
            ctx.lineTo(14, 16);
            ctx.lineTo(4, 16);
            ctx.closePath();
            break;
        case "pencil":
            ctx.moveTo(3.5, 14.5);
            ctx.lineTo(4.2, 11.4);
            ctx.lineTo(11.8, 3.8);
            ctx.lineTo(14.2, 6.2);
            ctx.lineTo(6.6, 13.8);
            ctx.closePath();
            ctx.moveTo(10.2, 5.4);
            ctx.lineTo(12.6, 7.8);
            break;
        case "trash":
            ctx.moveTo(3, 5);
            ctx.lineTo(15, 5);
            ctx.moveTo(7, 5);
            ctx.lineTo(7, 3);
            ctx.lineTo(11, 3);
            ctx.lineTo(11, 5);
            ctx.moveTo(4.5, 5);
            ctx.lineTo(5.3, 15.5);
            ctx.lineTo(12.7, 15.5);
            ctx.lineTo(13.5, 5);
            ctx.moveTo(7.6, 8);
            ctx.lineTo(7.8, 12.5);
            ctx.moveTo(10.4, 8);
            ctx.lineTo(10.2, 12.5);
            break;
        case "link":
            ctx.arc(6, 11.5, 3.2, Math.PI * 0.25, Math.PI * 1.25);
            ctx.moveTo(8.3, 13.8);
            ctx.lineTo(4, 9.2);
            ctx.moveTo(12, 6.5);
            ctx.arc(12, 6.5, 3.2, -Math.PI * 0.75, Math.PI * 0.25);
            ctx.moveTo(6.8, 11.2);
            ctx.lineTo(11.2, 6.8);
            break;
        case "table":
            ctx.moveTo(2.5, 3.5);
            ctx.lineTo(15.5, 3.5);
            ctx.lineTo(15.5, 14.5);
            ctx.lineTo(2.5, 14.5);
            ctx.closePath();
            ctx.moveTo(2.5, 7.5);
            ctx.lineTo(15.5, 7.5);
            ctx.moveTo(2.5, 11);
            ctx.lineTo(15.5, 11);
            ctx.moveTo(9, 3.5);
            ctx.lineTo(9, 14.5);
            break;
        case "temperature":
            ctx.arc(9, 13, 3, Math.PI * 1.7, Math.PI * 1.3);
            ctx.moveTo(7.2, 10.6);
            ctx.lineTo(7.2, 4);
            ctx.arc(9, 4, 1.8, Math.PI, 0);
            ctx.lineTo(10.8, 10.6);
            ctx.moveTo(9, 7);
            ctx.lineTo(9, 13);
            break;
        case "plus":
            ctx.moveTo(9, 3.5);
            ctx.lineTo(9, 14.5);
            ctx.moveTo(3.5, 9);
            ctx.lineTo(14.5, 9);
            break;
        case "help":
            ctx.arc(9, 6.2, 3.4, Math.PI * 1.05, Math.PI * 0.35);
            ctx.lineTo(9, 11.2);
            ctx.moveTo(9, 14.6);
            ctx.lineTo(9, 14.7);
            break;
        case "check":
            ctx.moveTo(4, 9.5);
            ctx.lineTo(7.5, 13);
            ctx.lineTo(14, 5);
            break;
        case "chevron":
            ctx.moveTo(4.5, 7);
            ctx.lineTo(9, 11.5);
            ctx.lineTo(13.5, 7);
            break;
        case "phone":
            ctx.moveTo(6, 2);
            ctx.lineTo(12, 2);
            ctx.lineTo(12, 16);
            ctx.lineTo(6, 16);
            ctx.closePath();
            ctx.moveTo(8.5, 13.5);
            ctx.lineTo(9.5, 13.5);
            break;
        case "computer":
            ctx.moveTo(3, 3.5);
            ctx.lineTo(15, 3.5);
            ctx.lineTo(15, 11.5);
            ctx.lineTo(3, 11.5);
            ctx.closePath();
            ctx.moveTo(1.5, 14.5);
            ctx.lineTo(16.5, 14.5);
            break;
        case "headset":
            ctx.arc(9, 9.5, 6, Math.PI, 0);
            ctx.moveTo(3, 9.5);
            ctx.lineTo(3, 14);
            ctx.lineTo(5.5, 14);
            ctx.lineTo(5.5, 10);
            ctx.lineTo(3, 10);
            ctx.moveTo(15, 9.5);
            ctx.lineTo(15, 14);
            ctx.lineTo(12.5, 14);
            ctx.lineTo(12.5, 10);
            ctx.lineTo(15, 10);
            break;
        case "mouse":
            ctx.moveTo(5, 7);
            ctx.arc(9, 7, 4, Math.PI, 0);
            ctx.lineTo(13, 11.5);
            ctx.arc(9, 11.5, 4, 0, Math.PI);
            ctx.closePath();
            ctx.moveTo(9, 3);
            ctx.lineTo(9, 7);
            break;
        case "keyboard":
            ctx.moveTo(2, 5);
            ctx.lineTo(16, 5);
            ctx.lineTo(16, 13);
            ctx.lineTo(2, 13);
            ctx.closePath();
            ctx.moveTo(5, 8);
            ctx.lineTo(13, 8);
            ctx.moveTo(6, 10.5);
            ctx.lineTo(12, 10.5);
            break;
        case "device":
            ctx.arc(9, 9, 6, 0, Math.PI * 2);
            ctx.moveTo(10, 9);
            ctx.arc(9, 9, 1, 0, Math.PI * 2);
            break;
        case "settings":
            // Gear: a ring with eight teeth.
            ctx.arc(9, 9, 2.4, 0, Math.PI * 2);
            ctx.moveTo(14, 9);
            ctx.arc(9, 9, 5, 0, Math.PI * 2);
            for (let i = 0; i < 8; i++) {
                const a = Math.PI * i / 4;
                ctx.moveTo(9 + 5 * Math.cos(a), 9 + 5 * Math.sin(a));
                ctx.lineTo(9 + 7.2 * Math.cos(a), 9 + 7.2 * Math.sin(a));
            }
            break;
        case "back":
            ctx.moveTo(11, 4);
            ctx.lineTo(6, 9);
            ctx.lineTo(11, 14);
            break;
        case "power":
            ctx.arc(9, 10, 6.5, -Math.PI * 0.3, Math.PI * 1.3);
            ctx.moveTo(9, 1.5);
            ctx.lineTo(9, 8.5);
            break;
        }
        ctx.stroke();
    }
}
