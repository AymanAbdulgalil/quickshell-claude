# Quickshell config: decisions and rules

Living record of what Ayman has decided. Updated as decisions are made; read often.
Items marked **(assumed)** were Claude's call. Ayman reviewed stage 1's and said "good decisions";
the ones in the power widget are not reviewed yet.

## Working rules

- Keep this file updated with decisions and rules from Ayman's messages.
- Keep `todo.txt` updated so open items persist across sessions. Remove items when done.
- Track every decision Ayman has not made yet in the "Decisions waiting on Ayman" section of `todo.txt`.
- Do not use anything that makes Hyprland disable damage tracking or otherwise raises GPU use a lot.
- Design happens in stages. Finish one stage before starting the next.
- Starting from scratch: the old config was deleted on request. Do not restore it.
- Icons are drawn (Canvas), not taken from an icon font.
- Processing Ayman's messages (2026-11-07): break each message into separate tasks, one per request, fix or tweak.
  Then group related tasks together (same file, same feature, or same system area) and work through one group at a
  time, so related changes are made and tested together. Report back by group.
- `DESIGN.md` is the design language: tokens, components, interaction states, performance rules. Read it before touching
  anything visual, and follow it.
- `HYPRLAND_UPGRADE.md` lists what to recheck whenever Hyprland, hyprlock or Quickshell update. Keep it current.
- `SETUP.md` records everything built and every system change made, for rebuilding or undoing. Update it along with
  this file.

## Theme system

Everything visual can change per theme: colors, fonts, corner rounding, layout, animation presets, and whole elements.
Themes are **presets**, built by Ayman in Settings and saved in `presets.json` (`ThemePresets.qml`).
**Every setting that affects appearance is in the preset** (2026-11-08): wallpaper; colors from a palette, the wallpaper (dark or
light), or custom; font, sizes and weight; corner radius, panel border, density; bar height, padding and spacing; motion speed;
how far windows fade behind panels; the gap between bar and panels; three fonts (text, titles, monospace); cursor; every visual Hyprland option (`hypr`, by option name); animation
curves and leaves. Presets store only what differs from `ThemePresets.defaults`. Not in a preset: keybinds, input, monitors, startup,
idle, and brightness and color temperature, which follow time of day. `Settings.themePreset` is the active id.

- `themes/palettes.js` holds the color palettes (Nord, Catppuccin...) and the wallpaper-to-palette math.
- `themes/ThemeSpec.qml` lists every value a theme can set. `themes/RuntimeTheme.qml` fills it from the active preset.
  Bar and control radius are scaled from the one panel radius (0.72 and 0.57).
- `Theme.qml` is what widgets read.
- `theming/ThemeManager.qml` switches and edits presets, sets the wallpaper (`awww`), works out wallpaper colors
  (cached per wallpaper and style in `Settings.wallpaperPalettes`, both styles at once, for every preset ahead of time),
  and passes the look on through `themes/apply.py`.
- **Theme switcher** (`theming/ThemeSwitcher.qml`): Super+T fades in a centred panel, 75% of the width: presets in a looping row, the current one in the
  middle and larger, each with its whole uncropped wallpaper and its name. No search. Arrows and Enter, the wheel or a click pick one. Also `qs ipc call theme panel`.
- Widgets use `Theme.colors`, `.fonts`, `.shape`, `.layout`, `.space`, `.control`, `.motion`, `.parts`, and `Label` for all text. Never hex values or
  palette names outside `themes/`, except the QR code's white background and black modules, which scanners need.
- A Canvas that paints with `Theme.colors` directly needs `themeWatch` (see any part), or it stays stale on a change.
- Animations use `Motion { preset: Theme.motion.quick }` (`quick`, `standard`, `panel`).
- Every state-driven color transitions: `Behavior on color { ColorMotion {} }`. No color may snap.
  In Canvas parts, animate a color or level property and repaint when it changes.

### Swapping elements

`Part { slot: "..." }` loads the file named in `Theme.parts`. To swap one: add a file under `parts/`,
and point the slot at it from a theme. The part reads its inputs from `parent`.

| Slot | Inputs |
|---|---|
| `workspaceMarker` | `current`, `occupied` |
| `networkIcon` | `netState`, `signalStrength`, `vpn` |
| `bluetoothIcon` | `btState`, `dots`, `discoverable` |
| `batterySuffix` | `mode`, `tint` |
| `clock` | `hours`, `minutes` |
| `language` | `layoutName` |
| `powerGauge` | `charge`, `capacity`, `tint` |
| `powerGlyph` | `glyph`, `tint` |
| `brightnessIcon` | `level`, `tint`, `iconSize`, `off` (night mode) |
| `volumeIcon` | `level`, `tint`, `iconSize`, `off` (muted) |
| `microphoneIcon` | `level`, `tint`, `iconSize`, `off` (muted) |

## Colors

