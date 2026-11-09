.pragma library

// Color palettes a theme preset can use, and the math that turns wallpaper colors into a palette.
// Theme presets themselves (wallpaper, colors, font, corners, gaps...) live in presets.json.

function make(id, name, dark, surfaces, text, accents, states, extra) {
    return Object.assign({
        id: id,
        name: name,
        palette: {
            dark: dark,
            surface: surfaces[0],
            surfaceRaised: surfaces[1],
            surfaceHover: surfaces[2],
            border: surfaces[3],
            foreground: text[0],
            foregroundStrong: text[1],
            muted: text[2],
            inactive: text[3],
            accent: accents[0],
            accentAlt: accents[1],
            onAccent: accents[2],
            info: states[0],
            success: states[1],
            warning: states[2],
            caution: states[3],
            error: states[4],
            special: states[5]
        }
    }, extra ?? {});
}

const NORD = {
    surfaces: ["#2e3440", "#3b4252", "#434c5e", "#4c566a"],
    text: ["#d8dee9", "#eceff4", "#81a1c1", "#4c566a"],
    accents: ["#88c0d0", "#81a1c1", "#2e3440"],
    states: ["#8fbcbb", "#a3be8c", "#ebcb8b", "#d08770", "#bf616a", "#b48ead"]
};

const list = [
    make("nord", "Nord", true, NORD.surfaces, NORD.text, NORD.accents, NORD.states),
    make("catppuccinMocha", "Catppuccin Mocha", true,
        ["#1e1e2e", "#313244", "#45475a", "#585b70"],
        ["#bac2de", "#cdd6f4", "#a6adc8", "#585b70"],
        ["#89b4fa", "#b4befe", "#1e1e2e"],
        ["#94e2d5", "#a6e3a1", "#f9e2af", "#fab387", "#f38ba8", "#cba6f7"]),
    make("catppuccinLatte", "Catppuccin Latte", false,
        ["#eff1f5", "#e6e9ef", "#dce0e8", "#bcc0cc"],
        ["#4c4f69", "#1e2030", "#6c6f85", "#acb0be"],
        ["#1e66f5", "#7287fd", "#eff1f5"],
        ["#179299", "#40a02b", "#df8e1d", "#fe640b", "#d20f39", "#8839ef"]),
    make("gruvboxDark", "Gruvbox Dark", true,
        ["#282828", "#3c3836", "#504945", "#665c54"],
        ["#ebdbb2", "#fbf1c7", "#a89984", "#665c54"],
        ["#83a598", "#458588", "#282828"],
        ["#8ec07c", "#b8bb26", "#fabd2f", "#fe8019", "#fb4934", "#d3869b"]),
    make("tokyoNight", "Tokyo Night", true,
        ["#1a1b26", "#24283b", "#292e42", "#414868"],
        ["#a9b1d6", "#c0caf5", "#737aa2", "#414868"],
        ["#7aa2f7", "#7dcfff", "#1a1b26"],
        ["#73daca", "#9ece6a", "#e0af68", "#ff9e64", "#f7768e", "#bb9af7"]),
    make("dracula", "Dracula", true,
        ["#282a36", "#343746", "#44475a", "#6272a4"],
        ["#f8f8f2", "#ffffff", "#9aa5ce", "#6272a4"],
        ["#bd93f9", "#ff79c6", "#282a36"],
        ["#8be9fd", "#50fa7b", "#f1fa8c", "#ffb86c", "#ff5555", "#ff79c6"]),
    make("rosePine", "Rosé Pine", true,
        ["#191724", "#1f1d2e", "#26233a", "#403d52"],
        ["#e0def4", "#e0def4", "#908caa", "#6e6a86"],
        ["#c4a7e7", "#9ccfd8", "#191724"],
        ["#9ccfd8", "#9ccfd8", "#f6c177", "#ebbcba", "#eb6f92", "#c4a7e7"]),
    make("everforest", "Everforest", true,
        ["#2d353b", "#343f44", "#3d484d", "#475258"],
        ["#d3c6aa", "#e4dcc6", "#9da9a0", "#7a8478"],
        ["#a7c080", "#83c092", "#2d353b"],
        ["#7fbbb3", "#a7c080", "#dbbc7f", "#e69875", "#e67e80", "#d699b6"])
];

function find(id) {
    return list.find(p => p.id === id) ?? list[0];
}

