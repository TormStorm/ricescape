// Shows the current account mode. Click to talk to the Ironman tutor.
import QtQuick
import Quickshell

StoneFrame {
    id: badge

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 30
    fill: Theme.panelDark

    Row {
        anchors.centerIn: parent
        spacing: 6

        ModeIcon {
            pixel: 2
            anchors.verticalCenter: parent.verticalCenter
        }
        ShadowText {
            id: label
            text: Theme.modeName
            color: Theme.textAlt
            pixelSize: 13
            bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["kitty", "--class", "ropes", "-e", "sh", "-c", "\"$HOME/.local/bin/ropes\" mode"])
    }
}
