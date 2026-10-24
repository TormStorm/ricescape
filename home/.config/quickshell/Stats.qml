// System stats for the orbs, pouch and chat status bar.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int cpu: 0             // % busy
    property int mem: 0             // % used
    property int gpu: -1            // % busy, -1 when unknown
    property int volume: 0
    property bool muted: false
    property int battery: -1        // %, -1 when there is no battery
    property bool charging: false
    property real diskFree: -1      // MiB free in $HOME
    property int diskUsed: 0        // % used
    property bool dnd: false
    property string netName: ""
    property string netType: ""
    property string mediaStatus: ""
    property string mediaTitle: ""
    property int updates: -1        // pending pacman updates, -1 when unknown
    property int uptime: 0          // seconds

    property var _lastCpu: null

    function formatSize(mib) {
        if (mib >= 1024 * 1000) return (mib / 1024 / 1024).toFixed(1) + "T";
        if (mib >= 1024) return Math.round(mib / 1024) + "G";
        return Math.round(mib) + "M";
    }
    function formatDuration(s) {
        const p = n => String(n).padStart(2, "0");
        return p(Math.floor(s / 3600)) + ":" + p(Math.floor(s % 3600 / 60)) + ":" + p(s % 60);
    }

    function toggleMute() {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
        muted = !muted;
        volumeProc.running = true;
    }
    function changeVolume(delta) {
        const arg = Math.abs(delta) + "%" + (delta > 0 ? "+" : "-");
        Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", arg]);
        volume = Math.max(0, Math.min(100, volume + delta));
        volumeProc.running = true;
    }
    function toggleDnd() {
        Quickshell.execDetached(["makoctl", "mode", "-t", "do-not-disturb"]);
        dnd = !dnd;
    }
    function playPause() {
        Quickshell.execDetached(["playerctl", "play-pause"]);
        mediaProc.running = true;
    }
    function nextTrack() {
        Quickshell.execDetached(["playerctl", "next"]);
        mediaProc.running = true;
    }

    // ---- Fast: CPU, memory, GPU, volume, battery -----------------------------------
    Process {
        id: cpuProc
        command: ["head", "-n1", "/proc/stat"]
        stdout: StdioCollector {
            id: cpuOut
            onStreamFinished: {
                const f = cpuOut.text.trim().split(/\s+/).slice(1).map(Number);
                const idle = f[3] + (f[4] || 0);
                const total = f.slice(0, 8).reduce((a, b) => a + b, 0);
                if (root._lastCpu) {
                    const dt = total - root._lastCpu.total;
                    if (dt > 0) root.cpu = Math.round(100 * (1 - (idle - root._lastCpu.idle) / dt));
                }
                root._lastCpu = { total: total, idle: idle };
            }
        }
    }

    Process {
        id: memProc
        command: ["grep", "-E", "^(MemTotal|MemAvailable):", "/proc/meminfo"]
        stdout: StdioCollector {
            id: memOut
            onStreamFinished: {
                const m = {};
                for (const line of memOut.text.trim().split("\n")) {
                    const parts = line.split(/\s+/);
                    m[parts[0].replace(":", "")] = Number(parts[1]);
                }
                if (m.MemTotal > 0) root.mem = Math.round(100 * (1 - m.MemAvailable / m.MemTotal));
            }
        }
    }

    // AMD/Intel expose gpu_busy_percent; NVIDIA needs nvidia-smi.
    Process {
        id: gpuProc
        command: ["sh", "-c",
            "for f in /sys/class/drm/card*/device/gpu_busy_percent; do " +
            "[ -r \"$f\" ] && { cat \"$f\"; exit 0; }; done; " +
            "command -v nvidia-smi >/dev/null && " +
            "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n1 && exit 0; " +
            "echo -1"]
        stdout: StdioCollector {
            id: gpuOut
            onStreamFinished: {
                const v = parseInt(gpuOut.text.trim());
                root.gpu = isNaN(v) ? -1 : v;
            }
        }
    }

    Process {
        id: volumeProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            id: volumeOut
            onStreamFinished: {
                const match = volumeOut.text.match(/Volume:\s*([\d.]+)/);
                if (match) root.volume = Math.round(parseFloat(match[1]) * 100);
                root.muted = volumeOut.text.indexOf("MUTED") !== -1;
            }
        }
    }

    Process {
        id: batteryProc
        command: ["sh", "-c",
            "for b in /sys/class/power_supply/BAT*; do if [ -r \"$b/capacity\" ]; then " +
            "cat \"$b/capacity\" \"$b/status\"; exit 0; fi; done; echo -1; echo none"]
        stdout: StdioCollector {
            id: batteryOut
            onStreamFinished: {
                const lines = batteryOut.text.trim().split("\n");
                root.battery = parseInt(lines[0]);
                root.charging = (lines[1] || "") === "Charging";
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = true;
            memProc.running = true;
            gpuProc.running = true;
            volumeProc.running = true;
            batteryProc.running = true;
            mediaProc.running = true;
        }
    }

    // ---- Slow: disk, network, media, uptime -------------------------------------------
    Process {
        id: diskProc
        command: ["sh", "-c", "df -BM --output=avail,pcent \"$HOME\" | tail -n1"]
        stdout: StdioCollector {
            id: diskOut
            onStreamFinished: {
                const parts = diskOut.text.trim().split(/\s+/);
                root.diskFree = parseInt(parts[0]);
                root.diskUsed = parseInt(parts[1]);
            }
        }
    }

    Process {
        id: netProc
        command: ["sh", "-c", "command -v nmcli >/dev/null && nmcli -t -f TYPE,STATE,CONNECTION device"]
        stdout: StdioCollector {
            id: netOut
            onStreamFinished: {
                root.netName = "";
                root.netType = "";
                for (const line of netOut.text.trim().split("\n")) {
                    const parts = line.split(":");
                    const type = parts[0], state = parts[1];
                    if (state === "connected" && type !== "loopback" && type !== "bridge") {
                        root.netName = parts.slice(2).join(":");
                        root.netType = type === "wifi" ? "Wi-Fi" : (type === "ethernet" ? "Wired" : type);
                        if (type === "wifi" || type === "ethernet") break;
                    }
                }
            }
        }
    }

    Process {
        id: mediaProc
        command: ["sh", "-c", "playerctl status 2>/dev/null && playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null"]
        stdout: StdioCollector {
            id: mediaOut
            onStreamFinished: {
                const lines = mediaOut.text.trim().split("\n");
                root.mediaStatus = lines[0] || "";
                root.mediaTitle = (lines[1] || "").replace(/^ - /, "");
            }
        }
    }

    Process {
        id: uptimeProc
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector {
            id: uptimeOut
            onStreamFinished: root.uptime = Math.floor(parseFloat(uptimeOut.text))
        }
    }

    Process {
        id: dndProc
        command: ["sh", "-c", "makoctl mode 2>/dev/null"]
        stdout: StdioCollector {
            id: dndOut
            onStreamFinished: root.dnd = dndOut.text.indexOf("do-not-disturb") !== -1
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            diskProc.running = true;
            netProc.running = true;
            uptimeProc.running = true;
            dndProc.running = true;
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.uptime += 1
    }

    // ---- Updates (pacman-contrib's checkupdates), every 30 minutes -----------------------
    Process {
        id: updatesProc
        command: ["sh", "-c", "command -v checkupdates >/dev/null || { echo -1; exit; }; checkupdates 2>/dev/null | wc -l"]
        stdout: StdioCollector {
            id: updatesOut
            onStreamFinished: {
                const v = parseInt(updatesOut.text.trim());
                root.updates = isNaN(v) ? -1 : v;
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updatesProc.running = true
    }
}
