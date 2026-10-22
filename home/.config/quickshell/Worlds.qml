// Workspace tabs, styled like the OSRS side-panel tabs.
import QtQuick

Row {
    id: worlds

    required property string outputName

    spacing: 4

    Repeater {
        model: Niri.forOutput(worlds.outputName)

        StoneFrame {
            required property var modelData

            width: 30
            height: 30
            fill: modelData.is_active ? Theme.accent : Theme.panelDark

            ShadowText {
                anchors.centerIn: parent
                text: String(modelData.idx)
                color: modelData.is_active ? Theme.textWhite : Theme.text
                pixelSize: 13
                bold: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.focusWorkspace(modelData.idx)
            }
        }
    }
}
