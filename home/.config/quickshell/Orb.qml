// A status orb: the number on the left, a round orb filling from the bottom.
import QtQuick

Item {
    id: orb

    property string label: ""
    property int value: 0              // 0–100, drives the fill
    property string valueText: String(value)
    property color fillColor: Theme.orbHp
    property color valueColor: Theme.valueColor(value)
    property int size: 30

    signal clicked()

    implicitWidth: row.implicitWidth
    implicitHeight: size

    Row {
        id: row
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter

        StoneFrame {
            width: 34
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            fill: Theme.panelDark
            bevel: 1

            ShadowText {
                anchors.centerIn: parent
                text: orb.valueText
                color: orb.valueColor
                pixelSize: 12
                bold: true
            }
        }

        Canvas {
            id: canvas
            width: orb.size
            height: orb.size

            property real level: Math.max(0, Math.min(100, orb.value)) / 100
            property color fillColor: orb.fillColor
            property color empty: Theme.panelDark
            property color rim: Theme.borderDark
            property color shine: Theme.borderLight

            onLevelChanged: requestPaint()
            onFillColorChanged: requestPaint()
            onEmptyChanged: requestPaint()
            onRimChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                const r = width / 2;
                ctx.reset();

                ctx.beginPath();
                ctx.arc(r, r, r - 1, 0, 2 * Math.PI);
                ctx.fillStyle = rim;
                ctx.fill();

                ctx.save();
                ctx.beginPath();
                ctx.arc(r, r, r - 3, 0, 2 * Math.PI);
                ctx.clip();
                ctx.fillStyle = empty;
                ctx.fillRect(0, 0, width, height);
                const h = (height - 6) * level;
                ctx.fillStyle = fillColor;
                ctx.fillRect(0, height - 3 - h, width, h);
                ctx.restore();

                ctx.beginPath();
                ctx.arc(r, r, r - 3, 0, 2 * Math.PI);
                ctx.lineWidth = 1;
                ctx.strokeStyle = shine;
                ctx.stroke();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: orb.clicked()
    }
}
