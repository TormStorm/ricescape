// Which HUD panels are open, pinned, or holding the keyboard.
// Panels open on hover by themselves; this covers keybinds and pins.
pragma Singleton

import QtQuick

QtObject {
    id: root

    // Opened from a keybind: the panel stays open and takes the keyboard.
    property bool chatGrab: false
    property bool inventoryGrab: false
    property string grabScreen: ""

    // Pinned panels stay open until unpinned.
    property bool chatPinned: false
    property bool inventoryPinned: false
    property bool minimapPinned: false

    function isGrabScreen(name) {
        return grabScreen === "" || grabScreen === name;
    }

    function toggle(panel, screenName) {
        grabScreen = screenName || "";
        switch (panel) {
        case "chat":
            chatGrab = !chatGrab;
            inventoryGrab = false;
            break;
        case "inventory":
            inventoryGrab = !inventoryGrab;
            chatGrab = false;
            break;
        case "minimap":
            minimapPinned = !minimapPinned;
            break;
        default:
            console.warn("ricescape: unknown panel", panel);
        }
    }

    function togglePin(panel) {
        switch (panel) {
        case "chat": chatPinned = !chatPinned; break;
        case "inventory": inventoryPinned = !inventoryPinned; break;
        case "minimap": minimapPinned = !minimapPinned; break;
        case "all": {
            const pin = !(chatPinned && inventoryPinned && minimapPinned);
            chatPinned = pin;
            inventoryPinned = pin;
            minimapPinned = pin;
            break;
        }
        }
    }

    function release() {
        chatGrab = false;
        inventoryGrab = false;
    }
}
