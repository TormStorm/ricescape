// A HUD panel that hides against a screen edge, leaving a thin stone lip.
// Hover the lip (push the mouse into that edge) and it slides out; move away
// and it tucks itself back in. Pinned or keybind-opened panels stay out.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    property string edge: "bottom"          // "top" or "bottom"
    property bool alignRight: false
    property int sideMargin: 0
    property int peek: 5                    // pixels left showing when hidden
    property real contentWidth: 100
    property real contentHeight: 100

    property bool pinned: false
    property bool grab: false               // opened by keybind: take the keyboard
    property bool hold: false               // content is busy (typing, menu open)
    property bool hoverOpen: false
    readonly property bool open: hoverOpen || pinned || grab || hold

    default property alias content: body.data

    signal closed()

    anchors {
        top: edge === "top"
        bottom: edge === "bottom"
        left: !alignRight
        right: alignRight
    }
    margins {
        left: alignRight ? 0 : sideMargin
        right: alignRight ? sideMargin : 0
    }

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitWidth: Math.ceil(contentWidth * Theme.scale)
    implicitHeight: Math.ceil(contentHeight * Theme.scale)

    WlrLayershell.namespace: "ricescape"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: grab ? WlrKeyboardFocus.Exclusive
                               : (open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)

    property real progress: open ? 1 : 0
    Behavior on progress { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

    onOpenChanged: if (!open) closed()

    // How far the panel is pushed off screen.
    readonly property real hiddenBy: (implicitHeight - peek) * (1 - progress)

    Item {
        id: slider
        width: win.implicitWidth
        height: win.implicitHeight
        y: win.edge === "bottom" ? win.hiddenBy : -win.hiddenBy

        Item {
            id: body
            width: win.contentWidth
            height: win.contentHeight
            scale: Theme.scale
            transformOrigin: Item.TopLeft
        }

        HoverHandler {
            id: hover
            onHoveredChanged: {
                if (hovered) {
                    closeTimer.stop();
                    if (!win.hoverOpen) openTimer.restart();
                } else {
                    openTimer.stop();
                    closeTimer.restart();
                }
            }
        }
    }

    // A short delay before opening avoids flicker when the mouse just passes by.
    Timer {
        id: openTimer
        interval: 90
        onTriggered: win.hoverOpen = true
    }
    Timer {
        id: closeTimer
        interval: 450
        onTriggered: win.hoverOpen = false
    }

    // Only the visible part of the panel takes clicks; the rest passes through.
    Item {
        id: hitbox
        x: 0
        width: win.implicitWidth
        y: win.edge === "bottom" ? win.hiddenBy : 0
        height: Math.max(win.peek, win.implicitHeight - win.hiddenBy)
    }
    mask: Region { item: hitbox }
}
