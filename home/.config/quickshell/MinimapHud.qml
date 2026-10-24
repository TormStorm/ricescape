// Top-right HUD: the minimap and its orbs.
//   Disc     clock and date; yellow dots are the windows on this workspace
//   Compass  turns with the workspace; click for the overview
//   Orbs     CPU, RAM, GPU and volume
//   Pouch    free disk space, counted like a coin stack
//   XP       notifications on/off      Globe  workspace / overview
//   X        logout panel              Banner your account mode
import QtQuick

Item {
    id: hud

    property string outputName: ""
    property string tip: ""
    property real tipX: 0
    property real tipY: 0

    implicitWidth: 252
    implicitHeight: 216

    readonly property var workspace: Niri.activeWorkspace(outputName)
    readonly property var windows: workspace ? Niri.windowsOn(workspace.id) : []

    function hint(text, item) {
        if (!text) { tip = ""; return; }
        const p = item.mapToItem(hud, 0, item.height + 4);
        tip = text;
        tipX = Math.max(2, Math.min(p.x, width - 140));
        tipY = Math.min(p.y, height - 22);
    }

    property date now: new Date()
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: hud.now = new Date()
    }

    // ---- Disc ---------------------------------------------------------------
    Item {
        id: disc
        x: 82
        y: 22
        width: 166
        height: 166

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.borderDark
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.lighter(Theme.borderLight, 1.3) }
                GradientStop { position: 1.0; color: Qt.darker(Theme.borderLight, 1.45) }
            }
        }
        Rectangle {
            id: well
            anchors.fill: parent
            anchors.margins: 8
            radius: width / 2
            color: Theme.borderDark

            Canvas {
                id: terrain
                anchors.fill: parent
                anchors.margins: 1

                property color ground: Theme.map
                property var dots: hud.windows
                onGroundChanged: requestPaint()
                onDotsChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    const r = width / 2;
                    ctx.reset();
                    ctx.save();
                    ctx.beginPath();
                    ctx.arc(r, r, r, 0, 2 * Math.PI);
                    ctx.clip();

                    const g = ctx.createRadialGradient(r * 0.8, r * 0.7, 4, r, r, r);
                    g.addColorStop(0, Qt.lighter(ground, 1.25));
                    g.addColorStop(1, Qt.darker(ground, 1.35));
                    ctx.fillStyle = g;
                    ctx.fillRect(0, 0, width, height);

                    // Paths across the map
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.13);
                    ctx.lineWidth = 6;
                    ctx.beginPath();
                    ctx.moveTo(0, r * 1.2);
                    ctx.bezierCurveTo(r * 0.6, r * 1.05, r * 1.1, r * 1.35, width, r * 0.9);
                    ctx.moveTo(r * 0.9, 0);
                    ctx.bezierCurveTo(r * 1.05, r * 0.6, r * 0.75, r * 1.3, r * 1.05, height);
                    ctx.stroke();

                    // Speckles (trees and rocks), deterministic
                    let seed = 7;
                    const rand = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
                    ctx.fillStyle = Qt.rgba(0, 0, 0, 0.18);
                    for (let i = 0; i < 70; i++) ctx.fillRect(rand() * width, rand() * height, 2, 2);

                    // Windows on this workspace: yellow NPC dots
                    for (const w of dots) {
                        const a = (w.id * 2.39996) % (2 * Math.PI);
                        const d = r * (0.42 + ((w.id * 37) % 40) / 100);
                        const x = r + Math.cos(a) * d;
                        const y = r + Math.sin(a) * d;
                        ctx.fillStyle = "#000000";
                        ctx.fillRect(x - 2, y - 1, 5, 4);
                        ctx.fillStyle = w.is_urgent ? "#FF2020" : (w.is_focused ? "#FFFFFF" : "#FFFF00");
                        ctx.fillRect(x - 2, y - 2, 4, 4);
                    }
                    ctx.restore();

                    // You are here
                    ctx.fillStyle = "#FFFFFF";
                    ctx.fillRect(r - 2, r + 22, 4, 4);
                }
            }

            Column {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -6
                spacing: -1

                ShadowText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(hud.now, "HH:mm")
                    color: Theme.textWhite
                    pixelSize: 22
                }
                ShadowText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(hud.now, "ddd d MMM")
                    color: Theme.text
                    pixelSize: 11
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.toggleOverview()
                onWheel: w => Niri.focusWorkspaceRelative(w.angleDelta.y > 0 ? -1 : 1)
                onContainsMouseChanged: hud.hint(containsMouse
                    ? hud.windows.length + " window" + (hud.windows.length === 1 ? "" : "s") + " here · scroll to change world"
                    : "", disc)
            }
        }
    }

    // ---- Pouch (free disk) ------------------------------------------------------
    StoneFrame {
        id: pouch
        x: 0
        y: 0
        width: 92
        height: 28
        rim: 3
        rivets: false
        fill: Theme.panelDark

        Glyph {
            x: 4
            anchors.verticalCenter: parent.verticalCenter
            code: 0xF124F
            color: "#E8C030"
            pixelSize: 15
        }
        ShadowText {
            anchors.right: parent.right
            anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            text: Stats.diskFree < 0 ? "--" : Stats.formatSize(Stats.diskFree)
            color: Stats.diskUsed > 90 ? "#FF3030" : (Stats.diskUsed > 75 ? "#FFFF00" : "#00FF80")
            pixelSize: 13
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: hud.hint(containsMouse
                ? "Disk: " + Stats.formatSize(Stats.diskFree) + " free, " + Stats.diskUsed + "% used" : "", pouch)
        }
    }

    // ---- Compass, XP, logout, globe -------------------------------------------------
    Compass {
        id: compass
        x: 90
        y: 22
        size: 34
        angle: hud.workspace ? (hud.workspace.idx - 1) * 40 : 0
        onClicked: Niri.toggleOverview()
        onScrolled: d => Niri.focusWorkspaceRelative(d > 0 ? -1 : 1)
        onHoveredChanged: hud.hint(hovered ? "Overview" : "", compass)
    }

    RoundButton {
        id: xp
        x: 62
        y: 36
        size: 26
        onClicked: Stats.toggleDnd()
        onHoveredChanged: hud.hint(hovered ? (Stats.dnd ? "Notifications: off" : "Notifications: on") : "", xp)

        ShadowText {
            anchors.centerIn: parent
            text: "XP"
            color: Stats.dnd ? Qt.darker(Theme.text, 2) : Theme.text
            pixelSize: 11
        }
    }

    StoneButton {
        id: logout
        x: 226
        y: 0
        width: 26
        height: 26
        radius: 5
        onClicked: Actions.logout()
        onHoveredChanged: hud.hint(hovered ? "Logout" : "", logout)

        Glyph {
            anchors.centerIn: parent
            code: 0xF0156
            color: Theme.text
            pixelSize: 16
        }
    }

    RoundButton {
        id: globe
        x: 222
        y: 150
        size: 30
        face: "#2E5E8A"
        onClicked: Niri.toggleOverview()
        onScrolled: d => Niri.focusWorkspaceRelative(d > 0 ? -1 : 1)
        onHoveredChanged: hud.hint(hovered ? "World " + (hud.workspace ? hud.workspace.idx : 1) : "", globe)

        Glyph {
            anchors.centerIn: parent
            code: 0xF01E7
            color: "#7CCB6A"
            pixelSize: 17
        }
        ShadowText {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 1
            text: hud.workspace ? String(hud.workspace.idx) : "1"
            color: Theme.textWhite
            pixelSize: 11
        }
    }

    // ---- Orbs ----------------------------------------------------------------
    Orb {
        id: cpuOrb
        x: 33
        y: 72
        value: Stats.cpu
        fillColor: Theme.orbHp
        glyph: 0xF0EE0
        onHoveredChanged: hud.hint(hovered ? "CPU " + Stats.cpu + "%" : "", cpuOrb)
        onClicked: Actions.systemMonitor()
    }
    Orb {
        id: ramOrb
        x: 31
        y: 108
        value: Stats.mem
        fillColor: Theme.orbPrayer
        glyph: 0xF035B
        onHoveredChanged: hud.hint(hovered ? "Memory " + Stats.mem + "% used" : "", ramOrb)
        onClicked: Actions.systemMonitor()
    }
    Orb {
        id: gpuOrb
        x: 43
        y: 143
        value: Stats.gpu
        fillColor: Theme.orbRun
        glyph: 0xF08AE
        onHoveredChanged: hud.hint(hovered ? (Stats.gpu < 0 ? "GPU usage unavailable" : "GPU " + Stats.gpu + "%") : "", gpuOrb)
        onClicked: Actions.systemMonitor()
    }
    Orb {
        id: volOrb
        x: 70
        y: 174
        value: Stats.volume
        valueText: Stats.muted ? "M" : String(Stats.volume)
        numberColor: Stats.muted ? "#FF3030" : "#00FF00"
        dim: Stats.muted
        fillColor: Theme.orbSpec
        glyph: Stats.muted ? 0xF0581 : 0xF057E
        onHoveredChanged: hud.hint(hovered ? "Volume " + Stats.volume + "% · click to mute · scroll" : "", volOrb)
        onClicked: Stats.toggleMute()
        onRightClicked: Actions.mixer()
        onScrolled: d => Stats.changeVolume(d > 0 ? 5 : -5)
    }

    // ---- Mode banner ------------------------------------------------------------
    StoneFrame {
        id: banner
        x: 136
        y: 192
        width: 116
        height: 24
        rim: 3
        rivets: false
        fill: Theme.stoneActive

        Row {
            anchors.centerIn: parent
            spacing: 5

            ModeIcon {
                anchors.verticalCenter: parent.verticalCenter
                pixel: 1
            }
            ShadowText {
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.shortModeName
                color: Theme.textWhite
                pixelSize: 11
            }
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Actions.modePicker()
            onContainsMouseChanged: hud.hint(containsMouse ? Theme.modeName + " · Talk-to Ironman tutor" : "", banner)
        }
    }

    Tooltip {
        x: hud.tipX
        y: hud.tipY
        text: hud.tip
    }
}
