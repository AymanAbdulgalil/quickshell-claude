import QtQuick

// The active theme: a palette plus everything else the preset decides. ThemePresets.defaults has already filled it in.
ThemeSpec {
    id: root

    property var palette
    property var preset
    readonly property var hypr: preset?.hypr ?? ({})
    readonly property real scale: preset?.motionScale ?? 1
    readonly property int gapIn: gaps(hypr["general:gaps_in"] ?? 5)[0]
    // Hyprland's outer gap: one number, or top, right, bottom, left.
    readonly property var gapOut: gaps(hypr["general:gaps_out"] ?? 10)
    readonly property bool follow: preset?.panelGapsFollow ?? false

    function gaps(value) {
        const n = String(value).split(/[ ,]+/).map(v => parseInt(v)).filter(v => !isNaN(v));
        if (n.length === 0)
            return [0, 0, 0, 0];
        return [n[0], n[1] ?? n[0], n[2] ?? n[0], n[3] ?? n[1] ?? n[0]];
    }

    // An outer gap side by name: the bar's edge, the edge across from it, and the sides along it.
    function gapOutAt(side) {
        const index = { top: 0, right: 1, bottom: 2, left: 3 };
        const across = { top: "bottom", bottom: "top", left: "right", right: "left" };
        const edge = layout.barEdge;
        if (side === "edge")
            return gapOut[index[edge]];
        if (side === "far")
            return gapOut[index[across[edge]]];
        return layout.barVertical ? Math.max(gapOut[0], gapOut[2]) : Math.max(gapOut[1], gapOut[3]);
    }

    function curve(name) {
        const c = (preset?.curves ?? []).find(c => c.name === name);
        return c ? [c.x1, c.y1, c.x2, c.y2, 1, 1] : [];
    }

    // The bar's digits as actually drawn: icons take their height, and the text is centred on them, not on its line box.
    property FontMetrics barMetrics: FontMetrics {
        font.family: root.fonts.barFamily
        font.pixelSize: root.fonts.bar
        font.weight: root.fonts.barWeight
    }
    readonly property rect barDigit: {
        barMetrics.font;
        return barMetrics.tightBoundingRect("0");
    }
    // The tight rect is one pixel taller than the glyph it measures.
    readonly property int barDigitHeight: Math.max(6, Math.round(barDigit.height - 1))
    // Bar icons have their own size, separate from the bar's text (2026-11-10), in steps of one pixel (2026-11-11). The drawing
    // is symmetric in its canvas, and centred anchors put the canvas on a whole pixel; an odd size leaves the spare pixel above.
    readonly property int barIconDrawn: Math.max(6, Math.round(preset?.barIconSize ?? 12))
    // Bar text sits in a whole-pixel box as tall as an icon's canvas, so both are centred the same way. The digits are
    // centred in that box; when they cannot be exactly, the spare pixel goes above them, since text reads high otherwise.
    readonly property int barTextBox: barIconDrawn + 2
    readonly property int barDigitTop: Math.ceil((barTextBox - barDigit.height) / 2)

    colors {
        surface: palette.surface
        surfaceRaised: palette.surfaceRaised
        surfaceHover: palette.surfaceHover
        border: palette.border
        foreground: palette.foreground
        foregroundStrong: palette.foregroundStrong
        muted: palette.muted
        inactive: palette.inactive
        accent: palette.accent
        accentAlt: palette.accentAlt
        onAccent: palette.onAccent
        info: palette.info
        success: palette.success
        warning: palette.warning
        caution: palette.caution
        error: palette.error
        special: palette.special
    }

    fonts {
        family: preset?.panelFont || preset?.font || "JetBrains Mono"
        familyTitle: preset?.fontTitle || fonts.family
        familyMono: preset?.fontMono || fonts.family
        small: preset?.fontSmall ?? 11
        caption: fonts.small - 1
        body: fonts.small + 1
        title: fonts.small + 3
        bar: preset?.fontBar ?? 13
        display: preset?.fontDisplay ?? 30
        weight: preset?.fontWeight ?? Font.Medium
        barFamily: preset?.barFont || preset?.font || "JetBrains Mono"
        barWeight: preset?.barWeight ?? Font.Medium
    }

    // The panels' corners drive their controls', in the proportions of the original 14 and 8. The bar has its own.
    shape {
        panelRadius: preset?.widgetRadius ?? 14
        barRadius: preset?.barRadius ?? 10
        controlRadius: Math.round((preset?.widgetRadius ?? 14) * 0.57)
        borderWidth: preset?.panelBorder ?? 1
        barBorderWidth: preset?.barBorder ?? 1
    }

    space.density: preset?.density ?? 1
    control.density: preset?.density ?? 1

    layout {
        barHeight: preset?.barHeight ?? 32
        barEdge: preset?.barPosition ?? "top"
        barAtBottom: layout.barEdge === "bottom"
        // Following the windows, a panel starts where they do: past the bar's inner gap and Hyprland's outer gap.
        panelBarGap: root.follow ? (preset?.barGapInner ?? 0) + root.gapOutAt("edge") : preset?.panelBarGap ?? 6
        panelGapSide: root.follow ? root.gapOutAt("side") : preset?.panelGapSide ?? 10
        panelGapFar: root.follow ? root.gapOutAt("far") : preset?.panelGapFar ?? 10
        // The icon's canvas: its drawing (14 grid units tall) with one pixel to spare above and below.
        barIconSize: root.barIconDrawn + 2
        statusIconScale: (root.barIconDrawn + 0.7) / 14
        barTextBox: root.barTextBox
        // From the box's top to where the text's line box must start for the digits to land on barDigitTop. The quarter pixel
        // keeps the baseline inside its pixel whether the renderer rounds or floors it.
        barTextShift: root.barDigitTop - root.barDigit.y - root.barMetrics.ascent + 0.25
        barGapEdge: preset?.barGapEdge ?? 10
        barGapInner: preset?.barGapInner ?? 0
        barGapStart: preset?.barGapStart ?? 10
        barGapEnd: preset?.barGapEnd ?? 10
        barPadding: preset?.barPadding ?? 10
        itemSpacing: preset?.barItemSpacing ?? 10
        groupSpacing: preset?.barGroupSpacing ?? 18
        panelGap: root.follow ? root.gapIn : preset?.panelGapBetween ?? 5
        panelPadding: Math.round(16 * (preset?.density ?? 1))
    }

    motion {
        quick.duration: 120 * root.scale
        standard.duration: 180 * root.scale
        panel.duration: (preset?.panelSpeed ?? 160) * root.scale
        panel.bezier: root.curve(preset?.panelCurve ?? "default")
        bar.duration: (preset?.barSpeed ?? 180) * root.scale
        bar.bezier: root.curve(preset?.barCurve ?? "default")
        panelFade: preset?.panelFade ?? true
        panelSlide: preset?.panelSlide ?? false
        barFade: preset?.barFade ?? true
        barSlide: preset?.barSlide ?? true
    }

    icons {
        style: preset?.iconStyle ?? "thin"
        stroke: (preset?.iconStyle ?? "thin") === "thick" ? 2.1 : 1.5
        mark: preset?.accentMark ?? "dot"
    }

    parts.analogClock: preset?.analogClock ?? "clock/Analog"
}
