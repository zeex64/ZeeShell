import QtQuick
import qs.config

// Text button. kind: filled | tonal | ghost | danger
Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property string kind: "tonal"
    property real pad: 16
    property alias hovered: layer.containsMouse

    signal clicked()

    readonly property color fg: kind === "filled" ? Theme.accentInk : kind === "danger" ? Theme.danger : kind === "tonal" ? Theme.softInk : Theme.text

    implicitWidth: row.implicitWidth + pad * 2
    implicitHeight: 36
    radius: Math.min(Theme.radius.full, height / 2)
    color: kind === "filled" ? Theme.accent : kind === "tonal" ? Theme.accentSoft : kind === "danger" ? Theme.alpha(Theme.danger, 0.14) : Theme.layer
    opacity: enabled ? 1 : 0.45
    scale: layer.pressed ? 0.95 : 1

    Behavior on color { CAnim {} }
    Behavior on scale { Anim { ms: 320; curve: Theme.curve.spring } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Icon {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: 16
            color: root.fg
        }

        Txt {
            visible: root.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.fg
            font.weight: Font.DemiBold
        }
    }

    StateLayer {
        id: layer
        tint: root.fg
        onClicked: root.clicked()
    }
}
