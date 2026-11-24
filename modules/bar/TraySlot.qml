import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components

// One tray icon. Left click activates, right click asks for its menu.
Item {
    id: slot

    required property var item
    property real size: 26
    property real iconSize: 17

    signal menu()
    signal activated()

    width: size
    height: size
    scale: area.pressed ? 0.86 : 1

    Behavior on scale { Anim { ms: 300; curve: Theme.curve.spring } }

    Rectangle {
        anchors.fill: parent
        radius: Math.min(Theme.radius.sm, width / 2)
        color: Theme.text
        opacity: area.containsMouse ? 0.1 : 0
        Behavior on opacity { Anim { ms: 160 } }
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: slot.iconSize
        source: slot.item.icon
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: e => {
            if (e.button === Qt.LeftButton && !slot.item.onlyMenu) { slot.item.activate(); slot.activated(); }
            else if (e.button === Qt.MiddleButton) { slot.item.secondaryActivate(); slot.activated(); }
            else if (slot.item.hasMenu) slot.menu();
        }
        onWheel: e => slot.item.scroll(e.angleDelta.y / 120, false)
    }
}
