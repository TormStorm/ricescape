// Top-right: the minimap, orbs and friends. Hover the top-right edge.
import QtQuick

EdgePanel {
    id: panel

    edge: "top"
    alignRight: true
    sideMargin: 4
    peek: 6
    contentWidth: hud.implicitWidth
    contentHeight: hud.implicitHeight + 4
    pinned: Hud.minimapPinned

    MinimapHud {
        id: hud
        y: 4
        outputName: panel.modelData.name
    }
}
