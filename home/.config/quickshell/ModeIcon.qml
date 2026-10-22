// Draws the current mode's pixel sprite (assets/icons/*.txt) in palette colours.
// Penguin for Normal, Ironman helm for every Ironman mode.
import QtQuick
import Quickshell.Io

Canvas {
    id: icon

    property int pixel: 2          // screen pixels per sprite pixel
    property var rows: []

    implicitWidth: (rows.length ? rows[0].length : 12) * pixel
    implicitHeight: (rows.length || 12) * pixel

    property color c1: Theme.logo1
    property color c2: Theme.logo2
    property color c3: Theme.logo3

    onRowsChanged: requestPaint()
    onC1Changed: requestPaint()
    onC2Changed: requestPaint()
    onC3Changed: requestPaint()

    FileView {
        path: Theme.iconPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: icon.rows = text().split("\n").filter(l => l.length && l[0] !== "#")
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const colours = { "A": c1, "B": c2, "C": c3 };
        for (let y = 0; y < rows.length; y++) {
            for (let x = 0; x < rows[y].length; x++) {
                const c = colours[rows[y][x]];
                if (!c) continue;
                ctx.fillStyle = c;
                ctx.fillRect(x * pixel, y * pixel, pixel, pixel);
            }
        }
    }
}
