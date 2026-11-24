import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.bar

BarItem {
    pad: 10
    active: Ui.active === "keybinds"
    onClicked: Ui.toggle("keybinds", screen)

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: "keyboard"
        size: 17
        color: Theme.text
    }
}
