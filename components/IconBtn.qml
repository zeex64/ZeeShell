import QtQuick
import qs.config

Rectangle {
    id: root

    property string icon: "circle"
    property bool fill: false
    property bool active: false
    property bool flat: true
    property real size: 34
    property real iconSize: Math.round(size * 0.52)
    property color tint: Theme.text
    property alias hovered: layer.containsMouse

    signal clicked()
    signal rightClicked()

    implicitWidth: size
    implicitHeight: size
    radius: Math.min(Theme.radius.full, size / 2)
    color: active ? Theme.accent : flat ? "transparent" : Theme.layer
    scale: layer.pressed ? 0.88 : 1

    Behavior on color { CAnim {} }
    Behavior on scale { Anim { ms: 320; curve: Theme.curve.spring } }

    Icon {
        anchors.centerIn: parent
        name: root.icon
        fill: root.fill || root.active
        size: root.iconSize
        color: root.active ? Theme.accentInk : root.tint

        Behavior on color { CAnim {} }
    }

    StateLayer {
        id: layer
        tint: root.active ? Theme.accentInk : Theme.text
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: e => e.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}
