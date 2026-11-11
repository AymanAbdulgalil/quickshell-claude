import QtQuick

// Every value a theme can set. To make a theme, add a file in this folder that
// starts from ThemeSpec or from an existing theme, and override what differs.
QtObject {
    component Colors: QtObject {
        property color surface
        property color surfaceRaised
        property color surfaceHover
        property color border
        property color foreground
        property color foregroundStrong
        property color muted     // secondary text
        property color inactive  // switched-off parts of icons
        property color accent
        property color accentAlt
        property color onAccent  // text and icons on top of accent or error fills
        property color info
        property color success
        property color warning
        property color caution
        property color error
        property color special
        // Invisible, for fading a fill in and out. "transparent" is invisible black, so fades passed through dark.
        readonly property color clear: Qt.rgba(surfaceHover.r, surfaceHover.g, surfaceHover.b, 0)
    }

    component Fonts: QtObject {
        property string family: "sans-serif"
        property string familyTitle: "sans-serif"
        property string familyMono: "monospace"
        property int caption: 10
        property int small: 11
        property int body: 12
        property int title: 14
        property int display: 30
        // Text on the bar, which has its own family and weight.
        property int bar: 13
        property string barFamily: "sans-serif"
        property int barWeight: Font.Medium
        // Titles and captions in panels.
        property int weight: Font.Medium
    }

    component Shape: QtObject {
        property int barRadius: 10
        property int panelRadius: 14
        property int controlRadius: 8
        // A control inside a control.
        readonly property int innerRadius: Math.max(0, controlRadius - 2)
        // Panels' border; the bar has its own.
        property int borderWidth: 1
        property int barBorderWidth: 1
    }

    component Layout: QtObject {
        property int barHeight: 32
        property bool barAtBottom: false
        // "top", "bottom", "left" or "right". A vertical bar keeps barHeight as its thickness.
        property string barEdge: "top"
        readonly property bool barVertical: barEdge === "left" || barEdge === "right"
        // Between the bar and the panels that open from it.
        property int panelBarGap: 6
        // From the screen edge the bar is on, to where a panel starts.
        readonly property int barClearance: barGapEdge + barHeight + panelBarGap
        // Around the bar, named from the bar: the screen edge it is on, the side facing the windows, and its ends
        // (start is left or top, end is right or bottom).
        property int barGapEdge: 10
        property int barGapInner: 0
        property int barGapStart: 10
        property int barGapEnd: 10
        // Panels: from the screen's sides (along the bar), and from the edge across from the bar.
        property int panelGapSide: 10
        property int panelGapFar: 10
        // Bar icons are as tall as the bar's digits; this is their canvas, two pixels taller.
        property int barIconSize: 16
        // Bar text is laid out in a box of this height (the icons' canvas) and moved down by barTextShift inside it,
        // so its digits, not its line box, sit on the bar's centre line. Use BarText.
        property int barTextBox: 16
        property real barTextShift: 0
        property int listPanelHeight: 520
        property int barPadding: 10
        property int itemSpacing: 10
        // Between groups of bar icons.
        property int groupSpacing: 18
        property int panelWidth: 320
        property int panelPadding: 16
        // Between two panels shown together (launcher and time panel, notification popups).
        property int panelGap: 6
        // Status icons are drawn on a 16 (or 20 by 16) grid. At 1 every unit is one pixel, which keeps them sharp.
        property real statusIconScale: 1
        property int listPanelWidth: 350
        property int listMaxHeight: 440
        property int notificationWidth: 370
        property int clipboardWidth: 420
        property int notesWidth: 530
        property int settingsWidth: 860
        property int settingsHeight: 680
        property int settingsSidebar: 170
        property int launcherWidth: 500
        property int launcherHeight: 410
        // How far below the middle of the screen the launcher and time panel sit.
        property int launcherShift: 40
        property int sliderPanelWidth: 270
        property int sliderPanelPadding: 10
    }

    component MotionPreset: QtObject {
        property int duration: 150
        property int easing: Easing.OutCubic
        // A cubic Bezier [x1, y1, x2, y2] that replaces `easing` when set, as in Hyprland's curves.
        property var bezier: []
    }

    component MotionSet: QtObject {
        property MotionPreset quick: MotionPreset { duration: 120 }
        property MotionPreset standard: MotionPreset { duration: 180 }
        property MotionPreset panel: MotionPreset { duration: 160 }
        // The bar's own: its entrance at start, and icons that come and go.
        property MotionPreset bar: MotionPreset { duration: 180 }
        property bool panelFade: true
        property bool panelSlide: false
        property bool barFade: true
        property bool barSlide: true
        // Loops in status indicators, in milliseconds.
        property int iconStep: 350
        property int flash: 500
        property int chargeCycle: 1100
        // How long an armed button (two clicks to run) stays armed.
        property int confirm: 4000
        property int nightStep: 100
    }

    // Swappable elements: which file in parts/ draws each one, without ".qml".
    // A part reads its inputs from `parent`. Each slot's inputs are listed in CLAUDE.md.
    component Parts: QtObject {
        property string workspaceMarker: "workspace/Dot"
        property string networkIcon: "network/Drawn"
        property string bluetoothIcon: "bluetooth/Drawn"
        property string batterySuffix: "battery/Symbols"
        property string clock: "clock/Digital"
        property string analogClock: "clock/Analog"
        property string cameraIcon: "camera/Lens"
        property string clipboardIcon: "clipboard/Board"
        property string logoIcon: "logo/Arch"
        property string notificationIcon: "notifications/Bell"
        property string language: "language/Code"
        property string powerGauge: "power/HatchedGauge"
        property string powerGlyph: "power/Glyph"
        property string brightnessIcon: "power/Sun"
        property string volumeIcon: "volume/Speaker"
        property string microphoneIcon: "microphone/Capsule"
    }

    // Icons and the accent element (2026-11-11).
    component Icons: QtObject {
        // "thin" or "thick" wire, or "filled".
        property string style: "thin"
        readonly property bool filled: style === "filled"
        // Line width on the 16-unit grid. Filled icons keep the thin line for what is not filled.
        property real stroke: 1.5
        // The theme's accent element: a small mark used for workspaces, task dots and the clock's marks. See parts/accent/shapes.js.
        property string mark: "dot"
    }

    property Colors colors: Colors {}
    property Fonts fonts: Fonts {}
    property Shape shape: Shape {}
    property Layout layout: Layout {}
    property Space space: Space {}
    property ControlSizes control: ControlSizes {}
    property MotionSet motion: MotionSet {}
    property Parts parts: Parts {}
    property Icons icons: Icons {}
}
