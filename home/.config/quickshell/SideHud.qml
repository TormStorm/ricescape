// Bottom-right HUD: the inventory (every app, 28 to a page) above two rows of
// stone tabs (your favourite apps).
//
//   Click an item or stone      launch it
//   Right-click                 Choose Option: launch, (un)favourite, move
//   Type while it's open        search; Enter launches the first match
//   Scroll the inventory        change page
import QtQuick

Item {
    id: hud

    property bool active: true
    property bool grab: false
    readonly property bool typing: search.activeFocus && search.text.length > 0
    readonly property bool menuOpen: menu.visible

    property string hoverAction: ""
    property string hoverTarget: ""

    signal closeRequested()

    implicitWidth: 246
    implicitHeight: inv.height + 3 + tabs.height

    onGrabChanged: if (grab) search.forceActiveFocus()
    onActiveChanged: if (!active) { search.text = ""; search.focus = false; menu.close(); }

    readonly property int perPage: 28
    property int page: 0
    readonly property var results: Apps.search(search.text)
    readonly property int pageCount: Math.max(1, Math.ceil(results.length / perPage))
    readonly property var pageItems: results.slice(page * perPage, (page + 1) * perPage)
    onResultsChanged: page = 0

    function launch(entry) {
        if (!entry) return;
        Apps.launch(entry);
        search.text = "";
        hud.closeRequested();
    }

    function hover(action, entry) {
        hoverAction = entry ? action : "";
        hoverTarget = entry ? entry.name : "";
    }

    function openMenu(entry, item, mx, my) {
        if (!entry) return;
        const p = item.mapToItem(hud, mx, my);
        const fav = Apps.isFavourite(entry);
        const opts = [{ action: "Launch", target: entry.name, run: () => hud.launch(entry) }];
        if (fav) {
            opts.push({ action: "Move-left", target: entry.name, run: () => Apps.moveFavourite(entry, -1) });
            opts.push({ action: "Move-right", target: entry.name, run: () => Apps.moveFavourite(entry, 1) });
            opts.push({ action: "Unfavourite", target: entry.name, run: () => Apps.removeFavourite(entry) });
        } else {
            opts.push({ action: "Favourite", target: entry.name, run: () => Apps.addFavourite(entry) });
        }
        opts.push({ action: "Cancel", target: "", run: () => {} });
        menu.popup(opts, p.x, p.y, hud);
    }

    // An app icon, or its initial on a coin when no icon exists.
    component AppIcon: Item {
        id: ai
        property var entry: null
        property int size: 26
        readonly property string source: entry ? Apps.iconSource(entry) : ""
        width: size
        height: size

        Image {
            anchors.fill: parent
            visible: ai.source.length > 0
            source: ai.source
            sourceSize: Qt.size(ai.size * 2, ai.size * 2)
            smooth: true
            asynchronous: true
        }
        Rectangle {
            visible: ai.entry !== null && ai.source.length === 0
            anchors.centerIn: parent
            width: ai.size - 4
            height: ai.size - 4
            radius: width / 2
            color: Theme.borderDark
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: width / 2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(Theme.accent, 1.3) }
                    GradientStop { position: 1.0; color: Qt.darker(Theme.accent, 1.5) }
                }
            }
            ShadowText {
                anchors.centerIn: parent
                text: ai.entry ? ai.entry.name.charAt(0).toUpperCase() : ""
                color: Theme.textWhite
                pixelSize: Math.round(ai.size * 0.5)
            }
        }
    }

    // ---- Inventory ----------------------------------------------------------------
    StoneFrame {
        id: inv
        width: parent.width
        height: 284
        rim: 5
        fill: Theme.panel

        Item {
            id: area
            anchors.fill: parent

            // Mouseover text, like the top-left text in the game
            Row {
                x: 4
                y: 2
                height: 16
                spacing: 4
                visible: search.text.length === 0

                ShadowText {
                    text: hud.hoverAction || (search.activeFocus ? "Type to search" : "")
                    color: hud.hoverAction ? Theme.textWhite : Qt.darker(Theme.textWhite, 1.6)
                    pixelSize: 12
                }
                ShadowText {
                    width: Math.min(implicitWidth, area.width - 70)
                    text: hud.hoverTarget
                    color: "#FF9040"
                    pixelSize: 12
                    elide: Text.ElideRight
                }
            }
            Row {
                x: 4
                y: 2
                height: 16
                spacing: 4
                visible: search.text.length > 0

                ShadowText { text: "Search:"; color: Theme.textWhite; pixelSize: 12 }
                ShadowText { text: search.text + "*"; color: Theme.text; pixelSize: 12 }
            }

            TextInput {
                id: search
                width: 0
                height: 0
                opacity: 0
                Keys.onReturnPressed: hud.launch(hud.pageItems[0])
                Keys.onEnterPressed: hud.launch(hud.pageItems[0])
                Keys.onEscapePressed: {
                    if (text.length) text = "";
                    else { focus = false; hud.closeRequested(); }
                }
                Keys.onLeftPressed: hud.page = Math.max(0, hud.page - 1)
                Keys.onRightPressed: hud.page = Math.min(hud.pageCount - 1, hud.page + 1)
            }

            Grid {
                id: grid
                x: 2
                y: 20
                columns: 4
                columnSpacing: 0
                rowSpacing: 0

                Repeater {
                    model: hud.perPage

                    Item {
                        id: slot
                        required property int index
                        readonly property var entry: index < hud.pageItems.length ? hud.pageItems[index] : null
                        width: (area.width - 4) / 4
                        height: 33

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: 3
                            color: Theme.textWhite
                            opacity: slotMouse.containsMouse && slot.entry ? 0.12 : 0
                        }
                        AppIcon {
                            anchors.centerIn: parent
                            entry: slot.entry
                        }
                        MouseArea {
                            id: slotMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: slot.entry ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onContainsMouseChanged: hud.hover("Launch", containsMouse ? slot.entry : null)
                            onClicked: m => {
                                if (m.button === Qt.RightButton) hud.openMenu(slot.entry, slot, m.x, m.y);
                                else hud.launch(slot.entry);
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: grid
                acceptedButtons: Qt.NoButton
                onWheel: w => hud.page = w.angleDelta.y > 0 ? Math.max(0, hud.page - 1)
                                                            : Math.min(hud.pageCount - 1, hud.page + 1)
            }

            // Pages
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: area.height - 19
                spacing: 6
                visible: hud.pageCount > 1

                StoneButton {
                    width: 18
                    height: 16
                    radius: 3
                    onClicked: hud.page = Math.max(0, hud.page - 1)
                    Glyph { anchors.centerIn: parent; code: 0xF0141; pixelSize: 11 }
                }
                ShadowText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: (hud.page + 1) + " / " + hud.pageCount
                    color: Theme.text
                    pixelSize: 11
                }
                StoneButton {
                    width: 18
                    height: 16
                    radius: 3
                    onClicked: hud.page = Math.min(hud.pageCount - 1, hud.page + 1)
                    Glyph { anchors.centerIn: parent; code: 0xF0142; pixelSize: 11 }
                }
            }
        }
    }

    // ---- Stone tabs: favourites -----------------------------------------------------
    Grid {
        id: tabs
        y: inv.height + 3
        columns: 7
        spacing: 1

        Repeater {
            model: 14

            StoneButton {
                id: stone
                required property int index
                readonly property var entry: index > 0 && index - 1 < Apps.favourites.length
                                             ? Apps.favourites[index - 1] : null
                width: (hud.width - 6) / 7
                height: 36
                radius: 6
                active: index === 0
                onHoveredChanged: {
                    if (index === 0) hud.hover("Inventory", hovered ? { name: "(" + Apps.all.length + " apps)" } : null);
                    else hud.hover("Launch", hovered ? entry : null);
                }
                onClicked: {
                    if (index === 0) { search.text = ""; hud.page = 0; search.forceActiveFocus(); }
                    else hud.launch(entry);
                }
                onRightClicked: if (entry) hud.openMenu(entry, stone, width / 2, 0)

                Glyph {
                    visible: stone.index === 0
                    anchors.centerIn: parent
                    code: 0xF0E10
                    color: "#C9A060"
                    pixelSize: 20
                }
                AppIcon {
                    visible: stone.index > 0
                    anchors.centerIn: parent
                    entry: stone.entry
                    size: 22
                }
            }
        }
    }

    // Click anywhere else to dismiss the menu
    MouseArea {
        anchors.fill: parent
        visible: menu.visible
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: menu.close()
        z: 150
    }

    OptionMenu {
        id: menu
        onChosen: i => {
            const opt = options[i];
            close();
            opt.run();
        }
        onDismissed: close()
    }
}
