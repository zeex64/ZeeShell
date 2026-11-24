import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.bar

// Network, Bluetooth, sound, battery and notifications. The one bar button
// that opens the quick settings panel.
BarItem {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery && battery.isLaptopBattery

    pad: 12
    spacing: 10
    active: Ui.active === "sidebar"
    onClicked: Ui.toggle("sidebar", screen)
    onRightClicked: Audio.toggleMute()
    onScrolled: dir => Audio.setVolume(Audio.volume + dir * 0.05)

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: Network.icon
        size: 16
        color: Network.connected ? Theme.text : Theme.textMute
    }

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        visible: Bluetooth.defaultAdapter !== null && Bluetooth.defaultAdapter.enabled
        name: Bluetooth.devices.values.some(d => d.connected) ? "bluetooth-connected" : "bluetooth"
        size: 16
    }

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: Audio.icon
        size: 16
        color: Audio.muted ? Theme.textMute : Theme.text
    }

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        visible: Audio.micMuted
        name: "microphone-slash"
        size: 16
        color: Theme.danger
    }

    Row {
        visible: root.hasBattery
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            readonly property real p: root.battery ? root.battery.percentage : 0
            name: root.battery && root.battery.state === UPowerDeviceState.Charging ? "battery-charging" : p > 0.8 ? "battery-full" : p > 0.55 ? "battery-high" : p > 0.3 ? "battery-medium" : p > 0.12 ? "battery-low" : "battery-warning"
            size: 17
            color: p < 0.15 ? Theme.danger : Theme.text
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round((root.battery ? root.battery.percentage : 0) * 100) + "%"
            size: 12
            font.weight: Font.Medium
        }
    }

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        height: 18

        Icon {
            anchors.centerIn: parent
            name: Notifs.dnd ? "bell-slash" : Notifs.count > 0 ? "bell-ringing" : "bell"
            size: 16
            color: Notifs.dnd ? Theme.textMute : Theme.text
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: -2
            width: 8
            height: 8
            radius: 4
            color: Theme.accent
            border.width: 1.5
            border.color: Theme.bg
            scale: Notifs.count > 0 && !Notifs.dnd ? 1 : 0

            Behavior on scale { Anim { ms: 360; curve: Theme.curve.spring } }
        }
    }
}
