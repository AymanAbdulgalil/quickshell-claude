"""Turns Hyprland option names and values into Lua for its config API. Shared by generate.py and themes/apply.py."""
import re

GRADIENT = re.compile(r"^(\S+(?: \S+)*) (-?\d+)deg$")


def lua(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return '"' + value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'
    if isinstance(value, list):
        return "{ " + ", ".join(lua(v) for v in value) + " }"
    if isinstance(value, dict):
        return "{ " + ", ".join(f"{key(k)} = {lua(v)}" for k, v in value.items()) + " }"
    raise TypeError(f"cannot write {value!r} as Lua")


def key(name):
    return name if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name) else f'["{name}"]'


def color_word(word):
    """Hyprland lists colors as aarrggbb; Lua takes rgba(rrggbbaa)."""
    if re.fullmatch(r"[0-9a-fA-F]{8}", word):
        return f"rgba({word[2:]}{word[:2]})"
    return word


def option_value(name, value):
    """Colors as `hyprctl descriptions` shows them ("aabbccdd eeff0011 45deg") become what Lua wants."""
    if isinstance(value, str) and ("col." in name or "color" in name):
        found = GRADIENT.match(value)
        if found:
            words = [color_word(w) for w in found.group(1).split()]
            if len(words) == 1 and found.group(2) == "0":
                return words[0]
            return {"colors": words, "angle": int(found.group(2))}
        return color_word(value)
    return value


def nest(options):
    """{"decoration:blur:size": 6, "general:col.active_border": x} to nested tables, as hl.config takes them."""
    tree = {}
    for name, value in options.items():
        parts = [p for section in name.split(":") for p in section.split(".")]
        node = tree
        for part in parts[:-1]:
            node = node.setdefault(part, {})
        node[parts[-1]] = option_value(name, value)
    return tree


def config_calls(options):
    """One hl.config per top-level section, so a bad value only loses its own section."""
    return [f"hl.config({{ {key(section)} = {lua(body)} }})" for section, body in nest(options).items()]


def curve_call(c):
    return f'hl.curve({lua(c["name"])}, {{ type = "bezier", points = {{ {{{c["x1"]}, {c["y1"]}}}, {{{c["x2"]}, {c["y2"]}}} }} }})'


def animation_call(leaf, a):
    fields = {"leaf": leaf, "enabled": bool(a.get("enabled", True)), "speed": a.get("speed", 1), "bezier": a.get("curve", "default")}
    if a.get("style"):
        fields["style"] = a["style"]
    return f"hl.animation({lua(fields)})"
