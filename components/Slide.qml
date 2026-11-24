import QtQuick
import qs.config

// Chunky slider with an icon riding inside the fill.
Item {
    id: root

    property real value: 0 // 0..1
    property string icon: ""
    property real step: 0.05
    property bool dimmed: false
    readonly property bool dragging: area.pressed

    signal moved(real value)
    signal iconClicked()

    implicitHeight: 40
    implicitWidth: 240

    Rectangle {
        id: track
        anchors.fill: parent
        radius: Math.min(Theme.radius.full, height / 2)
        color: Theme.layer

        Rectangle {
            id: fill
            height: parent.height
            width: Math.max(parent.height, parent.width * Math.min(1, Math.max(0, root.value)))
            radius: parent.radius
            color: root.dimmed ? Theme.surfaceTop : Theme.accent

            Behavior on width { enabled: !root.dragging; Anim { ms: 240 } }
            Behavior on color { CAnim {} }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: fill.width - width - 12
            width: 4
            height: area.pressed ? 22 : 16
            radius: 2
            color: root.dimmed ? Theme.textMute : Theme.accentInk
            opacity: 0.55
            visible: fill.width > 64

            Behavior on height { Anim { ms: 200 } }
        }
    }

    MouseArea {
        id: area

        function apply(mx) {
            const h = root.height;
            root.moved(Math.min(1, Math.max(0, (mx - h / 2) / Math.max(1, root.width - h))));
        }

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: e => apply(e.x)
        onPositionChanged: e => { if (pressed) apply(e.x); }
        onWheel: e => root.moved(Math.min(1, Math.max(0, root.value + (e.angleDelta.y > 0 ? root.step : -root.step))))
    }

    Icon {
        visible: root.icon !== ""
        x: (root.height - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: 18
        fill: true
        color: root.dimmed ? Theme.textDim : Theme.accentInk

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }
}
