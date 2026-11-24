import QtQuick
import qs.config
import qs.components

// A quick-settings toggle. `more` adds a chevron that opens a detail page.
Rectangle {
    id: root

    property string icon
    property string label
    property string detail: ""
    property bool active: false
    property bool more: false

    signal toggled()
    signal opened()

    readonly property color fg: active ? Theme.accentInk : Theme.text

    height: 62
    radius: Theme.radius.lg
    color: active ? Theme.accent : Theme.layer
    scale: main.pressed ? 0.96 : 1

    Behavior on color { CAnim {} }
    Behavior on scale { Anim { ms: 320; curve: Theme.curve.spring } }

    StateLayer {
        id: main
        tint: root.fg
        onClicked: root.toggled()
    }

    Rectangle {
        id: tile
        x: 11
        anchors.verticalCenter: parent.verticalCenter
        width: 38
        height: 38
        radius: Math.min(Theme.radius.full, 19)
        color: Theme.alpha(root.fg, root.active ? 0.14 : 0.07)

        Icon {
            anchors.centerIn: parent
            name: root.icon
            fill: root.active
            size: 19
            color: root.fg
        }
    }

    Column {
        anchors.left: tile.right
        anchors.leftMargin: 10
        anchors.right: chevron.visible ? chevron.left : parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Txt {
            width: parent.width
            text: root.label
            font.weight: Font.DemiBold
            color: root.fg
            elide: Text.ElideRight
        }

        Txt {
            width: parent.width
            visible: root.detail !== ""
            text: root.detail
            size: 11.5
            color: Theme.alpha(root.fg, 0.7)
            elide: Text.ElideRight
        }
    }

    Rectangle {
        id: chevron
        visible: root.more
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        height: 38
        radius: Math.min(Theme.radius.full, 15)
        color: Theme.alpha(root.fg, 0.08)

        Icon {
            anchors.centerIn: parent
            name: "caret-right"
            size: 14
            color: root.fg
        }

        StateLayer {
            tint: root.fg
            onClicked: root.opened()
        }
    }
}
