// Ricescape — Quickshell entry point.
// Starter HUD: stone bar with worlds, mode badge, orbs and minimap clock.
import Quickshell
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
