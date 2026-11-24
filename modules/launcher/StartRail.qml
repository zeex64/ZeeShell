import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// The slim column down the left of the start layout: places you go often.
Rectangle {
    id: root

    property real corner: Theme.radius.xl

    width: 60
    topLeftRadius: corner
    bottomLeftRadius: corner
    color: Theme.alpha(Theme.surfaceHi, 0.35)

    Logo {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 16
        size: 30
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        spacing: 4

        IconBtn { size: 40; icon: "sliders-horizontal"; onClicked: Ui.show("sidebar") }
        IconBtn { size: 40; icon: "folder"; onClicked: { Ui.hide(); Quickshell.execDetached([Quickshell.shellPath("zeeshell"), "files"]); } }
        IconBtn { size: 40; icon: "image"; onClicked: Ui.show("wallpaper") }
        IconBtn { size: 40; icon: "gear"; onClicked: Ui.settings() }
        IconBtn { size: 40; icon: "lock"; onClicked: { Ui.hide(); Ui.locked = true; } }
        IconBtn { size: 40; icon: "power"; tint: Theme.danger; onClicked: Ui.show("power") }
    }
}
