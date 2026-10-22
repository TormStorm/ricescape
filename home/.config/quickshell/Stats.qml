// System stats polled for the orbs.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int battery: -1        // -1 when there is no battery
    property bool charging: false
    property int cpu: 0             // percent busy
    property int memAvailable: 100  // percent available
    property int volume: 0          // percent
    property bool muted: false

    property var _lastCpu: null

    Process {
        id: batteryProc
        command: ["sh", "-c", "for b in /sys/class/power_supply/BAT*; do if [ -r \"$b/capacity\" ]; then cat \"$b/capacity\" \"$b/status\"; exit 0; fi; done; echo -1; echo none"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                root.battery = parseInt(lines[0]);
                root.charging = (lines[1] || "") === "Charging";
            }
        }
    }

    Process {
        id: cpuProc
        command: ["head", "-n1", "/proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(/\s+/).slice(1).map(Number);
                const idle = f[3] + (f[4] || 0);
                const total = f.slice(0, 8).reduce((a, b) => a + b, 0);
                if (root._lastCpu) {
                    const dTotal = total - root._lastCpu.total;
                    const dIdle = idle - root._lastCpu.idle;
                    if (dTotal > 0) root.cpu = Math.round(100 * (1 - dIdle / dTotal));
                }
                root._lastCpu = { total: total, idle: idle };
            }
        }
    }

    Process {
        id: memProc
        command: ["grep", "-E", "^(MemTotal|MemAvailable):", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {};
                for (const line of text.trim().split("\n")) {
                    const parts = line.split(/\s+/);
                    m[parts[0].replace(":", "")] = Number(parts[1]);
                }
                if (m.MemTotal > 0) root.memAvailable = Math.round(100 * m.MemAvailable / m.MemTotal);
            }
        }
    }

    Process {
        id: volumeProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/Volume:\s*([\d.]+)/);
                if (match) root.volume = Math.round(parseFloat(match[1]) * 100);
                root.muted = text.indexOf("MUTED") !== -1;
            }
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            batteryProc.running = true;
            cpuProc.running = true;
            memProc.running = true;
            volumeProc.running = true;
        }
    }
}
