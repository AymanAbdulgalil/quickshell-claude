//@ pragma NativeTextRendering
import Quickshell
import "notifications"

ShellRoot {
    Bar {}

    // Loaded with the shell, not in the background: it must own notifications from the start.
    NotificationPopups {}
}