- Default preset: official Nord palette: https://www.nordtheme.com/docs/colors-and-palettes
- Follow Nord's meanings: nord11 error, nord13 warning, nord14 success, nord4 foreground text.

## Stage 1: minimal bar (done)

Thin bar floating at the top, with rounded corners and a subtle border.

### Layout

- Left: Arch logo (opens Settings; the gears in panels were removed on request, 2026-11-08), a group gap, then the workspace selector.
- Bar position, top, bottom, left or right, is per preset (`barPosition`); panels, popups and Notes follow it. Vertical is a plain stack for now; Ayman will build on it later.
- Middle: time.
- Right, reading **right to left** (2026-11-09): battery | wifi, Bluetooth, volume, microphone, camera, notifications | language.
  `|` is a wider gap (`Theme.layout.groupSpacing`). No brightness icon: its slider is in the power panel.
  The microphone shows only while an app records (red), the camera only while in use; both slide in and out
  (`bar/Reveal.qml`). No clipboard icon (Super+V only) and no theme icon on the bar.
- Bar is 32 px tall (2026-11-06); status icons are drawn at 4:3 to the bar's digits, to the nearest even height, measured from the font (`RuntimeTheme.barIconDrawn`, 2026-11-09),
  so they follow the bar text size, which is separate from the panels'. Bar text is moved by `barTextShift` so its digits, not its line box, sit on the centre
  line. Every drawing fits y 1 to 15 of its grid; panels keep 16 px icons at one unit per pixel. Icon drawings fill their 16-unit grid, so all
  icons look the same size and sit on the bar's centre line. Everything on the right sits on whole pixels.
- Spacing is measured on what is drawn: about 12 px between icons in a group, 20 px between groups. The Bluetooth icon
  keeps blank room for its wave and dots, so its pair is pulled closer (`BarContents.qml`).
- Battery: 3 px between the number and its symbol; 9 px from the bar's right edge. Every symbol uses one slot, as wide as `%`, so the number never moves. Charging is an upward arrow that fades at both ends of its travel.

### Battery

| State | Text color | Beside the number |
|---|---|---|
| Normal | foreground | `%` |
| Low (<20, not charging) | red | flashing `!` |
| Charging | yellow | arrows moving upward |
| Full, on charger | green | **(assumed)** check mark |

**(assumed)** "Plugged in, charge pending" counts as charging. Clicking opens the power widget.

### Wifi icon

Drawn. **Wifi and Bluetooth icons use the same foreground color as the language and time; color
only appears in accent marks** such as a cross or slash. Icons are scaled down to match the height of
the bar's text (`Theme.layout.statusIconScale`). Number of highlighted bars reflects signal strength.
States:

| State | Drawing |
|---|---|
| Connected | lit bars by signal, unlit bars dim |
| Disconnected | red cross |
| Searching | one bar sweeping outward |
| Connecting | bars filling up |
| Software off | frost slash |
| Hardware off | red slash |
| No internet | yellow `!` |
| Behind firewall / captive portal | orange brick wall |
| Through VPN | green shield badge, on wifi or ethernet |
| Monitor mode | waves on both sides of a purple dot |
| Hotspot **(assumed, from "etc.")** | teal up arrow |
| Ethernet | port icon |
| Ethernet, no internet / firewall / connecting | port icon, same treatment as wifi |

A problem badge takes the place of the VPN shield when both apply.
Priority: monitor, ethernet, hardware off, software off, hotspot, wifi.

### Bluetooth icon

Drawn. A vertical column of dots beside it counts connected devices (draws at most 4).
States: connected, on with nothing connected, searching (dot travels down the column),
connecting or pairing (blink), powering on or off (blink), off (frost slash),
blocked (red slash), no adapter (red cross).

**(assumed)** A device reporting under 20% battery gets a red dot.
**(assumed)** A yellow wave on the left means the laptop is discoverable.

### Language

Shows the current keyboard layout as two letters (EN, AR). Click switches to the next layout.

### Time

`01:03` or `12:30`: 12-hour, zero padded, no AM/PM.

### Workspace selector

Dots only (Astroid removed 2026-11-08; a per-theme accent element is still wanted later). **(assumed)** Wide frost pill for the active workspace, light dot for occupied, dim dot for empty.
Shows 1 through the highest workspace in use. Click to switch.

## Stage 2: power widget (reviewed by Ayman 2026-11-09)

Appears when clicking the battery element. Opens under the bar, at the right.
**(assumed)** Closes on a click outside, on Esc, or on clicking the battery again.
From a keybind: `qs ipc call power toggle`, and `qs ipc call power toggleNight` for night mode.

Requested contents: battery information (charge cycles, life usage; **not** manufacturer, model or
serial, removed on request), system uptime, remaining time at current usage, power usage. Buttons: night
mode, stay-on, power off, reboot, sleep, hibernate, "etc."

