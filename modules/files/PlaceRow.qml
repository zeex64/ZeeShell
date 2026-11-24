import QtQuick
import qs.config
import qs.components
import qs.services

// A row in the explorer's sidebar: a place, a favourite, a drive or a server.
// Files can be dropped onto it when it has a folder behind it.
Item {
    id: root

    required property var win
    property string icon: "folder"
    property string label: ""
    property string detail: ""
    property string path: "" // empty: not reachable yet (a drive or server that is not connected)
    property bool removable: false // show an x that emits removed()
    property string action: "" // icon of an extra button on the right (eject, plug in)
    property real used: -1 // drives: bytes used, with `total`
    property real total: 0
    readonly property bool current: path !== "" && win.path === path
    readonly property bool offline: path === ""

    signal removed()
    signal acted()
    signal picked() // clicked while offline

    width: parent ? parent.width : 0
    height: used >= 0 || detail !== "" ? 50 : 36

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.sm
        color: drop.containsDrag ? Theme.accent : root.current ? Theme.accentSoft : "transparent"

        Behavior on color { CAnim {} }
    }

    StateLayer {
        id: hit
        radius: Theme.radius.sm
        showHover: !root.current
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: e => {
            if (root.offline) root.picked();
            else if (e.button === Qt.MiddleButton) root.win.newTab(root.path, true);
            else root.win.go(root.path);
        }
    }

    Icon {
        x: 10
        y: root.height > 40 ? 9 : (root.height - height) / 2
        name: root.icon
        fill: root.current
        size: 17
        color: drop.containsDrag ? Theme.accentInk : root.current ? Theme.softInk : root.offline ? Theme.textMute : Theme.textDim
    }

    Txt {
        x: 36
        y: root.height > 40 ? 7 : (root.height - height) / 2
        width: parent.width - 36 - buttons.width - 6
        text: root.label
        elide: Text.ElideRight
        font.weight: root.current ? Font.DemiBold : Font.Medium
        color: drop.containsDrag ? Theme.accentInk : root.current ? Theme.softInk : root.offline ? Theme.textDim : Theme.text
    }

    Txt {
        visible: root.detail !== ""
        x: 36
        y: 26
        width: parent.width - 36 - buttons.width - 6
        text: root.detail
        elide: Text.ElideRight
        size: 11
        color: drop.containsDrag ? Theme.accentInk : root.current ? Theme.softInk : Theme.textMute
    }

    // how full a connected drive is
    Rectangle {
        visible: root.used >= 0
        x: 36
        y: 43
        width: parent.width - 36 - buttons.width - 10
        height: 3
        radius: 1.5
        color: Theme.layerHi

        Rectangle {
            width: parent.width * Math.min(1, root.total > 0 ? root.used / root.total : 0)
            height: parent.height
            radius: 1.5
            color: root.total > 0 && root.used / root.total > 0.9 ? Theme.danger : Theme.accent
        }
    }

    Row {
        id: buttons
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        IconBtn {
            visible: root.action !== ""
            size: 26
            iconSize: 14
            icon: root.action || "circle"
            tint: root.current ? Theme.softInk : Theme.textDim
            onClicked: root.acted()
        }

        IconBtn {
            visible: root.removable && (hit.containsMouse || hovered)
            size: 24
            iconSize: 11
            icon: "x"
            tint: root.current ? Theme.softInk : Theme.textDim
            onClicked: root.removed()
        }
    }

    DropArea {
        id: drop
        anchors.fill: parent
        enabled: !root.offline
        keys: ["text/uri-list"]
        onDropped: d => {
            root.win.receive(d.urls, root.path, d.proposedAction === Qt.MoveAction);
            d.acceptProposedAction();
        }
    }
}
