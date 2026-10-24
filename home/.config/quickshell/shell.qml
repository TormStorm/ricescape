//@ pragma IconTheme Papirus-Dark
// Ricescape — Quickshell entry point.
//
// Three OSRS-style HUD panels hide against the screen edges:
//   top-right     MinimapPanel  clock, workspace, CPU/RAM/GPU/volume orbs
//   bottom-left   ChatPanel     console + status bar
//   bottom-right  SidePanel     inventory (all apps) + stone tabs (favourites)
//
// Keybinds talk to it over IPC, e.g.:
//   quickshell ipc call hud toggle chat|inventory|minimap
//   quickshell ipc call hud pin chat|inventory|minimap|all
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/ricescape"

    Component.onCompleted: Theme.user = Quickshell.env("USER") || "Adventurer"

    // Palette written by `ropes mode`; re-read whenever it changes.
    FileView {
        path: root.stateDir + "/palette.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: Theme.apply(text())
    }

    // The current mode's icon sprite.
    FileView {
        path: Theme.iconPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: Theme.setIcon(text())
    }

    IpcHandler {
        target: "hud"

        function toggle(panel: string): void { Hud.toggle(panel, Niri.focusedOutput); }
        function pin(panel: string): void { Hud.togglePin(panel); }
        function close(): void { Hud.release(); }
    }

    Variants {
        model: Quickshell.screens
        MinimapPanel {}
    }
    Variants {
        model: Quickshell.screens
        ChatPanel {}
    }
    Variants {
        model: Quickshell.screens
        SidePanel {}
    }
}
