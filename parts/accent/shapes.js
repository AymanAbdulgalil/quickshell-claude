.pragma library

// The theme's accent element (2026-11-11): a small filled mark, chosen per preset (`accentMark`). Used for the workspaces,
// the calendar's task dots and the clock's marks. path() only builds the path, centred on x, y and reaching r from it;
// the caller fills it with fill(), which sets the fill rule each shape needs.

// Name and label, in the order Settings lists them.
var kinds = [["dot", "Dot"], ["ring", "Ring"], ["diamond", "Diamond"], ["hexagon", "Hexagon"], ["sparkle", "Sparkle"],
    ["astroid", "Astroid"], ["flower", "Four-petal flower"], ["star", "Eight-point star (two squares)"]];

function polygon(ctx, x, y, points) {
    ctx.moveTo(x + points[0][0], y + points[0][1]);
    for (var i = 1; i < points.length; i++)
        ctx.lineTo(x + points[i][0], y + points[i][1]);
    ctx.closePath();
}

function path(ctx, kind, x, y, r) {
    var i, a, pts;
    ctx.beginPath();
    switch (kind) {
    case "ring":
        ctx.arc(x, y, r, 0, Math.PI * 2, false);
        ctx.moveTo(x + r * 0.5, y);
        ctx.arc(x, y, r * 0.5, 0, Math.PI * 2, true);
        break;
    case "diamond":
        polygon(ctx, x, y, [[0, -r], [r * 0.78, 0], [0, r], [-r * 0.78, 0]]);
        break;
    case "hexagon":
        pts = [];
        for (i = 0; i < 6; i++) {
            a = Math.PI / 3 * i - Math.PI / 2;
            pts.push([r * Math.cos(a), r * Math.sin(a)]);
        }
        polygon(ctx, x, y, pts);
        break;
    case "sparkle":
        // Four straight points with a narrow waist.
        pts = [];
        for (i = 0; i < 8; i++) {
            a = Math.PI / 4 * i - Math.PI / 2;
            var d = i % 2 === 0 ? r : r * 0.3;
            pts.push([d * Math.cos(a), d * Math.sin(a)]);
        }
        polygon(ctx, x, y, pts);
        break;
    case "astroid":
        // x = r cos^3 t, y = r sin^3 t: four curved points.
        for (i = 0; i <= 64; i++) {
            a = Math.PI * 2 * i / 64;
            var c = Math.cos(a), s = Math.sin(a);
            var px = x + r * c * c * c, py = y + r * s * s * s;
            if (i === 0)
                ctx.moveTo(px, py);
            else
                ctx.lineTo(px, py);
        }
        ctx.closePath();
        break;
    case "flower":
        // Four pointed petals that meet in a point at the centre: each a leaf from the centre to its tip.
        for (i = 0; i < 4; i++) {
            a = Math.PI / 2 * i;
            var ux = Math.cos(a), uy = Math.sin(a);
            var vx = -uy, vy = ux;
            var w = r * 0.62;
            ctx.moveTo(x, y);
            ctx.quadraticCurveTo(x + ux * r * 0.5 + vx * w, y + uy * r * 0.5 + vy * w, x + ux * r, y + uy * r);
            ctx.quadraticCurveTo(x + ux * r * 0.5 - vx * w, y + uy * r * 0.5 - vy * w, x, y);
            ctx.closePath();
        }
        break;
    case "star":
        // Two squares, one turned 45 degrees, both wound the same way so they join.
        var h = r / Math.SQRT2;
        polygon(ctx, x, y, [[-h, -h], [h, -h], [h, h], [-h, h]]);
        polygon(ctx, x, y, [[0, -r], [r, 0], [0, r], [-r, 0]]);
        break;
    default:
        ctx.arc(x, y, r, 0, Math.PI * 2, false);
    }
}

// Shapes that look smaller than a dot of the same reach are drawn a little larger, so all read the same size.
function reach(kind) {
    return { dot: 1, ring: 1, diamond: 1.1, hexagon: 1.02, sparkle: 1.25, astroid: 1.3, flower: 1.15, star: 1.08 }[kind] || 1;
}

function fill(ctx, kind, x, y, r, color) {
    ctx.save();
    ctx.fillStyle = color;
    // The ring's hole needs even-odd; every other shape is wound one way, so even-odd changes nothing for them except the
    // star, whose two squares overlap and must stay nonzero.
    ctx.fillRule = kind === "ring" ? Qt.OddEvenFill : Qt.WindingFill;
    path(ctx, kind, x, y, r * reach(kind));
    ctx.fill();
    ctx.restore();
}
