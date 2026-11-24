import QtQuick
import qs.config
import qs.components

// One tile on the Settings home page: an area of the system with a line that
// says how it is set right now.
Card {
    id: root

    property string icon: "gear"
    property string title: ""
    property string status: ""
    property bool highlight: false

    signal clicked()

    height: 76
    color: highlight ? Theme.accentSoft : Theme.layer
    scale: layer.pressed ? 0.97 : 1

    Behavior on scale { Anim { ms: 240; curve: Theme.curve.spring } }
    Behavior on color { CAnim {} }

    Rectangle {
        id: chip
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 42
        height: 42
        radius: Math.min(Theme.radius.sm + 2, 21)
        color: root.highlight ? Theme.accent : Theme.alpha(Theme.accent, layer.containsMouse ? 0.3 : 0.16)

        Behavior on color { CAnim {} }

        Icon {
            anchors.centerIn: parent
            name: root.icon
            fill: layer.containsMouse || root.highlight
            size: 21
            color: root.highlight ? Theme.accentInk : Theme.accent
        }
    }

    Column {
        anchors.left: chip.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Txt {
            width: parent.width
            text: root.title
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            color: root.highlight ? Theme.softInk : Theme.text
        }

        Txt {
            width: parent.width
            text: root.status
            size: 11.5
            elide: Text.ElideRight
            color: Theme.alpha(root.highlight ? Theme.softInk : Theme.text, 0.62)
        }
    }

    StateLayer {
        id: layer
        onClicked: root.clicked()
    }
}
