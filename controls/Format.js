.pragma library

// Helpers shared by the settings pages.

function range(from, to, step) {
    const list = [];
    const by = step ?? 1;
    for (let v = from; v <= to + 1e-9; v += by)
        list.push(Math.round(v * 1000) / 1000);
    return list;
}

function twoDigits(n) {
    return String(n).padStart(2, "0");
}

function minutesOfDay(minutes) {
    return twoDigits(Math.floor(minutes / 60)) + ":" + twoDigits(minutes % 60);
}

function duration(seconds, never) {
    if (seconds >= never)
        return "Never";
    if (seconds < 60)
        return seconds + " s";
    if (seconds < 3600 && seconds % 60 !== 0)
        return Math.floor(seconds / 60) + ":" + twoDigits(seconds % 60) + " min";
    if (seconds < 3600)
        return (seconds / 60) + " min";
    return (seconds / 3600) + " h";
}

function percent(v) {
    return Math.round(v * 100) + "%";
}

function px(v) {
    return v + " px";
}

// "SUPER+shift + q" and "SHIFT + SUPER + Q" are the same keys.
function normalizeKeys(keys) {
    return keys.toUpperCase().split("+").map(k => k.trim()).filter(k => k !== "").sort().join("+");
}
