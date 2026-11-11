# Ayman's desktop: full setup record

Everything built for this desktop, and every change made to the system around it, so it can be understood,
rebuilt or undone. Decisions and rules are in `CLAUDE.md`; open items are in `todo.txt`. Last updated 2026-11-10.

Machine: Arch Linux laptop "Ay-lap", NVIDIA, 1920×1080 screen `eDP-1`, btrfs. Desktop: Hyprland 0.57 (Lua config)
with a Quickshell 0.3.2 shell. Login through SDDM.

## 1. Packages the setup relies on

| Package | Used for |
|---|---|
| hyprland | compositor, `~/.config/hypr/hyprland.lua` |
| quickshell | bar, panels, launcher, notifications, Settings app |
| awww | wallpaper daemon (`awww img`) |
| hypridle, hyprlock | idle times, lock screen |
| sddm (+ `sddm-greeter-qt6`) | login screen |
| networkmanager, bluez, upower, power-profiles-daemon | read and controlled by the panels |
| pipewire, wireplumber | sound; `pw-play` plays notification sounds |
| brightnessctl | brightness, without root |
| wl-clipboard, wl-clip-persist | clipboard history, copies that outlive their window |
| qrencode | QR codes (clipboard links, hotspot) |
| libnotify (`notify-send`) | system event notifications |
| qt6ct, qt5ct | Qt apps follow the theme |
| networkmanager-openvpn | OpenVPN imports (WireGuard needs nothing extra) |
| kitty | terminal (`Settings.terminal`) |
| flameshot, hyprshot | screenshots (Print keys) |

