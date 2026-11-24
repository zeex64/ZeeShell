import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.bar

// Toggles the Steam special workspace. Lit while it is showing; dim until
// Steam has a window.
BarItem {
    id: root

    shown: Config.steam.enabled
    pad: 10
    active: Hypr.steamShown
    onClicked: Hypr.toggleSteam()

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        height: 18

        Icon {
            anchors.centerIn: parent
            name: "steam-logo"
            fill: Hypr.steamShown
            size: 18
            color: Hypr.steamShown ? Theme.softInk : Hypr.steamRunning ? Theme.text : Theme.textMute
            scale: Hypr.steamShown ? 1.1 : 1

            Behavior on color { CAnim {} }
            Behavior on scale { Anim { ms: 360; curve: Theme.curve.spring } }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: -3
            width: 7
            height: 7
            radius: 3.5
            color: Theme.ok
            border.width: 1.5
            border.color: Theme.bg
            scale: Hypr.steamRunning && !Hypr.steamShown ? 1 : 0

            Behavior on scale { Anim { ms: 360; curve: Theme.curve.spring } }
        }
    }
}
