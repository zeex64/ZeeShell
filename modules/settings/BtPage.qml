import Quickshell
import Quickshell.Bluetooth
import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.sidebar as Side

// Bluetooth: the adapter, devices in range, and the ones already paired.
Column {
    id: page

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var paired: Bluetooth.devices.values.filter(d => d.paired)

    spacing: 12

    Group {
        title: "Bluetooth"

        Opt {
            visible: page.adapter === null
            label: "No Bluetooth adapter found"
            hint: "Plug one in, or check that the bluetooth service is running"
        }

        ToggleOpt {
            visible: page.adapter !== null
            label: "Bluetooth"
            hint: page.adapter ? (page.adapter.enabled ? "On as “" + page.adapter.name + "”" : "Turned off") : ""
            checked: page.adapter !== null && page.adapter.enabled
            onToggled: v => { if (page.adapter) page.adapter.enabled = v; }
        }

        ToggleOpt {
            visible: page.adapter !== null && page.adapter.enabled
            label: "Visible to other devices"
            hint: "Needed while pairing from a phone or another computer"
            checked: page.adapter !== null && page.adapter.discoverable
            onToggled: v => { if (page.adapter) page.adapter.discoverable = v; }
        }
    }

    Group {
        visible: page.adapter !== null && page.adapter.enabled
        title: "Devices"

        Side.BluetoothPage {
            width: parent.width
            topPadding: 4
            bottomPadding: 8
        }
    }

    Group {
        visible: page.paired.length > 0
        title: "Paired"

        Repeater {
            model: page.paired

            Opt {
                id: known
                required property var modelData
                label: modelData.name || modelData.address
                hint: (modelData.connected ? "Connected" : "Not connected") + (modelData.batteryAvailable ? "  ·  battery " + Math.round(modelData.battery * 100) + "%" : "")

                Btn {
                    text: known.modelData.connected ? "Disconnect" : "Connect"
                    kind: "ghost"
                    onClicked: known.modelData.connected ? known.modelData.disconnect() : known.modelData.connect()
                }

                IconBtn { icon: "trash"; flat: false; tint: Theme.danger; onClicked: known.modelData.forget() }
            }
        }
    }
}
