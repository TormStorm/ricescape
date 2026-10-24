// Right-click "Choose Option" menu, OSRS style.
// options: [{ action: "Launch", target: "Firefox" }, ...]
import QtQuick

Item {
    id: menu

    property var options: []
    property int hoveredIndex: -1

    signal chosen(int index)
    signal dismissed()

    visible: options.length > 0
    width: Math.max(header.implicitWidth, col.implicitWidth) + 10
    height: 18 + options.length * 16 + 4
    z: 200

    function popup(opts, px, py, bounds) {
        options = opts;
        const w = width, h = height;
        x = Math.max(0, Math.min(px - w / 2, bounds.width - w));
        y = Math.max(0, Math.min(py - 4, bounds.height - h));
    }
    function close() {
        options = [];
        hoveredIndex = -1;
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            color: "#5D5447"
        }
        Rectangle {
            x: 1
            y: 1
            width: parent.width - 2
            height: 16
            color: "#000000"
        }
    }

    Text {
        id: header
        x: 3
        y: 2
        text: "Choose Option"
        color: "#A89A80"
        font.family: Theme.uiFont
        font.pixelSize: 12
        font.bold: true
        renderType: Text.NativeRendering
    }

    Column {
        id: col
        x: 4
        y: 19

        Repeater {
            model: menu.options

            Row {
                required property var modelData
                required property int index
                height: 16
                spacing: 4

                ShadowText {
                    text: modelData.action
                    color: menu.hoveredIndex === index ? Theme.text : Theme.textWhite
                    pixelSize: 12
                    bold: false
                }
                ShadowText {
                    visible: !!modelData.target
                    text: modelData.target || ""
                    color: "#FF9040"
                    pixelSize: 12
                    bold: false
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: m => menu.hoveredIndex = m.y < 18 ? -1 : Math.floor((m.y - 19) / 16)
        onExited: menu.hoveredIndex = -1
        onClicked: m => {
            const i = Math.floor((m.y - 19) / 16);
            if (m.y >= 18 && i >= 0 && i < menu.options.length) menu.chosen(i);
            else menu.dismissed();
        }
    }
}
