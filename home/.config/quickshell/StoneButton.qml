// A rounded stone tab, like the OSRS side-panel and chat filter buttons.
import QtQuick

Item {
    id: btn

    property bool active: false
    property bool enabled: true
    readonly property bool hovered: mouse.containsMouse
    property int radius: 7
    property color baseColor: Theme.panel
    readonly property color base: active ? Theme.stoneActive
                                : (hovered && enabled ? Qt.lighter(baseColor, 1.2) : baseColor)
    default property alias content: inner.data

    signal clicked()
    signal rightClicked()
    signal middleClicked()
    signal scrolled(int delta)

    Rectangle {
        anchors.fill: parent
        radius: btn.radius
        color: Theme.borderDark

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: btn.radius - 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.lighter(btn.base, 1.45) }
                GradientStop { position: 0.14; color: Qt.lighter(btn.base, 1.15) }
                GradientStop { position: 0.85; color: Qt.darker(btn.base, 1.1) }
                GradientStop { position: 1.0; color: Qt.darker(btn.base, 1.45) }
            }
        }
        // Soft inner highlight
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: btn.radius - 2
            color: "transparent"
            border.color: Qt.lighter(btn.base, 1.6)
            border.width: 1
            opacity: 0.25
        }
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: 3
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: btn.enabled
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => {
            if (m.button === Qt.RightButton) btn.rightClicked();
            else if (m.button === Qt.MiddleButton) btn.middleClicked();
            else btn.clicked();
        }
        onWheel: w => btn.scrolled(w.angleDelta.y)
    }
}