Layout (2026-11-09): charge with the battery type small beside it; the gauge, with "battery life used" inside its hatched part; a fixed 2x2 grid of
voltage, current (N/A while charging), cycles, uptime, so the height never changes; brightness and temperature sliders; power profile; buttons.

Night mode transitions the screen temperature gradually and lowers brightness gradually with it.
Power profile labels are Saver, Balanced, Turbo, in equal-width segments.

Decisions:
- Key element: one gauge whose full length is capacity when new. It shows charge, current full
  capacity, and hatched capacity lost to wear.
- "etc." added: lock, log out, and a power profile switch.
- Hibernate, log out, reboot and power off need two clicks. The first arms the button (red, "Power off?"),
  and it disarms after 4 seconds. Lock and sleep take one click.
- Power reading averages the last 10 seconds, because instant readings spike. Time left comes from UPower.
- Battery details are only read while the panel is open (every 2 seconds).
- Night mode uses generated static Hyprland screen shaders, so nothing extra is needed. It fades by swapping to a
  new shader every 100 ms, and removes the shader entirely when the screen is unchanged. A Hyprland config reload
  clears the shader; the button re-reads it when the panel opens.
- Night brightness and temperature, and normal brightness and temperature, are separate settings (Stage 3).
- Sleep and Hibernate lock first and wait 0.4 seconds before suspending, because of the hyprlock hang below.
- Stay on uses a Wayland idle inhibitor. It survives Quickshell restarting (a file in the runtime folder holding the Hyprland session id) and resets on reboot or a new login, on purpose (2026-11-09).
- Hibernate button disables itself and gives the reason logind reports: `no` is "turned off", `na` is
  "needs swap on disk".

## Stage 3: bar sliders and settings (built, awaiting Ayman's review)

Volume is a bar icon that opens a panel of horizontal sliders (2026-11-07); brightness and temperature are in the power panel (2026-11-09). Volume and microphone
share one "audio" panel (the microphone row is always there; its bar icon only while recording). In each row the
dynamic icon is a button: night and normal mode for brightness, mute and unmute for sound and microphone.
**(assumed)** Scrolling on a bar icon changes the value directly. From keybinds: `qs ipc call panel toggle volume`
(`microphone` opens the same panel; `brightness` opens the power panel).

Settings (saved in `settings.json`): idle times, dim level, night schedule, fade length, brightness and temperature
per mode. Now in the Settings app's Display and Power tabs.
**(assumed)** Also added: lid action, and Saver when battery is low.
**(assumed)** Moving the brightness slider saves to whichever mode is on. Brightness keys go through
`qs ipc call brightness up` and `down`, in proportional steps.

`hypridle` is the only idle and lock handler. Its times are in `~/.config/hypr/hypridle-times.conf`, written by the
settings page, which then restarts it. Dimming goes through `qs ipc call brightness dim` and `undim`.

## Stage 4: network and Bluetooth panels (built, awaiting Ayman's review)

Each opens and closes from its bar icon. `controls/` holds shared controls for new panels.

**Network panel:** Wi-Fi switch and refresh. Tabs: Networks (in range; each row opens connect or disconnect, forget,
password, auto-connect, preference), Saved (every saved connection, including out of range), Adapter (addresses,
internet state, auto-connect, hotspot, Ethernet, VPN).
**(assumed)** "Preferred networks" is NetworkManager's autoconnect priority, shown as Preference, 0 to 20.
**(assumed)** Scanning only runs while the panel is open. Passwords never go on a command line. Forget takes two clicks.
Enterprise wifi (WPA-EAP) is not set up here; the row points to nm-connection-editor.

**Bluetooth panel:** power switch and rescan. My devices and Nearby; each row opens pair or connect, forget,
auto-connect (trusted), wake, block. This laptop: visible to others for 3 minutes, accept pairing.
**(assumed)** Discovery and a pairing agent run only while the panel is open. The agent is `bluetoothctl --agent
NoInputNoOutput`, so devices that require a typed or confirmed code cannot pair here yet.

Night schedule times are 24-hour, confirmed. The other masked sleep modes stay masked, confirmed.

## Stage 5: launcher, time panel, notifications (built, awaiting Ayman's review)

**Launcher and time panel:** SUPER toggles both, shown together, a little below the middle of the screen with the
time panel above. Both 500 px wide (the clock side is 150 px, with no separator, 2026-11-09). Launcher has two unlabelled columns, apps (names only, no icons) and commands, sorted by match and
by use. Arrow keys move: up and down in a column, left and right between columns. No Tab. Text after a space is
arguments. Terminal only through a leading `!` (no button, no Ctrl+T, no Ctrl+Enter). The one hint is the input's
placeholder, kept short. Terminal is `kitty`, in `Settings.terminal`. `!` alone is enough, confirmed.
Time panel: analog clock with digital under it, separator, calendar starting on Saturday with month buttons. **(assumed)** Scrolling changes month; clicking the month title returns to now. From a keybind:
`qs ipc call launcher toggle`. `hl.dsp.global("quickshell:launcher")` is the SUPER bind in `hyprland.lua`.

