// Live palette for the whole shell.
// shell.qml feeds it ~/.local/state/ricescape/palette.json (written by `ropes mode`)
// and the current mode's icon sprite, so every component re-themes instantly.
pragma Singleton

import QtQuick

QtObject {
    id: root

    property string mode: "normal"
    property string modeName: "Normal"
    readonly property string shortModeName: ({
        "normal": "Normal", "ironman": "Ironman", "ultimate": "Ultimate",
        "hardcore": "Hardcore", "group": "Group", "unranked": "Unranked",
        "hardcore-group": "HC Group"
    })[mode] || modeName
    property string user: "Adventurer"

    // Stone and backgrounds
    property color bg: "#121212"
    property color accent: "#C9A227"
    property color panel: "#3E3529"
    property color panelDark: "#2B241C"
    property color borderLight: "#6B5E49"
    property color borderDark: "#1A1610"
    property color stoneActive: "#6E2A1E"
    property color parchment: "#D3C4A0"
    property color map: "#4F5A36"

    // Text
    property color text: "#FFFF00"
    property color textShadow: "#000000"
    property color textAlt: "#FF981F"
    property color textWhite: "#FFFFFF"
    property color chatText: "#000000"
    property color chatInput: "#0000FF"
    property color chatSystem: "#7F0000"

    // Status
    property color good: "#3FA34D"
    property color warn: "#E0A82E"
    property color bad: "#C0392B"
    property color orbHp: "#B5281F"
    property color orbPrayer: "#3DA3D8"
    property color orbRun: "#D9B02B"
    property color orbSpec: "#3AB29E"

    // Mode icon (penguin for Normal, helm for Ironman modes)
    property string iconPath: ""
    property var iconRows: []
    property color logo1: "#505050"
    property color logo2: "#F2F2F2"
    property color logo3: "#F08A1C"

    property string uiFont: "JetBrainsMono Nerd Font"
    property string monoFont: "JetBrainsMono Nerd Font"
    property string iconFont: "Symbols Nerd Font"
    property real scale: 1

    // OSRS-style number colours: green when healthy, yellow, then red.
    // For usage values (CPU, RAM...), low is healthy.
    function usageColor(percent) {
        if (percent < 0) return textWhite;
        if (percent < 60) return "#00FF00";
        if (percent < 85) return "#FFFF00";
        return "#FF3030";
    }
    // For "remaining" values (battery), high is healthy.
    function levelColor(percent) {
        if (percent < 0) return textWhite;
        if (percent > 50) return "#00FF00";
        if (percent > 20) return "#FFFF00";
        return "#FF3030";
    }

    function setIcon(raw) {
        iconRows = raw.split("\n").filter(l => l.length && l[0] !== "#");
    }

    function apply(raw) {
        let p;
        try {
            p = typeof raw === "string" ? JSON.parse(raw) : raw;
        } catch (e) {
            console.warn("ricescape: could not parse palette.json:", e);
            return;
        }
        const map = {
            mode: "mode", modeName: "name",
            bg: "bg", accent: "accent", panel: "panel", panelDark: "panel_dark",
            borderLight: "border_light", borderDark: "border_dark", stoneActive: "stone_active",
            parchment: "parchment", map: "map",
            text: "text", textShadow: "text_shadow", textAlt: "text_alt", textWhite: "text_white",
            chatText: "chat_text", chatInput: "chat_input", chatSystem: "chat_system",
            good: "good", warn: "warn", bad: "bad",
            orbHp: "orb_hp", orbPrayer: "orb_prayer", orbRun: "orb_run", orbSpec: "orb_spec",
            iconPath: "icon_path", logo1: "logo_1", logo2: "logo_2", logo3: "logo_3",
            uiFont: "ui_font", monoFont: "mono_font", iconFont: "icon_font"
        };
        for (const prop in map) {
            if (p[map[prop]] !== undefined) root[prop] = p[map[prop]];
        }
        const s = parseFloat(p.ui_scale);
        if (s > 0) root.scale = s;
    }
}
