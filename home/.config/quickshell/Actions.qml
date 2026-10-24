// Things the HUD launches.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string ropes: home + "/.local/bin/ropes"

    // A floating kitty (niri floats the "ropes" app id) that waits before closing.
    function dialog(script) {
        Quickshell.execDetached(["kitty", "--class", "ropes", "-e", "sh", "-c",
            script + '; printf "\\nPress any key to close"; read -rsn1 _']);
    }

    function terminal(dir) {
        Quickshell.execDetached({ command: ["kitty"], workingDirectory: dir || home });
    }
    function logout() { Quickshell.execDetached([ropes, "logout"]); }
    function network() { Quickshell.execDetached(["kitty", "--class", "ropes", "-e", "nmtui"]); }
    function mixer() { Quickshell.execDetached(["pavucontrol"]); }
    function systemMonitor() { Quickshell.execDetached(["kitty", "-e", "btop"]); }
    function update() { dialog('"' + ropes + '" update'); }
    function modePicker() {
        Quickshell.execDetached(["kitty", "--class", "ropes", "-e", ropes, "mode"]);
    }
}
