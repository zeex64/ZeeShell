import QtQuick
import qs.config

Rectangle {
    id: root

    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 46
    implicitHeight: 26
    radius: Math.min(Theme.radius.full, height / 2)
    color: checked ? Theme.accent : Theme.surfaceTop

    Behavior on color { CAnim {} }

    Rectangle {
        readonly property real pad: 4

        y: pad
        height: parent.height - pad * 2
        width: area.pressed ? height + 6 : height
        x: root.checked ? parent.width - width - pad : pad
        radius: Math.min(Theme.radius.full, height / 2)
        color: root.checked ? Theme.accentInk : Theme.textDim

        Behavior on x { Anim { ms: 340; curve: Theme.curve.spring } }
        Behavior on width { Anim { ms: 200 } }
        Behavior on color { CAnim {} }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