**Notifications:** Quickshell replaces dunst (`notifications/`); `dunst.service` is masked. Popups top right with
action buttons. With one action, a click runs it; with several, each gets a button. Right click dismisses, hover pauses the timer. Sound via `pw-play`,
warning sound for critical, which never times out. **(assumed)** A bell icon opens history with do not disturb and
sound switches. Popup time is in settings. From keybinds: `qs ipc call notifications act`, `dismiss`, `toggleQuiet`.

**Camera:** a red camera (body with a lens ring) appears at the far left of the status group only while a camera is in
use. `bar/camera-watch.py` waits on inotify for `/dev/video*` opens and closes and checks which are still held 0.25 s
later, so it shows within about a second and ignores apps that only list cameras. No polling.

**Microphone:** turns red while any app records from a microphone (a PipeWire link from an audio source into an app's
input stream, `AudioState.micInUse`).

**Hotspot:** its own tab with name, password, visible, band. While on, the bar icon becomes a colored tower and the
panel shows a banner; this is the one status icon allowed to be colored, on request.

**VPN:** its own tab. "Add from file" browses for `.ovpn` and `.conf`; files are copied to `~/.local/share/vpn`
first and imported from there, so they stay when the original is deleted. That folder is the "Imported files" list,
with rename (also renames the VPN made from it) and delete (two clicks; the VPN itself stays until removed) on
hover, latest used first (a file is touched when imported and whenever its VPN connects). VPNs are listed latest
used first too. Imports turn NetworkManager's auto-connect off: it had been starting the VPN at every boot
(2026-11-07). A VPN connects only when asked; the switch in its row can turn auto-connect back on. Filenames are shortened to 15 safe characters, as WireGuard requires.
OpenVPN needs `networkmanager-openvpn`, which is not installed; the tab says so.
WireGuard files are checked for a real private key first: Proton masks it as `*****` when a configuration is
downloaded again after creation, and NetworkManager then fails with "invalid secret 'PrivateKey'".

**Speed:** the network and Bluetooth panels are built 4 seconds after start and kept. Their rows use `ScriptModel`, so updates do not rebuild them, and last time's Wi-Fi list shows dimmed until the scan answers.

**Sound devices:** the audio panel has an output and an input picker under its sliders.

**Bluetooth scan** lasts 20 seconds on open; the refresh button starts and stops it.

## Stage 6: clipboard and themes (built, awaiting Ayman's review)

**Clipboard:** Super+V or `qs ipc call clipboard toggle`; opens in the middle of the screen (no bar icon since
2026-11-07). Enter copies the selected entry, like a click. History with search, text and images, kept across
reboots in `~/.local/share/quickshell/clipboard` (private to the user). Links get a QR button. `clipboard/clip.py` is the
only writer. Entries that apps mark as passwords are never saved; anything else copied, including passwords from apps that do
not mark them, is stored as plain files. **(assumed)** Pinning, 300 entries by default (`clipboardLimit`, no control yet).
`wl-clip-persist` keeps copies alive after their window closes; it must be installed.

**QR codes:** `controls/QrCode.qml`, drawn on a Canvas from `qrencode -t ASCII` (no image file). The hotspot's uses the
`WIFI:` format, so a phone joins directly.

**Automatic events** send notifications (2026-11-07, `notifications/SystemEvents.qml`): joining, switching or losing
a network; VPN up or down; Bluetooth devices connecting or disconnecting; night mode by schedule; battery saver
switching itself; battery at 15% and 7% (7% critical, with sound). Others are quiet (`suppress-sound`). Nothing is
sent for a change made in that thing's own open panel, or in the first 8 seconds after start.

**Bell:** kept, beside the language. Settings > Notifications has do not disturb, sound, popup time and count, and a menu per sender: Show and keep, Show only, Don't show.
An app offering no action is brought forward and the notification dismissed.

## Stage 7: Settings app (rebuilt 2026-11-08, awaiting Ayman's review)

`settings/`: centred, floating, 860 by 680, with a grouped sidebar. Opens with Super+Space, its desktop entry,
`qs ipc call settings open [tab]`, and the Arch logo on the bar.

- **Appearance** (saved per preset, each page says which): Themes, Bar and panels, Windows, Animations.
- **Hyprland** (saved once): Monitors, Input, Keybinds, Window rules, Startup, All options.
- **System**: Display, Power, Network, Bluetooth, Notifications, General.

Choices use dropdowns, not rows of segments. Help text is kept to a minimum on request. The sidebar's Appearance heading names the preset being edited.
**(assumed)** Esc or a click outside closes it; Ctrl+Tab moves between tabs. It takes the keyboard while open.

