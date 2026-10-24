// Installed apps (for the inventory) and your favourites (the stone tabs).
// Favourites are saved to ~/.config/ricescape/favourites.json as desktop ids.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int maxFavourites: 13
    readonly property var defaultFavourites: [
        "kitty", "firefox", "org.gnome.Nautilus", "thunar", "chromium", "code",
        "discord", "steam", "spotify", "runelite", "obsidian", "org.pulseaudio.pavucontrol"
    ]

    readonly property var all: {
        const list = [];
        for (const e of DesktopEntries.applications.values) list.push(e);
        list.sort((a, b) => a.name.localeCompare(b.name));
        return list;
    }

    property var favouriteIds: []
    property bool fileLoaded: false
    readonly property var favourites: {
        // Re-evaluate when the app list changes, too.
        const _ = all.length;
        return favouriteIds.map(id => DesktopEntries.byId(id)).filter(e => e !== null && e !== undefined);
    }

    function search(query) {
        const q = (query || "").trim().toLowerCase();
        if (!q) return all;
        const starts = [], contains = [];
        for (const e of all) {
            const name = e.name.toLowerCase();
            if (name.startsWith(q)) starts.push(e);
            else if (name.includes(q)
                     || (e.genericName || "").toLowerCase().includes(q)
                     || (e.keywords || []).some(k => k.toLowerCase().includes(q))) contains.push(e);
        }
        return starts.concat(contains);
    }

    function iconSource(entry) {
        if (!entry || !entry.icon) return "";
        if (entry.icon.startsWith("/")) return "file://" + entry.icon;
        return Quickshell.iconPath(entry.icon, true);
    }

    function launch(entry) {
        if (!entry) return;
        if (entry.runInTerminal) {
            Quickshell.execDetached({
                command: ["kitty", "--"].concat(entry.command),
                workingDirectory: entry.workingDirectory || Quickshell.env("HOME")
            });
        } else {
            entry.execute();
        }
    }

    function isFavourite(entry) {
        return !!entry && favouriteIds.indexOf(entry.id) !== -1;
    }
    function addFavourite(entry) {
        if (!entry || isFavourite(entry)) return;
        favouriteIds = favouriteIds.concat([entry.id]).slice(-maxFavourites);
        save();
    }
    function removeFavourite(entry) {
        if (!entry) return;
        favouriteIds = favouriteIds.filter(id => id !== entry.id);
        save();
    }
    function moveFavourite(entry, delta) {
        const ids = favouriteIds.slice();
        const i = ids.indexOf(entry.id);
        const j = i + delta;
        if (i === -1 || j < 0 || j >= ids.length) return;
        ids.splice(i, 1);
        ids.splice(j, 0, entry.id);
        favouriteIds = ids;
        save();
    }

    function save() {
        file.setText(JSON.stringify(favouriteIds, null, 2) + "\n");
    }

    function useDefaults() {
        favouriteIds = defaultFavourites.filter(id => DesktopEntries.byId(id) !== null);
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/ricescape/favourites.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            root.fileLoaded = true;
            try {
                const ids = JSON.parse(text());
                if (Array.isArray(ids)) root.favouriteIds = ids.filter(id => typeof id === "string");
            } catch (e) {
                console.warn("ricescape: favourites.json is not valid JSON, using defaults");
                root.useDefaults();
            }
        }
        onLoadFailed: root.useDefaults()
    }

    // The app index loads after startup; fill in defaults once it has.
    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            if (root.favouriteIds.length === 0 && !root.fileLoaded) root.useDefaults();
        }
    }
}
