#!/bin/sh
# One-time setup for the Quickshell login screen and a smoother login. Run with: sudo sh install.sh
# Undo: sudo sh install.sh --undo
set -e
USER_NAME=${SUDO_USER:-ayman}
DIR=/var/lib/quickshell-sddm
LINK=/usr/share/sddm/themes/quickshell
CONF=/etc/sddm.conf.d/theme.conf
BACKUP=/root/sddm-backup

if [ "$1" = "--undo" ]; then
    [ -f "$BACKUP/theme.conf" ] && cp "$BACKUP/theme.conf" "$CONF"
    rm -f "$LINK"
    echo "SDDM theme restored from $BACKUP. $DIR was left in place."
    exit 0
fi

# 1. The theme folder: owned by $USER_NAME so Quickshell can update colors and wallpaper with each preset change,
#    readable by the sddm user. SDDM loads it through a link in its themes folder.
mkdir -p "$DIR"
chown "$USER_NAME:$USER_NAME" "$DIR"
chmod 755 "$DIR"
[ -e "$LINK" ] || ln -s "$DIR" "$LINK"

# 2. Pick it, keeping the old setting.
mkdir -p "$BACKUP" /etc/sddm.conf.d
[ -f "$CONF" ] && [ ! -f "$BACKUP/theme.conf" ] && cp "$CONF" "$BACKUP/theme.conf"
cat > "$CONF" <<CONF
[Theme]
Current=quickshell
CONF

# 3. Remove wofi (its keybind is already gone from hyprland.lua).
if pacman -Q wofi >/dev/null 2>&1; then
    pacman -Rns --noconfirm wofi
fi

echo "Done. Next, as $USER_NAME (no sudo): qs ipc call theme reapply"
