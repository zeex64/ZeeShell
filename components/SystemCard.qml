import QtQuick
import qs.config
import qs.services

Card {
    id: root

    implicitWidth: 380
    implicitHeight: 148

    component Gauge: Column {
        property real value
        property string label
        property string icon
        property string detail

        width: (root.width - 24) / 4
        spacing: 6

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 58
            height: 58

            Ring {
                anchors.fill: parent
                value: parent.parent.value
                color: parent.parent.value > 0.9 ? Theme.danger : Theme.accent
            }

            Txt {
                anchors.centerIn: parent
                text: Math.round(parent.parent.value * 100)
                font.weight: Font.Bold
                size: 14
                font.features: { "tnum": 1 }
            }
        }

        Txt { anchors.horizontalCenter: parent.horizontalCenter; text: parent.label; size: 11.5; font.weight: Font.DemiBold; color: Theme.textDim }
        Txt { anchors.horizontalCenter: parent.horizontalCenter; text: parent.detail; size: 10.5; color: Theme.textMute }
    }

    Row {
        x: 12
        y: 14

        Gauge { value: SysInfo.cpu / 100; label: "CPU"; detail: SysInfo.cpuTemp > 0 ? SysInfo.cpuTemp + "°C" : "" }
        Gauge { value: SysInfo.mem; label: "Memory"; detail: SysInfo.gib(SysInfo.memUsed) + " GB" }
        Gauge { value: SysInfo.hasGpu ? SysInfo.gpu / 100 : 0; label: "GPU"; detail: SysInfo.hasGpu ? SysInfo.gpuTemp + "°C" : "n/a" }
        Gauge { value: SysInfo.disk; label: "Disk"; detail: SysInfo.bytes(SysInfo.diskTotal - SysInfo.diskUsed) + " free" }
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        Row {
            spacing: 4
            Icon { anchors.verticalCenter: parent.verticalCenter; name: "arrow-down"; size: 12; color: Theme.accent }
            Txt { text: SysInfo.bytes(SysInfo.rx) + "/s"; size: 11.5; color: Theme.textDim; font.features: { "tnum": 1 } }
        }

        Row {
            spacing: 4
            Icon { anchors.verticalCenter: parent.verticalCenter; name: "arrow-up"; size: 12; color: Theme.accent }
            Txt { text: SysInfo.bytes(SysInfo.tx) + "/s"; size: 11.5; color: Theme.textDim; font.features: { "tnum": 1 } }
        }

        Row {
            spacing: 4
            Icon { anchors.verticalCenter: parent.verticalCenter; name: "clock-countdown"; size: 12; color: Theme.accent }
            Txt { text: "up " + SysInfo.uptimeText(); size: 11.5; color: Theme.textDim }
        }
    }
}
