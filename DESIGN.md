# Design language

How this shell looks, moves and is built. `CLAUDE.md` records individual decisions; this file is the system they fit
into. Anything visual that is not listed here should not exist yet: add the token first, then use it.

## Character

Quiet, thin, exact. The desktop belongs to the windows and the wallpaper; the shell is a line at the top and things that
slide in when asked. It is a precision instrument rather than a dashboard.

1. **Monochrome first.** Text and icons use the foreground color. Color carries meaning, and only in small marks.
2. **Drawn, not borrowed.** Every icon is drawn on a Canvas. No icon fonts, no image icons in the shell.
3. **On the pixel.** Icons are one unit per pixel, on a 16-unit grid, at whole coordinates. Text uses native rendering.
4. **Soft transitions.** Panels fade in and out, like windows. Colors change by easing, never by snapping.
5. **Everything is a theme.** No color, font, size or duration is written into a widget. Presets decide.
6. **Idle costs nothing.** Nothing polls, animates or repaints without a visible reason.

## Tokens

Widgets read `Theme.*`. Nothing else may hold a look value. The only exceptions are the QR code's black on white, which
scanners need, and the SDDM fallbacks, which have no Theme.

### Color (`Theme.colors`)

| Role | Used for |
|---|---|
| `surface` | Bar, panels, cards. What everything sits on |
| `surfaceRaised` | Controls at rest, hovered rows |
| `surfaceHover` | Hovered controls, selected rows |
| `border` | Hairlines: panel edges, separators |
| `foreground` | Text and icons |
| `foregroundStrong` | Titles, values, the text being typed |
| `muted` | Secondary text, section captions, hints |
| `inactive` | Switched-off parts of icons, days outside the month |
| `accent` | The one current thing: selected segment, switch on, active workspace, focus ring |
| `accentAlt` | Second stop of a gradient only |
| `onAccent` | Text and icons on accent or error fills |
| `success` `warning` `caution` `error` `info` `special` | Status marks, with their usual meanings |

Rule of restraint: at most one accent-filled control per group of rows. Status colors never decorate.

### Type (`Theme.fonts`, through `Label`)

Three families per preset: text (`family`), titles (`familyTitle`), monospace (`familyMono`). Sizes are roles, not numbers.

| Role | Default | Used for |
|---|---|---|
| `caption` | 10 | Timestamps, fine print |
| `small` | 11 | Default: rows, hints, buttons, section captions |
| `body` | 12 | List titles, inputs |
| `title` | 14 | Page and panel titles |
| `bar` | 13 | Everything on the bar |
| `display` | 30 | One large number or time per panel |

Weight: `Theme.fonts.weight` for titles and captions, regular otherwise. Sentence case. No trailing period on a label; a
full sentence of help text has one.

### Space (`Theme.space`)

`xxs 2`, `xs 4`, `s 6`, `m 8`, `ml 10`, `l 12`, `xl 16`, `xxl 24`. Scaled by the preset's density. The bar is the exception:
its spacing is measured on what is drawn (`Theme.layout.itemSpacing`, `groupSpacing`) and does not scale.

### Size (`Theme.control`)

`small 24` (steppers, segments), `regular 28` (buttons, inputs, tabs), `iconButton 26`, `row 40` (two-line list rows),
`settingRow 30`. Scaled by density.

### Shape (`Theme.shape`)

Three nested radii from the preset's one radius: `panelRadius` (1), `barRadius` (0.72), `controlRadius` (0.57).
`innerRadius` is `controlRadius - 2`, for a control inside a control. Pills (switches, dots) are full height. A panel has one hairline border.
No shadows in the shell.

### Motion (`Theme.motion`)

| Preset | Default | Used for |
|---|---|---|
| `quick` | 120 ms | Hover, press, selection |
| `standard` | 180 ms | State colors, reveals |
| `panel` | 160 ms | Panels moving and resizing |

All ease out. A preset can scale them with `motionScale`, and 0 turns them off. Use `Motion` and `ColorMotion`, never a bare
animation. Looping indicators step on a `Timer`, whole steps only, so they do not hold the render loop open at 60 Hz.

## Components

Build with these. A new look means a new option on one of them, not a local copy.

| Component | Purpose |
|---|---|
| `Label` | All text. Defaults: theme family, `small`, foreground, plain text format |
| `controls/InteractiveSurface` | Any clickable rectangle: hover, pressed, selected and armed colors, transitions, pointer |
| `controls/ActionButton` | Text button. `confirm` needs two clicks |
| `controls/IconButton` | Drawn glyph button |
| `controls/Tabs` | Top-level views of one panel. Settings choices use `Dropdown` |
| `controls/SettingRow` | Label left, control right, one row height |
| `controls/SettingSection` | Caption and hairline that starts a group |
| `controls/SettingSwitch`, `SettingStepper`, `Dropdown`, `TextField` | Values |
| `controls/Hint` | Muted help or empty-state line, wraps |
| `controls/BarPanel` | Window for everything that opens under the bar or in the middle |
| `power/PanelButton` | Square glyph and label, for the power panel |

### Interaction states

| State | Fill | Content |
|---|---|---|
| Rest | transparent or `surfaceRaised` | `foreground` |
| Hover | `surfaceHover` | `foreground` |
| Selected | `accent` (segments), `surfaceHover` (rows) | `onAccent`, `foregroundStrong` |
| Armed (second click runs it) | `error` | `onAccent`, label ends in `?`; disarms after `Theme.motion.confirm` |
| Disabled | no change, opacity 0.4 | no pointer cursor |
| Focus | 1 px `accent` border on inputs | |

### Layout of a panel

Title row: title on the left, then actions, then the main switch at the far right. Content below at the panel's
padding. No hint lines at the bottom. Lists scroll past `listMaxHeight`. The card grows and shrinks; its window never does.

### Layout of Settings

Grouped sidebar: **Appearance** (saved per preset), **Hyprland** and **System** (saved once). The sidebar names the preset being edited. Help text only where a control would otherwise be misunderstood. Changes apply as they are made; there is no Save button. A setting that uses a lot of GPU says so.

## What belongs in a preset

Everything that changes how the desktop looks: wallpaper, colors, fonts and sizes, corners, bar and panel metrics, density, motion, every
visual Hyprland option, animation curves and speeds, cursor. **Not** in a preset: what the desktop does (keybinds, input, startup, monitors,
idle times) or the screen's own brightness and color temperature, which follow time of day, not theme.

## Performance rules

- Panels are built when first opened and released a minute after closing. Only the bar lives permanently.
- Windows that are closed are `visible: false`. A closed panel has no surface.
- A `Canvas` repaints only when an input it draws changes. Never bind it to a running animation; step it.
- Processes run on demand or block on events (`nmcli monitor`, inotify). No polling except while the thing is on screen.
- Changing one Hyprland option only touches Hyprland. Other apps are rebuilt only when colors, font or wallpaper change.
- Never expose an option that disables damage tracking or animates continuously. Those are hidden from the Hyprland pages (see `hyprland/schema.js`).

## Code rules

- One responsibility per file; state in singletons, drawing in `parts/`, windows in folders by feature.
- Shared JavaScript helpers live in `controls/Format.js`, not copied per page.
- Declare inputs as `property`, use ids rather than `parent.parent`.
- Secrets never go on a command line.
- Generated files are written beside the target and renamed over it, and Hyprland config is validated before it replaces the live one.
