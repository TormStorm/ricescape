// Bottom-right: the inventory (all apps) and stone tabs (favourites).
// Hover the bottom-right edge, or press Super+D to open it and type to search.
import QtQuick

EdgePanel {
    id: panel

    edge: "bottom"
    alignRight: true
    peek: 5
    contentWidth: hud.implicitWidth
    contentHeight: hud.implicitHeight
    pinned: Hud.inventoryPinned
    grab: Hud.inventoryGrab && Hud.isGrabScreen(panel.modelData.name)
    hold: hud.typing || hud.menuOpen

    SideHud {
        id: hud
        active: panel.open
        grab: panel.grab
        onCloseRequested: Hud.release()
    }
}
