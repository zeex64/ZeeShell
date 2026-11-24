import Quickshell.Bluetooth
import QtQuick
import qs.config
import qs.components
import qs.services

Column {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: Bluetooth.devices.values.slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))

    spacing: 8
    Component.onCompleted: if (adapter && adapter.enabled) adapter.discovering = true
    Component.onDestruction: if (adapter && adapter.discovering) adapter.discovering = false

    Txt {
        visible: !root.adapter
        text: "No Bluetooth adapter found"
        color: Theme.textMute
    }

    Txt {
        visible: root.adapter !== null && !root.adapter.enabled
        text: "Bluetooth is turned off"
        color: Theme.textMute
    }

    Txt {
        visible: root.adapter !== null && root.adapter.enabled && root.devices.length === 0
        text: "Looking for devices…"
        color: Theme.textMute
    }

    Repeater {
        model: root.adapter && root.adapter.enabled ? root.devices : []

        Card {
            id: dev

            required property var modelData
            readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting || modelData.pairing

            width: root.width
            height: 56
            color: modelData.connected ? Theme.accentSoft : Theme.layer

            StateLayer {
                onClicked: {
                    if (dev.modelData.connected) dev.modelData.disconnect();
                    else if (dev.modelData.paired) dev.modelData.connect();
                    else dev.modelData.pair();
                }
            }

            Icon {
                x: 16
                anchors.verticalCenter: parent.verticalCenter
                name: {
                    const i = dev.modelData.icon;
                    if (/head|audio/.test(i)) return "headphones";
                    if (/mouse/.test(i)) return "mouse";
                    if (/keyboard/.test(i)) return "keyboard";
                    if (/phone/.test(i)) return "device-mobile";
                    if (/gaming|joy/.test(i)) return "game-controller";
                    if (/computer/.test(i)) return "laptop";
                    return "bluetooth";
                }
                size: 20
                color: dev.modelData.connected ? Theme.softInk : Theme.text
            }

            Column {
                x: 48
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 120

                Txt {
                    width: parent.width
                    text: dev.modelData.name || dev.modelData.address
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    color: dev.modelData.connected ? Theme.softInk : Theme.text
                }

                Txt {
                    text: dev.busy ? "Working…" : dev.modelData.connected ? "Connected" : dev.modelData.paired ? "Paired" : "Tap to pair"
                    size: 11.5
                    color: Theme.alpha(dev.modelData.connected ? Theme.softInk : Theme.text, 0.65)
                }
            }

            Txt {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                visible: dev.modelData.batteryAvailable
                text: Math.round(dev.modelData.battery * 100) + "%"
                size: 12
                font.weight: Font.DemiBold
                color: dev.modelData.connected ? Theme.softInk : Theme.textDim
            }
        }
    }
}
