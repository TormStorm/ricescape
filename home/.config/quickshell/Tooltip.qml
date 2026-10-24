// A small OSRS-style hover box (pale yellow, black border).
import QtQuick

Rectangle {
    id: tip

    property string text: ""

    visible: text.length > 0
    width: label.implicitWidth + 10
    height: label.implicitHeight + 6
    color: "#FFFFA0"
    border.color: "#000000"
    border.width: 1
    z: 100

    Text {
        id: label
        anchors.centerIn: parent
        text: tip.text
        color: "#000000"
        font.family: Theme.uiFont
        font.pixelSize: 11
        renderType: Text.NativeRendering
    }
}
