// A Nerd Font icon with the OSRS drop shadow. `code` is the codepoint.
import QtQuick

ShadowText {
    property int code: 0

    text: code > 0 ? String.fromCodePoint(code) : ""
    family: Theme.iconFont
    bold: false
    color: Theme.textWhite
    pixelSize: 16
}
