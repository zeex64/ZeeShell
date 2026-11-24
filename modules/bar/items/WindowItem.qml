import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.bar

BarItem {
    interactive: false
    pad: 12

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: Hypr.activeTitle === "" ? "desktop" : "app-window"
        size: 16
        color: Theme.textDim
    }

    Txt {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, 300)
        text: Hypr.activeTitle === "" ? "Desktop" : Hypr.activeTitle
        elide: Text.ElideRight
        color: Theme.textDim
        font.weight: Font.Medium
    }
}
