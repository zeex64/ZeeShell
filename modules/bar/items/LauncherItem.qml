import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.bar

BarItem {
    id: root
    pad: 8
    active: Ui.active === "launcher"
    onClicked: Ui.toggle("launcher", screen)
    onRightClicked: Ui.settings()

    Logo {
        anchors.verticalCenter: parent.verticalCenter
        size: 22
        rotation: root.hovered ? 90 : 0
        Behavior on rotation { Anim { ms: 500; curve: Theme.curve.spring } }
    }
}
