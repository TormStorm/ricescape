// Live palette. `ropes mode` rewrites palette.json and this reloads it.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string mode: "normal"
    property string modeName: "Normal"

    property color bg: "#121212"
    property color accent: "#C9A227"
    property color panel: "#3E3529"
    property color panelDark: "#2B241C"
    property color borderLight: "#6B5E49"
    property color borderDark: "#1A1610"
    property color helm: "#C9A227"

    property color text: "#FFFF00"
    property color textShadow: "#000000"
    property color textAlt: "#FF981F"
    property color textWhite: "#FFFFFF"

    property color good: "#3FA34D"
    property color warn: "#E0A82E"
    property color bad: "#C0392B"

    property color orbHp: "#B5281F"
    property color orbPrayer: "#3DA3D8"
    property color orbRun: "#D9B02B"
    property color orbSpec: "#3AB29E"

    property string uiFont: "JetBrainsMono Nerd Font"

    function valueColor(percent) {
        if (percent > 50) return good;
        if (percent > 25) return warn;
        return bad;
    }

    function apply(raw) {
        let p;
        try {
            p = JSON.parse(raw);
        } catch (e) {
            console.warn("ricescape: could not parse palette.json:", e);
            return;
        }
        const set = (prop, key) => { if (p[key] !== undefined) root[prop] = p[key]; };
        set("mode", "mode");
        set("modeName", "name");
        set("bg", "bg");
        set("accent", "accent");
        set("panel", "panel");
        set("panelDark", "panel_dark");
        set("borderLight", "border_light");
        set("borderDark", "border_dark");
        set("helm", "helm");
        set("text", "text");
        set("textShadow", "text_shadow");
        set("textAlt", "text_alt");
        set("textWhite", "text_white");
        set("good", "good");
        set("warn", "warn");
        set("bad", "bad");
        set("orbHp", "orb_hp");
        set("orbPrayer", "orb_prayer");
        set("orbRun", "orb_run");
        set("orbSpec", "orb_spec");
        set("uiFont", "ui_font");
    }

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/ricescape/palette.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.apply(text())
    }
}
