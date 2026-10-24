// Bottom-left: the chatbox console and status bar. Hover the bottom-left edge,
// or press Super+` (grave) to open it with the keyboard.
import QtQuick

EdgePanel {
    id: panel

    edge: "bottom"
    alignRight: false
    peek: 5
    contentWidth: hud.implicitWidth
    contentHeight: hud.implicitHeight
    pinned: Hud.chatPinned
    grab: Hud.chatGrab && Hud.isGrabScreen(panel.modelData.name)
    hold: hud.typing

    ChatHud {
        id: hud
        active: panel.open
        grab: panel.grab
        onCloseRequested: Hud.release()
    }
}
