// Bottom-left HUD: the chatbox console with a status bar of filter-style stones.
//
// Type a shell command and press Enter: it runs, and its output lands in the
// chat. Commands starting with :: are Ricescape commands (try ::help).
// It runs commands without a terminal, so for interactive programs open a real
// one with the Terminal stone or ::term.
import QtQuick

Item {
    id: hud

    property bool active: true          // panel is revealed
    property bool grab: false           // opened from the keybind: focus the input
    readonly property bool typing: input.activeFocus
    property string tip: ""
    property real tipX: 0
    property real tipY: 0

    signal closeRequested()

    implicitWidth: 522
    implicitHeight: box.height + bar.height + 3

    onGrabChanged: if (grab) input.forceActiveFocus()
    onActiveChanged: if (!active) input.focus = false

    function hint(text, item) {
        if (!text) { tip = ""; return; }
        const p = item.mapToItem(hud, 0, 0);
        tip = text;
        tipX = Math.max(2, Math.min(p.x, width - 220));
        tipY = p.y - 24;
    }

    // ---- Chatbox --------------------------------------------------------------
    StoneFrame {
        id: box
        width: parent.width
        height: 150
        rim: 5
        fill: Theme.parchment

        Item {
            id: area
            anchors.fill: parent

            ListView {
                id: log
                x: 5
                y: 3
                width: area.width - 26
                height: area.height - 25
                clip: true
                model: Console.lines
                spacing: 1
                boundsBehavior: Flickable.StopAtBounds
                property bool stick: true
                onMovementEnded: stick = atYEnd
                onCountChanged: if (stick) Qt.callLater(positionViewAtEnd)
                Component.onCompleted: positionViewAtEnd()

                delegate: Item {
                    required property string kind
                    required property string text
                    required property string who

                    width: log.width
                    height: kind === "cmd" ? cmdRow.implicitHeight : line.implicitHeight

                    Row {
                        id: cmdRow
                        visible: kind === "cmd"
                        Text {
                            text: who + ": "
                            color: Theme.chatText
                            font.family: Theme.uiFont
                            font.pixelSize: 13
                            font.bold: true
                            renderType: Text.NativeRendering
                        }
                        Text {
                            text: parent.parent.text
                            color: Theme.chatInput
                            font.family: Theme.uiFont
                            font.pixelSize: 13
                            renderType: Text.NativeRendering
                        }
                    }
                    Text {
                        id: line
                        visible: kind !== "cmd"
                        width: parent.width
                        text: parent.text
                        wrapMode: Text.WrapAnywhere
                        color: kind === "err" ? "#9A0000"
                             : kind === "sys" ? Theme.chatSystem
                             : Theme.chatText
                        font.family: kind === "out" || kind === "err" ? Theme.monoFont : Theme.uiFont
                        font.pixelSize: kind === "out" || kind === "err" ? 12 : 13
                        font.bold: kind === "sys"
                        renderType: Text.NativeRendering
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: w => {
                        log.contentY = Math.max(0, Math.min(log.contentHeight - log.height,
                            log.contentY - w.angleDelta.y));
                        log.stick = log.atYEnd;
                    }
                }
            }

            // Scrollbar, OSRS style
            Item {
                id: scroll
                x: area.width - 18
                y: 1
                width: 16
                height: area.height - 23

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 15
                    anchors.bottomMargin: 15
                    color: Qt.darker(Theme.panel, 1.2)
                    border.color: Theme.borderDark
                }
                StoneButton {
                    width: 16
                    height: 16
                    radius: 2
                    onClicked: { log.contentY = Math.max(0, log.contentY - 40); log.stick = false; }
                    Glyph { anchors.centerIn: parent; code: 0xF0737; pixelSize: 10; color: Theme.textWhite }
                }
                StoneButton {
                    y: scroll.height - 16
                    width: 16
                    height: 16
                    radius: 2
                    onClicked: { log.positionViewAtEnd(); log.stick = true; }
                    Glyph { anchors.centerIn: parent; code: 0xF072E; pixelSize: 10; color: Theme.textWhite }
                }
                StoneButton {
                    readonly property real track: scroll.height - 32
                    readonly property real ratio: log.contentHeight > 0 ? Math.min(1, log.height / log.contentHeight) : 1
                    x: 1
                    width: 14
                    radius: 2
                    height: Math.max(14, track * ratio)
                    y: 16 + (log.contentHeight > log.height
                        ? (track - height) * (log.contentY / (log.contentHeight - log.height)) : 0)
                    visible: ratio < 1
                }
            }

            // Divider
            Rectangle {
                x: 2
                y: area.height - 21
                width: area.width - 4
                height: 1
                color: Qt.darker(Theme.parchment, 1.7)
            }
            Rectangle {
                x: 2
                y: area.height - 20
                width: area.width - 4
                height: 1
                color: Qt.lighter(Theme.parchment, 1.12)
            }

            // Input line: "Name: command*"
            Row {
                x: 5
                y: area.height - 18
                width: area.width - 10
                height: 17

                Text {
                    id: who
                    text: Theme.user + ": "
                    color: Theme.chatText
                    font.family: Theme.uiFont
                    font.pixelSize: 13
                    font.bold: true
                    renderType: Text.NativeRendering
                }
                Item {
                    width: parent.width - who.width
                    height: parent.height

                    Text {
                        visible: !input.activeFocus && input.text.length === 0
                        text: Console.busy ? "Running... (Ctrl+C to stop)" : "Press Enter to Chat..."
                        color: Theme.chatInput
                        font: input.font
                        renderType: Text.NativeRendering
                    }
                    TextInput {
                        id: input
                        anchors.fill: parent
                        color: Theme.chatInput
                        font.family: Theme.uiFont
                        font.pixelSize: 13
                        selectByMouse: true
                        selectionColor: Theme.chatInput
                        renderType: Text.NativeRendering
                        clip: true
                        property int historyIndex: -1

                        cursorDelegate: Text {
                            text: "*"
                            color: Theme.chatInput
                            font: input.font
                            visible: input.activeFocus
                        }

                        function submit() {
                            const cmd = text.trim();
                            text = "";
                            historyIndex = -1;
                            if (cmd.length) Console.run(cmd);
                            log.stick = true;
                            log.positionViewAtEnd();
                        }
                        Keys.onReturnPressed: submit()
                        Keys.onEnterPressed: submit()
                        Keys.onEscapePressed: { focus = false; hud.closeRequested(); }
                        Keys.onUpPressed: {
                            const h = Console.history;
                            if (!h.length) return;
                            historyIndex = Math.min(h.length - 1, historyIndex + 1);
                            text = h[h.length - 1 - historyIndex];
                        }
                        Keys.onDownPressed: {
                            const h = Console.history;
                            historyIndex = Math.max(-1, historyIndex - 1);
                            text = historyIndex < 0 ? "" : h[h.length - 1 - historyIndex];
                        }
                        Keys.onPressed: e => {
                            if (e.modifiers & Qt.ControlModifier) {
                                if (e.key === Qt.Key_C && selectedText.length === 0) { Console.stop(); e.accepted = true; }
                                else if (e.key === Qt.Key_L) { Console.clear(); e.accepted = true; }
                            }
                        }
                    }
                }
            }

            MouseArea {
                x: 0
                y: area.height - 20
                width: area.width
                height: 20
                cursorShape: Qt.IBeamCursor
                onClicked: input.forceActiveFocus()
            }
        }
    }

    // ---- Status bar -------------------------------------------------------------
    Row {
        id: bar
        y: box.height + 3
        height: 32
        spacing: 2

        component Filter: StoneButton {
            id: f
            property string label: ""
            property string status: ""
            property color statusColor: "#00FF00"
            property string hover: ""
            width: 61
            height: 32
            radius: 6
            onHoveredChanged: hud.hint(hovered ? hover : "", f)

            Column {
                anchors.centerIn: parent
                spacing: -2
                ShadowText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: f.label
                    color: Theme.textWhite
                    pixelSize: 11
                    bold: false
                }
                ShadowText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(implicitWidth, f.width - 6)
                    text: f.status
                    color: f.statusColor
                    pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }

        Filter {
            label: "Terminal"
            status: "Open"
            statusColor: "#00FF00"
            hover: "Open a terminal"
            onClicked: Actions.terminal()
        }
        Filter {
            label: "Network"
            status: Stats.netName || "Offline"
            statusColor: Stats.netName ? "#00FF00" : "#FF3030"
            hover: Stats.netName ? Stats.netType + ": " + Stats.netName : "Not connected"
            onClicked: Actions.network()
        }
        Filter {
            label: "Volume"
            status: Stats.muted ? "Muted" : Stats.volume + "%"
            statusColor: Stats.muted ? "#FF3030" : "#00FF00"
            hover: "Click to mute · scroll to change · right-click for mixer"
            onClicked: Stats.toggleMute()
            onRightClicked: Actions.mixer()
            onScrolled: d => Stats.changeVolume(d > 0 ? 5 : -5)
        }
        Filter {
            label: Stats.battery < 0 ? "Power" : "Battery"
            status: Stats.battery < 0 ? "AC" : Stats.battery + "%" + (Stats.charging ? "+" : "")
            statusColor: Stats.battery < 0 ? "#00FF00" : Theme.levelColor(Stats.battery)
            hover: Stats.battery < 0 ? "No battery" : (Stats.charging ? "Charging" : "On battery")
        }
        Filter {
            label: "Media"
            status: Stats.mediaStatus || "Off"
            statusColor: Stats.mediaStatus === "Playing" ? "#00FF00"
                       : Stats.mediaStatus === "Paused" ? "#FFFF00" : "#FF3030"
            hover: Stats.mediaTitle ? Stats.mediaTitle : "Nothing playing"
            onClicked: Stats.playPause()
            onRightClicked: Stats.nextTrack()
        }
        Filter {
            label: "Updates"
            status: Stats.updates < 0 ? "?" : (Stats.updates === 0 ? "None" : String(Stats.updates))
            statusColor: Stats.updates === 0 ? "#00FF00" : (Stats.updates > 0 ? "#FFFF00" : Theme.textWhite)
            hover: Stats.updates > 0 ? "Click to run ropes update" : "Up to date"
            onClicked: Actions.update()
        }
        Filter {
            label: "Mode"
            status: Theme.shortModeName
            statusColor: Theme.text
            hover: Theme.modeName + " · Talk-to Ironman tutor"
            onClicked: Actions.modePicker()
        }

        // Session timer (system uptime), like the red report box
        Rectangle {
            id: timer
            width: 87
            height: 32
            radius: 5
            color: Theme.borderDark

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 4
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#9A2A22" }
                    GradientStop { position: 1.0; color: "#5A1210" }
                }
            }
            ShadowText {
                anchors.centerIn: parent
                text: Stats.formatDuration(Stats.uptime)
                color: Theme.textWhite
                pixelSize: 13
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onContainsMouseChanged: hud.hint(containsMouse ? "Uptime" : "", timer)
            }
        }
    }

    Tooltip {
        x: hud.tipX
        y: hud.tipY
        text: hud.tip
    }
}
