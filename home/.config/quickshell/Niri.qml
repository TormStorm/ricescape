// Niri workspaces ("worlds"), kept in sync through niri's event stream.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var workspaces: []

    function focusWorkspace(idx) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(idx)]);
    }

    function forOutput(name) {
        return workspaces.filter(w => w.output === name);
    }

    Process {
        id: query
        command: ["niri", "msg", "-j", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const ws = JSON.parse(text);
                    ws.sort((a, b) => a.idx - b.idx);
                    root.workspaces = ws;
                } catch (e) {
                    console.warn("ricescape: could not read niri workspaces:", e);
                }
            }
        }
    }

    Process {
        id: events
        command: ["niri", "msg", "-j", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.indexOf("Workspace") !== -1) query.running = true;
            }
        }
        onExited: restart.start()
    }

    Timer {
        id: restart
        interval: 3000
        onTriggered: events.running = true
    }

    Component.onCompleted: query.running = true
}
