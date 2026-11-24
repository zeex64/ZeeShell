import QtQuick
import qs.config

// A scrollbar you can grab. Point `flick` at any Flickable, ListView or
// GridView and anchor this to its right edge. Drag the thumb, or click the
// track to jump there.
Item {
    id: root

    required property var flick
    readonly property real range: Math.max(1, flick.contentHeight - flick.height)
    readonly property real thumbHeight: Math.max(40, height * Math.min(1, flick.height / Math.max(1, flick.contentHeight)))
    readonly property real travel: Math.max(1, height - thumbHeight)
    readonly property bool hot: area.containsMouse || area.pressed

    width: 14
    visible: flick.contentHeight > flick.height + 1
    opacity: hot ? 1 : flick.moving ? 0.85 : 0.55

    Behavior on opacity { Anim { ms: 300 } }

    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 3
        width: root.hot ? 8 : 4
        radius: width / 2
        height: parent.height
        color: Theme.text
        opacity: root.hot ? 0.08 : 0

        Behavior on width { Anim { ms: 180 } }
        Behavior on opacity { Anim { ms: 180 } }
    }

    Rectangle {
        id: thumb
        anchors.right: parent.right
        anchors.rightMargin: 3
        width: root.hot ? 8 : 4
        radius: width / 2
        height: root.thumbHeight
        y: Math.max(0, Math.min(root.travel, (root.flick.contentY - root.flick.originY) / root.range * root.travel))
        color: area.pressed ? Theme.accent : Theme.textDim

        Behavior on width { Anim { ms: 180 } }
        Behavior on color { CAnim {} }
    }

    MouseArea {
        id: area

        property real grab: 0

        function moveTo(y) {
            const t = Math.max(0, Math.min(root.travel, y - grab));
            root.flick.contentY = root.flick.originY + t / root.travel * root.range;
        }

        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        onPressed: e => {
            // On the thumb: keep it under the pointer. On the track: centre the thumb there.
            grab = e.y >= thumb.y && e.y <= thumb.y + thumb.height ? e.y - thumb.y : thumb.height / 2;
            root.flick.cancelFlick();
            moveTo(e.y);
        }
        onPositionChanged: e => { if (pressed) moveTo(e.y); }
        onWheel: e => e.accepted = false
    }
}
