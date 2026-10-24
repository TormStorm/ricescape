// An OSRS status orb: a number plate tucked under a round, filling orb.
import QtQuick

Item {
    id: orb

    property int value: 0                      // number on the plate
    property real level: value / 100           // 0–1, how full the orb is
    property string valueText: value < 0 ? "--" : String(value)
    property color numberColor: Theme.usageColor(value)
    property color fillColor: Theme.orbHp
    property int glyph: 0
    property int size: 30
    property bool dim: false
    property string tooltip: ""
    readonly property bool hovered: mouse.containsMouse

    signal clicked()
    signal rightClicked()
    signal scrolled(int delta)

    implicitWidth: plate.width + size - 7
    implicitHeight: size

    // Number plate
    Rectangle {
        id: plate
        width: 37
        height: 20
        anchors.verticalCenter: parent.verticalCenter
        radius: 4
        color: Theme.borderDark

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 3
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.lighter(Theme.panel, 1.25) }
                GradientStop { position: 1.0; color: Qt.darker(Theme.panel, 1.25) }
            }
        }

        ShadowText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 9
            text: orb.valueText
            color: orb.numberColor
            pixelSize: 13
        }
    }

    // The orb
    Canvas {
        id: ball
        x: plate.width - 7
        width: orb.size
        height: orb.size

        property real level: Math.max(0, Math.min(1, orb.level))
        property color fillColor: orb.dim ? Qt.darker(orb.fillColor, 2.2) : orb.fillColor
        property color empty: Qt.darker(Theme.panelDark, 1.4)
        property color rimDark: Theme.borderDark
        property color rimLight: Theme.borderLight

        onLevelChanged: requestPaint()
        onFillColorChanged: requestPaint()
        onRimLightChanged: requestPaint()
        onEmptyChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            const r = width / 2;
            ctx.reset();

            // Stone rim
            ctx.beginPath();
            ctx.arc(r, r, r - 0.5, 0, 2 * Math.PI);
            ctx.fillStyle = rimDark;
            ctx.fill();
            const rim = ctx.createLinearGradient(0, 0, 0, height);
            rim.addColorStop(0, Qt.lighter(rimLight, 1.3));
            rim.addColorStop(1, Qt.darker(rimLight, 1.4));
            ctx.beginPath();
            ctx.arc(r, r, r - 1.5, 0, 2 * Math.PI);
            ctx.fillStyle = rim;
            ctx.fill();

            // Well and fill
            ctx.save();
            ctx.beginPath();
            ctx.arc(r, r, r - 3.5, 0, 2 * Math.PI);
            ctx.clip();
            ctx.fillStyle = empty;
            ctx.fillRect(0, 0, width, height);
            const top = 3.5 + (height - 7) * (1 - level);
            const fill = ctx.createRadialGradient(r * 0.75, r * 0.6, 1, r, r, r);
            fill.addColorStop(0, Qt.lighter(fillColor, 1.5));
            fill.addColorStop(0.6, fillColor);
            fill.addColorStop(1, Qt.darker(fillColor, 1.8));
            ctx.fillStyle = fill;
            ctx.fillRect(0, top, width, height);
            // Gloss
            ctx.beginPath();
            ctx.ellipse(r * 0.55, r * 0.35, r * 0.7, r * 0.45);
            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.16);
            ctx.fill();
            ctx.restore();

            ctx.beginPath();
            ctx.arc(r, r, r - 3.5, 0, 2 * Math.PI);
            ctx.lineWidth = 1;
            ctx.strokeStyle = rimDark;
            ctx.stroke();
        }

        Glyph {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: 1
            code: orb.glyph
            pixelSize: Math.round(orb.size * 0.5)
            color: orb.dim ? Qt.darker(Theme.textWhite, 1.8) : Theme.textWhite
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => m.button === Qt.RightButton ? orb.rightClicked() : orb.clicked()
        onWheel: w => orb.scrolled(w.angleDelta.y)
    }
}
