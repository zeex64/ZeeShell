import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.bar

BarItem {
    pad: 12
    spacing: 12
    interactive: false

    component Stat: Row {
        property string icon
        property string value
        property bool hot: false

        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: parent.icon
            size: 15
            color: parent.hot ? Theme.danger : Theme.accent
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.value
            size: 12.5
            font.weight: Font.Medium
            font.features: { "tnum": 1 }
            color: Theme.textDim
        }
    }

    Stat { icon: "cpu"; value: SysInfo.cpu + "%"; hot: SysInfo.cpu > 90 }
    Stat { icon: "memory"; value: Math.round(SysInfo.mem * 100) + "%"; hot: SysInfo.mem > 0.9 }
    Stat { icon: "thermometer-simple"; value: SysInfo.cpuTemp + "°"; hot: SysInfo.cpuTemp > 85; visible: SysInfo.cpuTemp > 0 }
}
