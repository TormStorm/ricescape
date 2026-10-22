// The bevelled stone/brown frame used by every OSRS-style panel.
import QtQuick

Item {
    id: frame

    property color fill: Theme.panel
    property int bevel: 2
    default property alias content: inner.data

    Rectangle {
        anchors.fill: parent
        color: Theme.borderDark
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: frame.bevel
        color: frame.fill
        border.color: Theme.borderLight
        border.width: 1
    }
    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: frame.bevel + 1
    }
}
