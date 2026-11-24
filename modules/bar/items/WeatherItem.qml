import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.bar

BarItem {
    pad: 12
    onClicked: Ui.popup("calendar", mapToItem(null, width / 2, 0).x, screen)
    onRightClicked: Weather.refresh()

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: Weather.icon
        fill: true
        size: 17
        color: Theme.accent
    }

    Txt {
        anchors.verticalCenter: parent.verticalCenter
        text: Weather.tempText
        font.weight: Font.DemiBold
    }
}