Removed: **dunst** (replaced by Quickshell's notifications; its user service is masked), **wofi** (2026-11-07).

## 2. Quickshell (`~/.config/quickshell`)

`shell.qml` starts the bar (`Bar.qml`) and notification popups. `Bar.qml` draws the empty bar at once and loads
`BarContents.qml` in the background, so the bar appears even during a slow boot.

| Folder or file | What it holds |
|---|---|
| `Theme.qml`, `themes/` | What widgets read: `ThemeSpec.qml` (every themable value), `RuntimeTheme.qml` (fills it from the preset), `palettes.js` (palettes and wallpaper color math), `apply.py` (passes the look to other apps) |
| `ThemePresets.qml`, `presets.json` | Theme presets built in Settings > Themes |
| `Settings.qml`, `settings.json` | All saved settings |
| `Label.qml` | All text in the shell |
| `DESIGN.md` | The design language |
| `hyprland/`, `hyprland.json` | The Hyprland GUI: model, schema, Lua generator |
| `Panels.qml` | Which panel is open (one at a time, Notes included); keeps them open across workspace switches; the close key's `closePanel` |
| `Part.qml`, `parts/` | Swappable drawn elements (icons, clock, workspace marker...) |
| `bar/` | Bar widgets: workspaces, clock, language, battery, network, Bluetooth, sliders, camera, notifications |
| `power/` | Power panel, brightness, night mode (screen shaders), power profiles |
| `network/` | Network panel, hotspot, VPN import |
| `bluetooth/` | Bluetooth panel |
| `launcher/` | Launcher and time panel (Super) |
| `tasks/` | Tasks per day, opened from the time panel's calendar; `TaskStore` sends their reminders |
| `notifications/` | Notification server, popups, history panel, `SystemEvents.qml` (notifications for automatic events) |
| `clipboard/` | Clipboard history (`clip.py` is the only writer) |
| `theming/` | Theme manager, theme switcher panel (Super+T) |
| `notes/` | Notes panel (Super+I), Markdown editor with search; files in `~/Notes` |
| `timer/` | Stopwatch and timers, opened from the time panel's clock; `timers.json` |
| `settings/` | Settings app (Super+Space) |
| `controls/` | Shared controls, and `BarPanel` and `PanelLoader` |
| `sddm/` | The login screen theme source and its one-time root `install.sh` |

### What each part does (short)

- **Bar** (32 px, floating): workspaces left, time centre; right side reads right to left: battery | Wi-Fi,
  Bluetooth | brightness, volume, microphone (only while recording, red), camera (only while in use, red) |
  bell, language. Icons are drawn on Canvas, one unit per pixel, on whole pixels.
- **Panels** under the bar: power (battery gauge, uptime, night mode, stay on, power actions, profiles),
  brightness slider, audio (volume and microphone sliders in one panel), network (Wi-Fi, saved, adapter, hotspot,
  VPN), Bluetooth, notifications history. Windows fade back while any panel is open.
- **Clipboard**: Super+V, opens in the middle of the screen; history with search, pins, images, QR for links.
- **Launcher**: Super alone; apps and commands, `!` runs in a terminal; time panel above with a calendar. Clicking a day shows its tasks in the launcher's place, with reminders.
  Clicking the clock shows the stopwatch (runs, laps, history) and timers (a length or a time of day, ringing with a notification) there instead; the clock marks both.
- **Notifications**: popups top right, sounds, do not disturb; also sent by the system itself for network joins
  and switches, VPN up or down, Bluetooth devices, scheduled night mode, automatic battery saver, low battery.
- **Notes**: Super+I, fades in at the right like any panel; tabs of Markdown files in `~/Notes`, styles shown as you type, images by Ctrl+V, search (Ctrl+F).
- **Settings app**: Super+Space; Appearance (Themes, Bar and panels, Windows, Animations), Hyprland (Monitors, Input, Keybinds, Window rules, Startup, All options), System (Display, Power, Network, Bluetooth, Notifications, General).
- **Themes**: presets (wallpaper, colors from palette, wallpaper or custom, font, corners, gaps, window look).
  Super+T slides up a searchable row of presets.

## 3. Files outside Quickshell's folder that this setup writes

Written on every theme change by `themes/apply.py` (originals kept once in
`~/.local/share/quickshell/theme-backup`, including the gsettings values from before):

| File | Purpose |
|---|---|
| `~/.config/kitty/current-theme.conf` and related | Kitty colors and font |
| `~/.local/share/themes/Quickshell-A`, `-B` | GTK 3 theme: Adwaita recolored; the name flips to reload apps live |
| `~/.config/gtk-4.0/gtk.css` | GTK 4 and libadwaita colors (at app start) |
| `~/.config/gtk-3.0/gtk.css` | Kept empty on purpose (it would override the theme) |
| `~/.local/share/icons/Quickshell-Icons-A`, `-B` | Monochrome file, folder and device icons from Adwaita's symbolic set, in theme colors |
| gsettings `org.gnome.desktop.interface` | `gtk-theme`, `icon-theme`, `color-scheme`, `accent-color`, `font-name` |
| `~/.config/qt6ct/`, `~/.config/qt5ct/`, `~/.config/kdeglobals` | Qt colors, font, icon theme |
| `~/.config/btop/themes/quickshell.theme`, `btop.conf` (`color_theme`) | btop colors; a running btop reloads on SIGUSR2 |
| `~/.config/hypr/theme.lua` | Every visual Hyprland option, curves, animations, cursor, background color, startup wallpaper |
| `~/.config/hypr/hyprlock-colors.conf` | Lock screen colors |
| `/var/lib/quickshell-sddm/` | Login screen theme, colors (`theme.conf`) and a copy of the wallpaper (the preset's login wallpaper if it has one) |

Other user files:

| File | Purpose |
|---|---|
| `~/.config/hypr/hyprland.lua` | **Generated** from `hyprland.json` by Settings > Hyprland; reads `theme.lua`, then `user.lua`. Your original is `hyprland.lua.pre-gui` |
| `~/.config/hypr/user.lua` | Optional, yours: Lua the GUI cannot express, read last |
| `~/.config/hypr/hypridle.conf`, `hypridle-times.conf` | Idle: dim, screen off, lock, suspend (times from Settings) |
| `~/.config/hypr/hyprlock.conf` | Lock screen layout, including the keyboard language under the password field |
| `~/.config/hypr/after-sleep.sh` | Nudges the cursor after wake so a stalled lock screen redraws |
| `~/.local/share/applications/quickshell-settings.desktop` | Settings app entry |
| `~/.local/share/quickshell/clipboard/` | Clipboard history (private, 700) |
| `~/.local/share/quickshell/tasks.json` | Tasks and their reminders |
| `~/.local/share/quickshell/timers.json` | Stopwatch runs, laps and history; timers |
| `~/.local/share/vpn/` | Imported VPN files (700); they stay when the original is deleted |
| `$XDG_RUNTIME_DIR/quickshell-night` | Night mode shaders (wiped at reboot) |

## 4. System changes (root)

| Change | Where | Why | Undo |
|---|---|---|---|
| NVIDIA out of the initramfs; `console=tty9`; quiet boot flags | mkinitcpio, boot entry (`fix-boot.sh`, 2026-11-05; backups `/root/boot-fix-backup-*`) | NVIDIA refused the freeze resume needs; hide console text | restore from backups |
| Hibernate: `/swap/swapfile` 32G (btrfs subvolume, below zram), `resume=` and `resume_offset=`, `resume` hook; `hibernate.target` unmasked | boot entry, mkinitcpio, systemd (backups `/root/hibernate-backup-*`) | Hibernate button | restore backups, remove swapfile |
| Only NetworkManager and wpa_supplicant run Wi-Fi: `systemd-networkd` disabled, `iwd` masked | systemd | Conflicting network managers | `systemctl enable` / `unmask` |
| docker, mariadb, httpd, xinetd, slapd, libvirtd not started at boot (docker and libvirt start on demand through sockets) | systemd | Faster boot, on request | `systemctl enable` |
| dunst user service masked | systemd user | Quickshell owns notifications | `systemctl --user unmask dunst` |
| SDDM theme `quickshell`: `/var/lib/quickshell-sddm` (owned by ayman), link `/usr/share/sddm/themes/quickshell`, `/etc/sddm.conf.d/theme.conf` → `Current=quickshell` | `sddm/install.sh` (2026-11-07; old conf in `/root/sddm-backup`) | Login screen follows the theme | `sudo sh install.sh --undo` |
| wofi removed | pacman (`sddm/install.sh`) | On request | `sudo pacman -S wofi` |

NetworkManager connection changes made from the panels (priorities, auto-connect) live in NetworkManager itself.
On 2026-11-07 the imported WireGuard VPN `JVPN2-JP-FREE-9` had auto-connect turned off: NetworkManager had been
starting it at every boot.

## 5. Keybinds

| Keys | Action |
|---|---|
| Super (alone) | Launcher and time panel |
| Super+V | Clipboard history |
| Super+I | Notes |
| Super+Space | Settings |
| Super+T | Theme switcher |
| Super+Q / F / P / J | Close window (or the open panel) / float / pseudo / split. While a panel is open, F, P, J do nothing |
| Super+1..0, Super+Shift+1..0 | Go to / move window to workspace (moving does nothing while a panel is open) |
| Super+arrows, Super+Shift+S | Focus a window / move it to the special workspace (both nothing while a panel is open) |
| Super+S, Super+Shift+S | Special workspace |
| Super+L | Lock |
| Super+M | Exit Hyprland |
| Super+R | Reload Hyprland |
| Print, Shift+Print, Alt+Print | flameshot gui, hyprshot window, flameshot full to clipboard |
| Brightness keys | `qs ipc call brightness up/down` |
| Volume and mic keys | wpctl |
| Lid closed | `qs ipc call power lid` (lock, then the lid action) |
| Caps Lock | Switch keyboard layout (us, ara) |

## 6. Scripting (`qs ipc call ...`)

`panel toggle <volume|microphone|brightness|...>`, `power toggle`, `power toggleNight`, `launcher toggle`,
`clipboard toggle`, `settings open <tab>`, `settings toggle`, `theme preset <id>`, `theme list`, `theme reapply`,
`theme panel`, `notes toggle`, `power stayOn true|false`, `notifications act|dismiss|toggleQuiet`, `brightness up|down|dim|undim`.

## 7. History

- **2026-11-09**: bar icons 3:2 to the text, regrouped; brightness and temperature sliders in the power panel; Notes shows styles live, smooth caret, table keys; flameshot closes panels and goes fullscreen; notification buttons for every action when there are several; refresh buttons confirm with a check. Backup: `~/.local/share/quickshell/backups/pre-round5-2026-11-09.tar.gz`.

- **2026-11-08, night**: panels fade; bar on any edge; dropdowns throughout Settings; three fonts; rules per notification sender; looping theme switcher; Notes rewritten as a Markdown editor
  without vim keys; network and Bluetooth panels prebuilt; sound device pickers; login fades out into Hyprland; playerctl media binds removed. Backup: `~/.local/share/quickshell/backups/pre-round4-2026-11-08.tar.gz`.

- **2026-11-08, crash fix**: floating dropdown no longer reparents (cause of the Quickshell segfault); bar icons as tall as the digits; bar text centred on its digits.

- **2026-11-08, last**: Arch logo opens Settings, gears removed; bar position; bar text separate, icons scale and match in height; panels hold the keyboard and
  have a fixed height; curve graphs; preset thumbnails in `~/.cache/quickshell/thumbs`; language in the login and lock fields, show-password at login.

- **2026-11-08, later**: `DESIGN.md`; foundation rebuilt (tokens for type, space and size; `Label`; `InteractiveSurface`; `BarPanel`; panels built on
  demand); every visual setting moved into presets; `hyprland.lua` generated from a GUI; Settings rebuilt with a grouped sidebar. Backup of everything from
  before: `~/.local/share/quickshell/backups/pre-polish-2026-11-08.tar.gz`.

- **2026-11-05**: Stage 1 bar; Stage 2 power widget; boot and hibernate fixes; Stage 3 sliders and settings;
  Stage 4 network and Bluetooth panels.
- **2026-11-06**: Stage 5 launcher, time panel, notifications (dunst replaced), hotspot, VPN; Stage 6 clipboard and
  theme presets; Stage 7 Settings app and theme wheel. Refinements: 32 px bar, sharp icons, spacing, smooth panel
  resizing, faster camera indicator, mic warning, QR codes, Super+T hover-and-release, GTK and Qt apps live.
- **2026-11-07**: VPN import checks for Proton's hidden key; clipboard Enter fixed; bar right side regrouped
  (clipboard icon removed, audio sliders combined and horizontal, mic only while recording, bell beside language);
  windows fade while a panel is open; panels close on workspace switch; VPN auto-connect off, rename and delete for
  imported files, latest used first; system event notifications; keyboard language on the lock screen; monochrome
  themed icons; btop themed; screenshot cover hides Qt's reload delay; SDDM theme and smoother login start; wofi
  removed.
- **2026-11-08**: clipboard row flicker and blank QR codes fixed; Notes panel; Windows tab with all Hyprland look settings;
  Settings moved to Super+Space, float to Super+F, launcher gear removed; screenshot cover removed, faster theme switching;
  bottom theme switcher with search; Stay on given a second lock and a log; panels only slide, with gaps from Settings.

## 2026-11-09, round 6

Backup before it: `~/.local/share/quickshell/backups/pre-round6-2026-11-09.tar.gz`. Bar icons 4:3, wire speaker, bar direction rebuild, group width fix, one battery symbol slot, power facts in a grid. Stay on kept in `$XDG_RUNTIME_DIR/quickshell-stay-on`, its inhibitor tied to the shell with `setpriv` (util-linux). Notes extended, new `notes/NoteTable.qml`, new settings `notesWrap`, `notesLineNumbers`, `notesImagesWrapped`, `notesImagesUnwrapped`, `notesImageHeight`, `browser`.

## 2026-11-10, round 7

Before it: git commit `aa84f95` (`git diff aa84f95` shows everything; `presets.json` and `settings.json` were already changed). Bar icon size separate from
bar text (`barIconSize`), bar text in whole-pixel boxes (`BarText.qml`); charging arrow heads; Lucide-style reboot and refresh glyph; power grid spacing; audio
panel without reserved room, floating device lists (`BarPanel.popupOwner`); Super+Q closes panels (the close bind in `hyprland.lua` is now a Lua function);
panels stay open across workspace switches; Notes became an ordinary panel without drag and drop, with search, Ctrl+F2, its own scrolling
(`notes/AutoScrollBar.qml`) and help listing its settings; login screen fades from and to black, Hyprland starts on black (`misc:background_color`),
separate login wallpaper per preset (`loginWallpaper`, `settings/WallpaperGrid.qml`); time panel separator; tasks (`tasks/`, `tasks.json`).

## 2026-11-11, round 8

Before it: git commit `aa84f95` plus the uncommitted round 7. Outline Arch logo, bar icons in 1 px steps; the bar has its own font, weight, corners
and border, and a gap per side (`barGapEdge`, `barGapInner`, `barGapStart`, `barGapEnd`; `barGap` is migrated by `ThemePresets.migrate`); panels have
their own font and gaps per side or follow the windows' (`panelGapSide`, `panelGapFar`, `panelGapBetween`, `panelGapsFollow`); bar and panel motion
(duration, curve, fade, slide; `controls/PanelShow.qml`, `settings/MotionRows.qml`). Settings: cursor moved to Themes, Bar and panels in two sections.
Window controls (float, pseudo, split, focus, move window) are wrapped in `quickshell_guard` in `hyprland.lua`. Notes wrap toggle in one frame.
Stopwatch and timers (`timer/`, `timers.json`), wider clock with stopwatch arcs and timer hands. `TaskStore` and `TimerStore` write synchronously.

## 2026-11-11, round 9

Before it: rounds 7 and 8 uncommitted on `aa84f95`. 24-hour bar time and clocks (24-hour analog dial); stopwatch drawn as tinted wedges with laps on the
rim, one timer hand; timers picked with steppers (`timer/TimeWheel.qml`; typed parsing removed from `TimerStore`, `addAt` added). Accent element per preset
(`accentMark`; `parts/accent/shapes.js`, `controls/AccentMark.qml`) on the workspaces, calendar and clock; calendar shows up to five marks and a plus. Icon
style per preset (`iconStyle`: thin, thick, filled) in every drawn icon. Arch logo on the icon grid. Notes: quote blocks no longer flash to full width while
typing unwrapped (`updateLayout` reads the current text). Settings > Themes has an Icons section.
