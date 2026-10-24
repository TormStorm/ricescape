// The minimap compass. Its needle points at the current workspace's place
// in the list, so it turns as you switch worlds.
import QtQuick

RoundButton {
    id: compass

    property real angle: 0
    face: "#C8B88E"

    Behavior on angle { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    Canvas {
        anchors.fill: parent
        anchors.margins: 5
        rotation: compass.angle

        onPaint: {
            const ctx = getContext("2d");
            const c = width / 2;
            ctx.reset();
            // North (red) and south (blue) halves of the needle
            ctx.beginPath();
            ctx.moveTo(c, 2);
            ctx.lineTo(c + 4, c);
            ctx.lineTo(c - 4, c);
            ctx.closePath();
            ctx.fillStyle = "#C0201A";
            ctx.fill();
            ctx.beginPath();
            ctx.moveTo(c, height - 2);
            ctx.lineTo(c + 4, c);
            ctx.lineTo(c - 4, c);
            ctx.closePath();
            ctx.fillStyle = "#1F3F9A";
            ctx.fill();
            ctx.beginPath();
            ctx.arc(c, c, 1.6, 0, 2 * Math.PI);
            ctx.fillStyle = "#000000";
            ctx.fill();
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: -7
            text: "N"
            color: "#000000"
            font.family: Theme.uiFont
            font.pixelSize: 8
            font.bold: true
            renderType: Text.NativeRendering
        }
    }
}
