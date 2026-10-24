// OSRS-style text: a bright colour with a hard 1px black drop shadow.
import QtQuick

Item {
    id: root

    property alias text: label.text
    property color color: Theme.text
    property color shadowColor: Theme.textShadow
    property int pixelSize: 13
    property bool bold: true
    property string family: Theme.uiFont
    property alias elide: label.elide
    property alias horizontalAlignment: label.horizontalAlignment
    property alias textFormat: label.textFormat

    implicitWidth: label.implicitWidth + 1
    implicitHeight: label.implicitHeight + 1

    Text {
        x: 1
        y: 1
        width: label.width
        text: label.text
        color: root.shadowColor
        font: label.font
        elide: label.elide
        horizontalAlignment: label.horizontalAlignment
        textFormat: label.textFormat
        renderType: Text.NativeRendering
    }
    Text {
        id: label
        width: root.width > 0 ? root.width - 1 : implicitWidth
        color: root.color
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.bold: root.bold
        renderType: Text.NativeRendering
    }
}
