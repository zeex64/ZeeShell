import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.bar

BarItem {
    pad: 10
    active: Ui.active === "wallpaper"
    onClicked: Ui.toggle("wallpaper", screen)

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: "image"
        size: 17
        color: Theme.text
    }
}
