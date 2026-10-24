// A small round stone button (compass, XP, world globe).
import QtQuick

Item {
    id: btn

    property int size: 28
    property color face: Theme.panel
    readonly property bool hovered: mouse.containsMouse
    default property alias content: inner.data

    signal clicked()
    signal rightClicked()
    signal scrolled(int delta)

    width: size
    height: size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.borderDark

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.lighter(Theme.borderLight, 1.3) }
                GradientStop { position: 1.0; color: Qt.darker(Theme.borderLight, 1.4) }
            }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: width / 2
            color: Theme.borderDark

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: width / 2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(btn.hovered ? Qt.lighter(btn.face, 1.2) : btn.face, 1.35) }
                    GradientStop { position: 1.0; color: Qt.darker(btn.hovered ? Qt.lighter(btn.face, 1.2) : btn.face, 1.3) }
                }
            }
        }
    }

    Item {
        id: inner
        anchors.fill: parent
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => m.button === Qt.RightButton ? btn.rightClicked() : btn.clicked()
        onWheel: w => btn.scrolled(w.angleDelta.y)
    }
}