Dropdowns float over the window; the list is drawn by a layer in `SettingsWindow.qml`, nothing is reparented. Animations has a graph with two draggable handles per curve. Preset cards and the theme switcher use thumbnails
in `~/.cache/quickshell/thumbs` (made by `ThemeManager`, 720 px wide); the wallpaper grid does not.

**Themes tab:** preset cards (click to switch), New preset (copies the active one), Delete (two clicks), then an editor
for the active preset (name, wallpaper grid, colors, font with installed-font suggestions, other apps). Edits apply live.

Passed on to, live unless noted: kitty (the font only if it is monospace); GTK 3 through a generated theme (GTK's own
Adwaita stylesheet with every color mapped onto the palette, in `~/.local/share/themes/Quickshell-A` and `-B`; switching
between the two names is what makes running apps reload); GTK 4 and libadwaita (`gtk-4.0/gtk.css` at app start; light or
dark and the nearest GNOME accent live); font and color scheme through gsettings (font at 11); Qt through qt6ct, qt5ct
and `kdeglobals` (colors, font at 10, icon theme; qt6ct reloads about 3 seconds after its folder changes, so files are
written and renamed into place), monochrome icons (`Quickshell-Icons-A`/`-B`: Adwaita's symbolic icons painted
in the palette, folders in accent, everything else in text color; flipped like the GTK theme, live), btop
(`btop/themes/quickshell.theme`, SIGUSR2 reloads a running btop), the login screen (SDDM, next login), Hyprland (border colors, corners, gaps, border width, unfocused opacity, fade animations,
live; `hypr/theme.lua` at start, which also sets the startup wallpaper), hyprlock (`hypr/hyprlock-colors.conf`).
Originals are in `~/.local/share/quickshell/theme-backup`, including the gsettings values from before.
From scripts: `qs ipc call theme preset <id>`, `qs ipc call theme list`, `qs ipc call theme reapply`.

