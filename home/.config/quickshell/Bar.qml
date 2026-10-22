// The stone bar across the top of each screen.
import QtQuick
import QtQuick.Layouts
import Quickshell

PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 50
    color: "transparent"

    StoneFrame {
        anchors.fill: parent

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 12

            Worlds {
                outputName: bar.modelData.name
            }

            Item { Layout.fillWidth: true }

            ModeBadge {}

            Orb {
                label: "HP"
                value: Stats.battery < 0 ? 100 : Stats.battery
                valueText: Stats.battery < 0 ? "AC" : String(Stats.battery)
                fillColor: Theme.orbHp
            }
            Orb {
                label: "Prayer"
                value: Stats.memAvailable
                fillColor: Theme.orbPrayer
            }
            Orb {
                label: "Run"
                value: 100 - Stats.cpu
                fillColor: Theme.orbRun
            }
            Orb {
                label: "Spec"
                value: Stats.muted ? 0 : Stats.volume
                valueText: Stats.muted ? "M" : String(Stats.volume)
                valueColor: Theme.text
                fillColor: Theme.orbSpec
                onClicked: Quickshell.execDetached(["pavucontrol"])
            }

            Minimap {}

            StoneFrame {
                implicitWidth: 30
                implicitHeight: 30
                fill: Theme.panelDark

                ShadowText {
                    anchors.centerIn: parent
                    text: "⏻"
                    color: Theme.textAlt
                    pixelSize: 14
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["sh", "-c", "\"$HOME/.local/bin/ropes\" logout"])
                }
            }
        }
    }
}
