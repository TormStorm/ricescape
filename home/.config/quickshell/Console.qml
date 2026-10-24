// The chatbox console. Runs one shell command at a time without a terminal and
// streams its output into the chat. `cd` sticks between commands.
// Lines starting with :: are Ricescape commands.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int maxLines: 500
    property bool busy: false
    property var history: []
    property string cwd: Quickshell.env("HOME")
    property string outputKind: "out"

    property ListModel lines: ListModel {}

    function append(kind, text) {
        const clean = String(text)
            .replace(/\x1b\[[0-?]*[ -\/]*[@-~]/g, "")
            .replace(/\x1b\][^\x07]*(\x07|\x1b\\)/g, "")
            .replace(/\r/g, "")
            .replace(/\t/g, "    ");
        lines.append({ kind: kind, text: clean, who: kind === "cmd" ? Theme.user : "" });
        while (lines.count > maxLines) lines.remove(0);
    }
    function system(text) { append("sys", text); }

    function clear() { lines.clear(); }

    function stop() {
        if (proc.running) {
            proc.running = false;
            system("Stopped.");
        }
    }

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function exec(cmd, kind) {
        if (busy) {
            system("You're already busy. Press Ctrl+C to stop the current command.");
            return;
        }
        outputKind = kind || "out";
        proc.command = ["bash", "-c",
            'cd -- "$1" 2>/dev/null || cd; eval "$2"; s=$?; printf "\\036%s\\n" "$PWD"; exit $s',
            "ricescape", cwd, cmd];
        busy = true;
        proc.running = true;
    }

    function run(text) {
        if (history[history.length - 1] !== text) history = history.concat([text]).slice(-200);
        append("cmd", text);
        if (text.startsWith("::")) builtin(text.slice(2).trim());
        else exec(text);
    }

    function builtin(text) {
        const words = text.split(/\s+/);
        const name = words[0];
        const args = words.slice(1);
        switch (name) {
        case "help":
            system("::mode [name]   change account mode (im, uim, hcim, gim, ugim, hcgim, normal)");
            system("::term          open a terminal here        ::update   run ropes update");
            system("::fetch         show system info            ::clear    clear the chat");
            system("::pin           keep the chatbox open       Ctrl+C     stop a command");
            system("Anything else runs in bash. Interactive programs need ::term.");
            break;
        case "clear":
            clear();
            break;
        case "mode":
            if (!args.length) {
                system("You are playing as: " + Theme.modeName + ". Try ::mode ironman");
            } else {
                exec('"$HOME/.local/bin/ropes" mode ' + shellQuote(args[0]) + " --skip-dialogue 2>&1 | sed 's/^» //'", "sys");
            }
            break;
        case "term":
        case "terminal":
            Actions.terminal(cwd);
            break;
        case "update":
            Actions.update();
            break;
        case "fetch":
            exec("fastfetch --pipe --logo none");
            break;
        case "pin":
            Hud.togglePin("chat");
            system(Hud.chatPinned ? "The chatbox will stay open." : "The chatbox will hide again.");
            break;
        default:
            system("Unknown command ::" + name + ". Try ::help");
        }
    }

    Process {
        id: proc
        environment: ({
            TERM: "dumb",
            NO_COLOR: "1",
            PAGER: "cat",
            GIT_PAGER: "cat",
            SYSTEMD_PAGER: "",
            SYSTEMD_COLORS: "0"
        })
        stdout: SplitParser {
            onRead: data => {
                if (data.charCodeAt(0) === 0x1e) root.cwd = data.slice(1);
                else root.append(root.outputKind, data);
            }
        }
        stderr: SplitParser {
            onRead: data => root.append(root.outputKind === "sys" ? "sys" : "err", data)
        }
        onExited: (code, status) => {
            root.busy = false;
            if (code !== 0 && root.outputKind !== "sys") root.system("Exit code " + code + ".");
        }
    }

    Component.onCompleted: {
        system("Welcome to Ricescape.");
        system("Type a command and press Enter. Try ::help");
    }
}
