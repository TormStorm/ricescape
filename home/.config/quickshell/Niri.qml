// Niri workspaces and windows, kept in sync through niri's event stream.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var workspaces: []
    property var windows: []

    readonly property string focusedOutput: {
        const ws = workspaces.find(w => w.is_focused);
        return ws ? (ws.output || "") : "";
    }

    function activeWorkspace(outputName) {
        return workspaces.find(w => w.is_active && (!outputName || w.output === outputName))
            || workspaces.find(w => w.is_focused)
            || null;
    }
    function windowsOn(workspaceId) {
        return windows.filter(w => w.workspace_id === workspaceId);
    }

    function action(...args) {
        Quickshell.execDetached(["niri", "msg", "action", ...args]);
    }
    function toggleOverview() { action("toggle-overview"); }
    function focusWorkspaceRelative(delta) { action(delta > 0 ? "focus-workspace-down" : "focus-workspace-up"); }
    function focusWorkspace(idx) { action("focus-workspace", String(idx)); }

    Process {
        id: wsQuery
        command: ["niri", "msg", "-j", "workspaces"]
        stdout: StdioCollector {
            id: wsOut
            onStreamFinished: {
                try {
                    const ws = JSON.parse(wsOut.text);
                    ws.sort((a, b) => a.idx - b.idx);
                    root.workspaces = ws;
                } catch (e) {
                    console.warn("ricescape: could not read niri workspaces:", e);
                }
            }
        }
    }

    Process {
        id: winQuery
        command: ["niri", "msg", "-j", "windows"]
        stdout: StdioCollector {
            id: winOut
            onStreamFinished: {
                try {
                    root.windows = JSON.parse(winOut.text);
                } catch (e) {
                    console.warn("ricescape: could not read niri windows:", e);
                }
            }
        }
    }

    // Debounce bursts of events into one refresh.
    Timer {
        id: refresh
        interval: 80
        onTriggered: {
            wsQuery.running = true;
            winQuery.running = true;
        }
    }

    Process {
        id: events
        command: ["niri", "msg", "-j", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.indexOf("Workspace") !== -1 || data.indexOf("Window") !== -1) refresh.restart();
            }
        }
        onExited: reconnect.start()
    }

    Timer {
        id: reconnect
        interval: 3000
        onTriggered: events.running = true
    }

    Component.onCompleted: refresh.start()
}
