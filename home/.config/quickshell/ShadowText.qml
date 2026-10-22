// OSRS-style text: bright colour with a hard 1px black drop shadow.
import QtQuick

Item {
    id: root

    property alias text: label.text
    property color color: Theme.text
    property int pixelSize: 14
    property bool bold: false

    implicitWidth: label.implicitWidth + 1
    implicitHeight: label.implicitHeight + 1

    Text {
        x: 1
        y: 1
        text: label.text
        color: Theme.textShadow
        font: label.font
        renderType: Text.NativeRendering
    }
    Text {
        id: label
        color: root.color
        font.family: Theme.uiFont
        font.pixelSize: root.pixelSize
        font.bold: root.bold
        renderType: Text.NativeRendering
    }
}
