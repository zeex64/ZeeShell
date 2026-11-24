import QtQuick
import qs.config

Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property bool active: false

    signal clicked()

    implicitHeight: 32
    implicitWidth: row.implicitWidth + 26
    radius: Math.min(Theme.radius.full, height / 2)
    color: active ? Theme.accent : Theme.layer
    scale: layer.pressed ? 0.94 : 1

    Behavior on color { CAnim {} }
    Behavior on scale { Anim { ms: 300; curve: Theme.curve.spring } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Icon {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: 15
            fill: root.active
            color: root.active ? Theme.accentInk : Theme.textDim
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            size: 12.5
            font.weight: Font.Medium
            color: root.active ? Theme.accentInk : Theme.textDim
        }
    }

    StateLayer {
        id: layer
        tint: root.active ? Theme.accentInk : Theme.text
        onClicked: root.clicked()
    }
}