**Switching speed** (2026-11-08): the screenshot cover was removed on request. Presets apply 40 ms after the change,
Hyprland first; icons and the login wallpaper are only rebuilt when they really changed; wallpaper fades in 0.4 s. Qt apps
still follow about 3 seconds later (qt6ct's own delay).

**Login screen** (`sddm/`): an SDDM theme of our own (Qt 6) laid out like the lock screen, with the preset's wallpaper,
colors and font, a keyboard language indicator (click switches) and drawn sleep, restart and power off buttons.
The greeter cannot read the home folder, so `apply.py` writes the theme, colors and a wallpaper copy into
`/var/lib/quickshell-sddm` (owned by Ayman), which `/usr/share/sddm/themes/quickshell` links to. `sddm/install.sh`
set that up once with sudo (run 2026-11-07), picked the theme, and removed wofi. Its fallback colors are the one other place hex
values are allowed, since the greeter has no Theme. Smoother login: on success the form fades and the dimming
lifts, leaving the wallpaper; Hyprland's background color is the theme's (so not black before the wallpaper) and
the startup wallpaper has no transition. A blink remains at the switch from the greeter's X server to Hyprland.

**Login screen:** the language and a show-password eye sit quietly inside the password field; the user name is highlighted. On Enter it fades to the theme's background
for 340 ms and only then logs in, because the greeter is closed as soon as login succeeds. Hyprland starts on that color and fades the wallpaper in (`awww clear`, then `img`).
**Lock screen:** the language is at the bottom of the screen, muted (a hyprlock label cannot fade with the input field); no show-password, on Ayman's decision.

## Stage 9: Hyprland GUI (built 2026-11-08, awaiting Ayman's review)

`hyprland.lua` is now **generated** (`hyprland/generate.py`) from `hyprland.json` (`hyprland/HyprConfig.qml`). Hand edits to it are
overwritten; Lua of your own goes in `~/.config/hypr/user.lua`, read last. The original is `hyprland.lua.pre-gui`. Every change is checked
with `Hyprland --verify-config` first; if refused, the live file stays and the page shows why. Visual options go through `themes/apply.py`
to `theme.lua` instead, which is only rewritten if `hyprctl eval` accepted them, so a bad value cannot cause Hyprland's error banner.

All options comes from `hyprctl descriptions -j`, so new Hyprland options appear by themselves. `hyprland/schema.js` decides which are hidden,
which are visual, and how each is edited. Hidden on purpose: `debug:*` (it holds `damage_tracking`), continuously animated effects
(water, aurora, ripple and the like, wobble, motion blur), and what the shell controls (screen shader, background and border colors).
Window rule effects are one row each: a dropdown of known effects and a value (`knownEffects` in `RulesPage.qml`). Stored as Lua fields.

## Panels

Panels only fade in and out (2026-11-08, on request, to match windows). Hyprland's layer
fade is off for them (`hl.layer_rule` with `no_anim` in `hyprland.lua`). The gap between panels, from bar to panel and
launcher to time panel, follow the preset: "Gap from the bar" (`panelBarGap`) and the window gap (`Theme.layout.panelGap`); distance
from screen edges is the "around the bar" gap.

While a panel is open it holds the keyboard exclusively, so windows behind it get no keys (Hyprland's own binds still work). The panels
(2026-11-09): network and Bluetooth have one fixed height (`Theme.layout.listPanelHeight`), sound has `soundPanelHeight`, power's content never changes, and notifications and clipboard fit their content. Edits made while a panel is open keep the fade.

Application windows fade back (focused 0.55, others at most 0.4 by default; per preset in Settings > Windows) while any panel is open, through Hyprland's
`decoration` opacity, so its own fade animates it (`ThemeManager.windowsFaded`). Switching workspace closes any open
panel: the launcher used to hand focus back to a window on the old workspace and Hyprland jumped back.

Panels are built on first open and released a minute after closing (`controls/PanelLoader.qml`); `controls/BarPanel.qml` is the one window
they all use. Startup memory went from 387 MB to 195 MB. Opening everything still brings it back up: Qt's heap does not shrink on release.

Bar panels (power, network, Bluetooth, clipboard, notifications) and the notification popups keep one window size,
the screen height under the bar, with input limited to the card (`mask: Region`). Only the card's height changes,
animated and clipped (2026-11-06): resizing the window itself looked like one panel replacing another.
No hint lines at the bottom of panels (removed on request).

## Stage 8: Notes (extended 2026-11-09, awaiting Ayman's review)

`notes/NotesPanel.qml`, `notes/NoteEditor.qml`, `notes/NoteTable.qml`. Super+I (`qs ipc call notes toggle`) fades in at the right, 530 px wide. Independent of `Panels`: it stays
open beside other panels and does not fade windows or close on outside clicks, so files can be dragged from other windows. Esc closes it. The writable area is a raised sheet, apart from the tab and style bars.

A Markdown editor that shows the styles as you type. Files live in `~/Notes` (`.md`, `.txt`), saved 400 ms after typing, on tab switch and on close. Tabs persist.
Buttons: new, open, rename, delete (two clicks, to the trash), help. A second row inserts Markdown; inside a table it holds + Row, + Column, - Row, - Column instead. Every style has a key, listed under help.

Styling is character formats laid over the plain Markdown (`TextEdit.cursorSelection`, "Live styling" in `NoteEditor.qml`), so the file is unchanged by it. Markers shrink away
except on the line being edited, where they show dimmed; a table being edited shows raw as a whole. Emphasis nests in any order (`inlineMasks`). Undo is our own: text snapshots, Ctrl+Z, Ctrl+Y or Ctrl+Shift+Z.

**Drawn over the text** (`updateLayout`, positions read back from the laid-out text): rendered tables (borders, shaded title row, own sideways scroll; source rows hidden, first character sized to keep the row height), check boxes (click toggles; checked text is muted), rules, images in fixed-height strips. Behind the text at negative z: quote blocks and the current-line highlight. Quote indents are real block margins, which can only be set by reloading the document (`rebuild`), done only when a line's quote state changes.
**(assumed)** Shift+Tab cycles tabs except in a table, where it is the previous column. Ctrl+Enter in a table adds the line under the table. Enter on an empty list item ends the list. Table actions: Ctrl+Alt+R/C add, with Shift delete; the header and rule rows cannot be deleted. Dropped non-image files add their path (no longer open as tabs, on request).
Line numbers are logical lines, absolute or relative. Wrap is Alt+Z, remembered. Unwrapped makes the text as wide as its longest line inside the scroller. Settings > General > Notes: browser for links (empty is the system default), line numbers, image handling per wrap mode, fixed height.

Spaces only: Tab inserts four. Alt+Left/Right indent, Alt+Up/Down move lines, Ctrl+L selects the line, Ctrl+Shift+Up/Down add cursors (Esc or a click removes them).
The caret is drawn by us from `cursorRectangle`: it glides and fades fully out.

Images: on disk `![](images/x.png)`, copied to `~/Notes/images`; shown inline by loading the text as rich text. The text is rebuilt from `getText` (images are U+FFFC, in
document order against the `<img>` tags in `text`). Rich text returns U+2029 for line breaks; `plain()` maps them to `\n` one for one. Inline insertions need `inlineHtml`
(pre-wrap), or the HTML reader collapses spaces.

## Startup

The bar must appear quickly even if login happens while the system is still booting. `Bar.qml` only draws the
empty bar; everything else is in `BarContents.qml`, loaded in the background, and fades in when ready.

## Technical notes

- `Hyprland --verify-config -c FILE` prints "config ok" and exits 0 either way: check the text, not the code.
- `component` declarations for `Space` and control sizes in `ThemeSpec.qml` failed with "X is not a type". As their own files they work.
- A signal named `closed` on a `PanelWindow` subclass is a duplicate: the window has one. `BarPanel` uses `panelOpened`, `panelClosed`.
- Killing Quickshell with SIGKILL orphans `wl-clip-persist` and friends; several then fight over the clipboard and starve the new shell, which
  looks like a hang. When restarting by hand, kill those too.
- Singletons exist only once something refers to them. One that holds a `GlobalShortcut` or `IpcHandler` must be referenced from always-loaded code
  (`BarContents.qml`). Building panels on demand silently killed the launcher's Super shortcut this way.
- Fading a color from `"transparent"` passes through black, which looked like a double hover. Use `Theme.colors.clear`.
- Never disable a button that repeats while held: its `pressed` change is lost and the timer keeps firing.
- A brand-new QML file can be "not a type" until Quickshell fully restarts.
- A `Grid` with more `columns` than items adds one trailing `columnSpacing` to its width: this was the extra space around the battery. `BarGroup` uses its visible child count.
- Nested `Grid`s keep stale sizes when `columns` changes live; `Bar.qml` rebuilds its contents when the direction changes.
- The Write tool can turn `\u2029`-style escapes into real characters; check generated QML with Python, as with heredocs.
- A child with negative `z` draws behind its parent `TextEdit`'s text; that is how note backgrounds work.
- A process started by `Process` outlives a killed Quickshell. Anything holding a lock is started through `setpriv --pdeathsig TERM`.
- Never bind an item's `parent` to `QsWindow.contentItem` (or anything that changes with the window). Making a panel window visible reparents its content;
  the binding then reparents inside that call and Quickshell segfaults in `QQuickItem::setParentItem` (crash of 2026-11-08, `~/.cache/quickshell/crashes`).
  Hyprland went down 6 seconds later, as the dying shell's core dump finished, and left no report or core: cause not proven.
- A heredoc through the shell tool can turn `\u2029` into the real character, and QML then fails with "Unterminated regular expression class". Check with Python.
- `String.matchAll` does not exist in QML's JavaScript.
- A Behavior on a cursor delegate's x or y does nothing: the TextEdit sets them from C++. Draw the caret yourself from `cursorRectangle`.
- Native-rendered text under `scale` shows uneven gaps between letters. Scale the picture, not the label.
- A `Behavior on y` on something placed from its own height animates in from the top when the panel is built.
- `tightBoundingRect` is one pixel taller than the glyph.
- `hyprctl eval` takes several statements at once, one per line; one eval is how a whole preset is applied.

- Wifi security enum has more values than it first appears: `Wpa2Psk` and `Wpa2Eap` too. Missing `Wpa2Psk` once made
  ordinary networks look unsupported.
- `Quickshell.iconPath(name, true)` returns "" for a missing icon, but `notification.image` can be a raw
  `image://icon/` path that shows a magenta placeholder. `NotificationCard.resolveIcon` handles this.
- nmcli: passwords go through `nmcli connection edit` on stdin or `passwd-file`, never argv. Clear a hotspot channel
  with `802-11-wireless.channel ""`; `0` is rejected.

- Quickshell's wifi network list only holds the connected network unless `scannerEnabled` is on, and never holds
  saved networks out of range. `Networking` also fills in slowly: read it from the start, not on first use.

- Sleep freeze, 2026-11-05: the kernel suspended and resumed fine. `hyprlock` was started at the same
  instant, accepted the password, then never unlocked. If it recurs, check `journalctl -b -g hyprlock`.
- Reading suspend logs: journal wall-clock times include the time asleep, so a gap can just be sleep. Use
  `journalctl -k -o short-monotonic` to measure real kernel time; it stops during sleep.
- `hyprpolkitagent` segfaults when the compositor goes away, which is harmless. The panel's log out, reboot and power off stop it first.
- Hyprland's `key_press_enables_dpms` and `mouse_move_enables_dpms` are on, so any input wakes the screen even if
  hypridle misses it. A wake on 2026-11-05 stayed black because the input never reached hypridle.
  `hypr/after-sleep.sh` nudges the cursor after each wake, so a stalled lock screen redraws.
- A QML binding on a value that an animation also changes jumps straight to the end. Set the start value in
  `Component.onCompleted` instead (`NightMode.level`).
- Known limit, accepted 2026-11-05: every sleep and hibernate still switches console ("Disabling seat" in Hyprland's
  log), with a suspend stall of about 3 seconds, some flicker and delayed input on wake. Patching the two
  `pm_vt_switch_required` calls in NVIDIA's source did not stop it and was removed; something built into the kernel
  also seems to require the switch. Cause not proven: a logger in `/tmp` was lost to a reboot. Do not retry the patch.
- Keep diagnostics that must survive a reboot out of `/tmp`; it is wiped at every reboot.
- "Broadcast message ... will shutdown now" is systemd's wall message, not a log. The panel's Reboot and Power off
  pass `--no-wall`; typing `reboot` in a terminal still shows it.
- Do not cap `docker.service` stop time: killing dockerd leaves containers behind and slows shutdown further.

- Boot and shutdown, 2026-11-05 (`fix-boot.sh`, backups in `/root/boot-fix-backup-*`): NVIDIA is out of the
  initramfs, because it refused the freeze that resume needs ("Failed to load image"). `console=tty9` hides console
  text, so a failed boot shows on Ctrl+Alt+F9. Only NetworkManager and wpa_supplicant run the wifi; systemd-networkd
  and iwd are off.
- Ayman does not want Frappe and other services starting at boot: docker, mariadb, httpd, xinetd, slapd and
  libvirtd are disabled. Docker and libvirt still start on demand through their sockets.
- Hyprland treats an unknown `hl.dsp.dpms` action as a toggle. Only use `on` and `off`.
- Idle lives in `hypr/hypridle.conf`, started only by its systemd user service: dim at 1 min, screen off at 2, lock
  at 2:05, suspend at 10. The lid bind in `hyprland.lua` locks, waits 0.4 seconds, then suspends.
- Hibernate setup, 2026-11-05: `/swap/swapfile` (32G, btrfs subvolume, below zram in priority), `resume=` and
  `resume_offset=` in the boot entry, `resume` hook in mkinitcpio. `hibernate.target` was masked since Apr 20,
  which makes logind answer `no` whatever the swap setup. Backups are in `/root/hibernate-backup-*`.
- Never use Hyprland's `time` uniform in a screen shader: it needs `debug:damage_tracking` off. Hyprland shows
  that as a black, red-bordered error banner that reserves space, pushing the bar and windows down. It stays
  until `hyprctl seterror disable`. A red strip at the top of a screenshot is this banner, not the bar.
- Hyprland 0.57 uses a Lua config: `hyprctl dispatch workspace 2` fails with a Lua error.
  Dispatches must be Lua, e.g. `hl.dsp.focus({ workspace = 2 })`.
- Do not name QML properties `on` + capital letter (`onBattery`): QML reads them as signal handlers
  and the value silently comes out wrong.
- On a `Part`, avoid `status`, `active`, `source`, `item`, `progress`: `Loader` already has them.
- `Array.flat` does not exist in QML's JavaScript. Named inline components can fail when nested;
  use a file instead.
- Quickshell.Networking does not expose VPN or monitor mode. `bar/NetworkIndicator.qml` probes for them
  when `ip monitor link` or `nmcli monitor` reports a change. It does not poll.
- NetworkManager does not report scanning, so "searching" means the 20 seconds after losing a link
  or enabling the radio. After that it shows disconnected.
- Reloads triggered mid-write can log "X is not a type". Check the last entries of `qs log`.
- `grim` screenshots do not show the Hyprland screen shader, so night mode can't be checked that way.
- Brightness goes through `brightnessctl`, which works without root here.
- `sed -i` replaces the file, so Quickshell's watcher misses it and no reload happens. `touch` to force one.
- Files in `power/` need `import ".."` to see `Theme`.
- `GlobalShortcut` needs `import Quickshell.Hyprland`.
- `Behavior on` a `readonly` property fails ("read-only property"); the whole file then fails to load.
- Quickshell's `ClippingRectangle` (Quickshell.Widgets) has no `border`; draw a transparent `Rectangle` over it.
- Hyprland settings change live through `hyprctl eval 'hl.config({...})'`, and `hl.animation({...})` works there too.
- `hl.dsp.cursor.move` warps the cursor but sends no motion to apps, so hover can't be tested that way.
- GTK 3 reads `~/.config/gtk-3.0/gtk.css` only at start, and it overrides the theme, so it is left empty. Adwaita in GTK 3
  uses fixed colors, so `@define-color` alone changes almost nothing; that is why the theme is regenerated.
- `qs ipc call <target> show` is parsed as qs's own `show` command: never name an IPC function `show`.
- A `Process.environment` bound to a property can be stale inside that property's change handler; assign it there instead.
  This was the blank QR code.
- `Stay on` (2026-11-08): holds two locks, the bar's Wayland inhibitor and a logind idle inhibitor (`systemd-inhibit --what=idle`,
  which hypridle honors). Each change goes to `journalctl -t quickshell-stay-on`. It resets when Quickshell restarts. On a
  dying battery, UPower still suspends at its critical level (seen 2026-11-06).
- Inside a `Connections`, `parent` is not the enclosing item; use an id.
- `TextInput.accepted` did not always arrive on Enter (Wayland text-input in between); `controls/TextField.qml`
  reads Return and Enter as keys and emits `accepted` and `finished`.
- A `HoverHandler` keeps reporting hover over child buttons; a `MouseArea`'s `containsMouse` may not.
- Testing a GTK app by launching it reuses an already open window of it (Thunar): never kill it by name. Check icon
  names with `gio info -a standard::icon FILE` instead.
- Hyprland background color in Lua: `misc = { background_color = "rgb(171b2b)" }`.
