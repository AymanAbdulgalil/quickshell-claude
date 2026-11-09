import QtQuick

// The active theme: a palette plus everything else the preset decides. ThemePresets.defaults has already filled it in.
ThemeSpec {
    id: root

    property var palette
    property var preset
    readonly property var hypr: preset?.hypr ?? ({})
    readonly property real scale: preset?.motionScale ?? 1
    readonly property int gapIn: hypr["general:gaps_in"] ?? 5

    // The bar's digits as actually drawn: icons take their height, and the text is centred on them, not on its line box.
    property FontMetrics barMetrics: FontMetrics {
        font.family: root.fonts.family
        font.pixelSize: root.fonts.bar
        font.weight: root.fonts.weight
    }
    readonly property rect barDigit: {
        barMetrics.font;
        return barMetrics.tightBoundingRect("0");
    }
    // The tight rect is one pixel taller than the glyph it measures.
    readonly property int barDigitHeight: Math.max(6, Math.round(barDigit.height - 1))
    // Icons are drawn at 4:3 to the digits, to the nearest even height so they stay on whole pixels in the bar.
    readonly property int barIconDrawn: 2 * Math.round(barDigitHeight * 2 / 3)

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
        family: preset?.font ?? "JetBrains Mono"
        familyTitle: preset?.fontTitle || fonts.family
        familyMono: preset?.fontMono || fonts.family
        small: preset?.fontSmall ?? 11
        caption: fonts.small - 1
        body: fonts.small + 1
        title: fonts.small + 3
        bar: preset?.fontBar ?? 13
        display: preset?.fontDisplay ?? 30
        weight: preset?.fontWeight ?? Font.Medium
    }

    // One corner setting drives all three, in the proportions of the original 10, 14, 8.
    shape {
        panelRadius: preset?.widgetRadius ?? 14
        barRadius: Math.round((preset?.widgetRadius ?? 14) * 0.72)
        controlRadius: Math.round((preset?.widgetRadius ?? 14) * 0.57)
        borderWidth: preset?.panelBorder ?? 1
    }

    space.density: preset?.density ?? 1
    control.density: preset?.density ?? 1

    layout {
        barHeight: preset?.barHeight ?? 32
        barEdge: preset?.barPosition ?? "top"
        barAtBottom: layout.barEdge === "bottom"
        panelBarGap: preset?.panelBarGap ?? 6
        // The icon's canvas: its drawing (14 grid units tall) with one pixel to spare above and below.
        barIconSize: root.barIconDrawn + 2
        statusIconScale: (root.barIconDrawn + 0.7) / 14
        barTextShift: Math.round(root.barMetrics.height / 2 - (root.barMetrics.ascent + root.barDigit.y + root.barDigit.height / 2))
        barMargin: preset?.barGap ?? 10
        barPadding: preset?.barPadding ?? 10
        itemSpacing: preset?.barItemSpacing ?? 10
        groupSpacing: preset?.barGroupSpacing ?? 18
        // Panels stand apart by the same gap as windows: from the bar, and launcher from time panel.
        panelGap: root.gapIn
        panelPadding: Math.round(16 * (preset?.density ?? 1))
    }

    motion {
        quick.duration: 120 * root.scale
        standard.duration: 180 * root.scale
        panel.duration: (preset?.panelSpeed ?? 160) * root.scale
    }

    parts.analogClock: preset?.analogClock ?? "clock/Analog"
}
