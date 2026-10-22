// The minimap: a round stone frame holding the clock and date.
import QtQuick
import Quickshell

Item {
    id: map
    implicitWidth: 44
    implicitHeight: 44

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.borderDark

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: width / 2
            color: Theme.bg
            border.color: Theme.borderLight
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: -2

                ShadowText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    pixelSize: 12
                    bold: true
                }
                ShadowText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dd MMM")
                    color: Theme.textAlt
                    pixelSize: 8
                }
            }
        }
    }
}
