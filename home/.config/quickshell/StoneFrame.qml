// The bevelled stone frame every OSRS-style panel sits in:
// dark outline, a lit stone rim with rivets, then a recessed well.
import QtQuick

Item {
    id: frame

    property color fill: Theme.panel
    property int rim: 5            // thickness of the stone rim
    property int radius: 4
    property bool rivets: true
    property bool wellGradient: true
    default property alias content: inner.data

    // Outline
    Rectangle {
        anchors.fill: parent
        radius: frame.radius
        color: Theme.borderDark
    }

    // Stone rim, lit from the top
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: frame.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(Theme.borderLight, 1.25) }
            GradientStop { position: 0.5; color: Theme.borderLight }
            GradientStop { position: 1.0; color: Qt.darker(Theme.borderLight, 1.35) }
        }
    }

    // Rivets in the corners
    Repeater {
        model: frame.rivets ? 4 : 0

        Item {
            required property int index
            readonly property int size: Math.max(2, frame.rim - 3)

            width: size + 1
            height: size + 1
            x: index % 2 === 0 ? 3 : frame.width - width - 3
            y: index < 2 ? 3 : frame.height - height - 3

            Rectangle { x: 1; y: 1; width: parent.size; height: parent.size; color: Theme.borderDark }
            Rectangle { width: parent.size; height: parent.size; color: Qt.lighter(Theme.borderLight, 1.55) }
        }
    }

    // Recessed well: dark lip on top/left, light lip on bottom/right
    Rectangle {
        id: well
        anchors.fill: parent
        anchors.margins: frame.rim
        radius: Math.max(0, frame.radius - 2)
        color: Qt.lighter(Theme.borderLight, 1.3)

        Rectangle {
            anchors.fill: parent
            anchors.rightMargin: 1
            anchors.bottomMargin: 1
            radius: parent.radius
            color: Theme.borderDark
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: frame.wellGradient ? Qt.lighter(frame.fill, 1.08) : frame.fill }
                GradientStop { position: 1.0; color: frame.wellGradient ? Qt.darker(frame.fill, 1.12) : frame.fill }
            }
        }
    }

    Item {
        id: inner
        anchors.fill: well
        anchors.margins: 1
    }
}