// The roles a palette has, in the order the custom colors list shows them.
const roles = [
    ["surface", "Background"],
    ["surfaceRaised", "Raised background"],
    ["surfaceHover", "Hover background"],
    ["border", "Border"],
    ["foreground", "Text"],
    ["foregroundStrong", "Strong text"],
    ["muted", "Quiet text"],
    ["inactive", "Inactive"],
    ["accent", "Accent"],
    ["accentAlt", "Second accent"],
    ["onAccent", "Text on accent"],
    ["info", "Info"],
    ["success", "Success"],
    ["warning", "Warning"],
    ["caution", "Caution"],
    ["error", "Error"],
    ["special", "Special"]
];

function hexToRgb(hex) {
    return [parseInt(hex.slice(1, 3), 16) / 255, parseInt(hex.slice(3, 5), 16) / 255, parseInt(hex.slice(5, 7), 16) / 255];
}

function rgbToHsl(rgb) {
    const [r, g, b] = rgb;
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    const l = (max + min) / 2;
    if (max === min)
        return [0, 0, l];
    const d = max - min;
    const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    let h = max === r ? (g - b) / d + (g < b ? 6 : 0) : max === g ? (b - r) / d + 2 : (r - g) / d + 4;
    return [h * 60, s, l];
}

function hsl(h, s, l) {
    h = ((h % 360) + 360) % 360;
    const c = (1 - Math.abs(2 * l - 1)) * s;
    const x = c * (1 - Math.abs((h / 60) % 2 - 1));
    const m = l - c / 2;
    const parts = h < 60 ? [c, x, 0] : h < 120 ? [x, c, 0] : h < 180 ? [0, c, x] : h < 240 ? [0, x, c] : h < 300 ? [x, 0, c] : [c, 0, x];
    return "#" + parts.map(v => Math.round((v + m) * 255).toString(16).padStart(2, "0")).join("");
}

// swatches: [{ hex, weight }] from the wallpaper, most common first.
function fromSwatches(swatches, dark) {
    let accentHue = 210;
    let accentSat = 0.5;
    let best = -1;
    let baseHue = 220;
    let baseSat = 0.12;
    let baseWeight = -1;
    for (const swatch of swatches) {
        const [h, s, l] = rgbToHsl(hexToRgb(swatch.hex));
        const score = s * Math.sqrt(swatch.weight) * (l > 0.2 && l < 0.85 ? 1 : 0.2);
        if (score > best) {
            best = score;
            accentHue = h;
            accentSat = s;
        }
        if (swatch.weight > baseWeight) {
            baseWeight = swatch.weight;
            baseHue = h;
            baseSat = s;
        }
    }
    const tint = Math.min(0.3, baseSat * 0.6 + 0.05);
    const vivid = Math.max(0.45, Math.min(0.8, accentSat));
    const L = dark ? [0.13, 0.18, 0.23, 0.32] : [0.95, 0.9, 0.85, 0.75];
    const textL = dark ? [0.85, 0.94, 0.62, 0.36] : [0.25, 0.12, 0.45, 0.68];
    const accentL = dark ? 0.7 : 0.42;
    const stateS = dark ? 0.6 : 0.7;
    const stateL = dark ? 0.68 : 0.42;
    return {
        dark: dark,
        surface: hsl(baseHue, tint, L[0]),
        surfaceRaised: hsl(baseHue, tint, L[1]),
        surfaceHover: hsl(baseHue, tint, L[2]),
        border: hsl(baseHue, tint, L[3]),
        foreground: hsl(baseHue, 0.2, textL[0]),
        foregroundStrong: hsl(baseHue, 0.2, textL[1]),
        muted: hsl(accentHue, 0.25, textL[2]),
        inactive: hsl(baseHue, tint, textL[3]),
        accent: hsl(accentHue, vivid, accentL),
        accentAlt: hsl(accentHue + 25, vivid * 0.8, accentL),
        onAccent: hsl(baseHue, tint, dark ? L[0] : 0.97),
        info: hsl(accentHue + 40, stateS, stateL),
        success: hsl(110, stateS, stateL),
        warning: hsl(45, stateS + 0.2, stateL),
        caution: hsl(25, stateS + 0.15, stateL),
        error: hsl(355, stateS + 0.1, stateL),
        special: hsl(accentHue + 90, stateS, stateL)
    };
}
