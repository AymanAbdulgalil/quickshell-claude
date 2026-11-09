.pragma library

// Which of Hyprland's options the Settings app shows, where they are saved, and how each is edited.

// Never shown: debugging switches (one disables damage tracking), continuously animating effects (GPU), and values
// the shell itself controls.
const hiddenPrefixes = ["debug:", "experimental:", "quirks:", "input-capture:", "decoration:motion_blur", "decoration:wobble",
    "decoration:blur:fluid_jar", "decoration:blur:water", "decoration:blur:aurora", "decoration:blur:ripple", "decoration:blur:haze",
    "decoration:blur:drops", "decoration:blur:heat_shimmer", "decoration:blur:glass", "decoration:blur:acrylic"];
const hiddenNames = ["decoration:screen_shader", "misc:background_color", "general:col.active_border", "general:col.inactive_border"];

const visualPrefixes = ["general:", "decoration:", "animations:", "group:", "dwindle:", "master:", "scrolling:", "layout:", "layers:", "cursor:"];
const visualMisc = ["misc:disable_hyprland_logo", "misc:disable_splash_rendering", "misc:force_default_wallpaper", "misc:font_family",
    "misc:splash_font_family", "misc:col.splash", "misc:animate_manual_resizes", "misc:animate_mouse_windowdragging"];
const heavy = ["decoration:blur:", "decoration:shadow:", "decoration:glow:"];

function isHidden(name) {
    return hiddenNames.includes(name) || hiddenPrefixes.some(p => name.startsWith(p));
}

// Saved in the theme preset rather than in hyprland.json.
function isVisual(name) {
    return visualMisc.includes(name) || visualPrefixes.some(p => name.startsWith(p));
}

function isHeavy(name) {
    return heavy.some(p => name.startsWith(p));
}

// "switch", "choice", "number", "gap", "text"
function kindOf(o) {
    if (typeof o.default === "boolean")
        return "switch";
    if (o.map)
        return "choice";
    if (typeof o.default === "number")
        return "number";
    if (/^\d+ \d+ \d+ \d+$/.test(String(o.default)))
        return "gap";
    return "text";
}

// Hyprland reports a choice as [{ label: value }, ...].
function choices(o) {
    return (o.map ?? []).map(entry => {
        const label = Object.keys(entry)[0];
        return [entry[label], label];
    }).sort((a, b) => a[0] - b[0]);
}

// What the option holds now, in the form its editor wants.
function shown(o) {
    if (kindOf(o) === "gap")
        return parseInt(o.current);
    return o.current;
}

function defaultOf(o) {
    if (kindOf(o) === "gap")
        return parseInt(o.default);
    return o.default;
}

function title(name) {
    const last = name.split(":").pop().replace(/^col\./, "");
    const words = last.replace(/_/g, " ");
    return words.charAt(0).toUpperCase() + words.slice(1);
}

function section(name) {
    return name.split(":").slice(0, -1).join(" › ");
}

function matches(o, query) {
    return query === "" || o.name.toLowerCase().includes(query) || (o.description ?? "").toLowerCase().includes(query);
}

// What a keybind can do: [kind, label, what its argument is, or "" for none].
const actions = [
    ["exec", "Run a command", "Command"],
    ["global", "Shell action", "quickshell:launcher, clipboard, notes, settings, themes"],
    ["close", "Close window", ""],
    ["float", "Toggle floating", ""],
    ["pseudo", "Toggle pseudo-tiling", ""],
    ["split", "Toggle split", ""],
    ["focusDirection", "Focus direction", "left, right, up or down"],
    ["focusWorkspace", "Go to workspace", "1, or e+1, e-1"],
    ["moveToWorkspace", "Move window to workspace", "1, or special:magic"],
    ["special", "Toggle special workspace", "Name"],
    ["drag", "Drag window with mouse", ""],
    ["resize", "Resize window with mouse", ""],
    ["exit", "Exit Hyprland", ""],
    ["lua", "Lua expression", "hl.dsp...."]
];

function actionOf(kind) {
    return actions.find(a => a[0] === kind) ?? actions[0];
}

function describeBind(b) {
    const a = actionOf(b.kind);
    return a[2] === "" ? a[1] : a[1] + ": " + b.arg;
}

// Qt key to the name Hyprland uses.
function keyName(event) {
    const special = {
        [0x01000004]: "Return", [0x01000005]: "Return", [0x20]: "Space", [0x01000001]: "Tab", [0x01000003]: "BackSpace",
        [0x01000007]: "Delete", [0x01000006]: "Insert", [0x01000010]: "Home", [0x01000011]: "End", [0x01000016]: "Page_Up",
        [0x01000017]: "Page_Down", [0x01000012]: "left", [0x01000013]: "up", [0x01000014]: "right", [0x01000015]: "down",
        [0x01000009]: "Print"
    };
    if (special[event.key])
        return special[event.key];
    if (event.key >= 0x01000030 && event.key <= 0x01000052)
        return "F" + (event.key - 0x01000030 + 1);
    if (event.key >= 0x20 && event.key < 0x7f)
        return String.fromCharCode(event.key).toUpperCase();
    return "";
}

// "SUPER + SHIFT + Q" from a key press, or "" for a press of a modifier alone.
function chord(event, mods) {
    const name = keyName(event);
    if (name === "")
        return "";
    const parts = [];
    if (event.modifiers & mods.meta)
        parts.push("SUPER");
    if (event.modifiers & mods.control)
        parts.push("CTRL");
    if (event.modifiers & mods.alt)
        parts.push("ALT");
    if (event.modifiers & mods.shift)
        parts.push("SHIFT");
    parts.push(name);
    return parts.join(" + ");
}

// How a modifier pressed alone is bound, or "" for any other key.
function loneModifier(key) {
    const names = {
        [0x01000053]: "SUPER + SUPER_L", [0x01000054]: "SUPER + SUPER_R", [0x01000022]: "SUPER + SUPER_L",
        [0x01000021]: "CTRL + Control_L", [0x01000020]: "SHIFT + Shift_L", [0x01000023]: "ALT + Alt_L"
    };
    return names[key] ?? "";
}
