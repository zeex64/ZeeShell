import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.bar

BarItem {
    pad: 10
    active: Ui.active === "power"
    onClicked: Ui.toggle("power", screen)

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: "power"
        size: 17
        color: Theme.danger
    }
}
