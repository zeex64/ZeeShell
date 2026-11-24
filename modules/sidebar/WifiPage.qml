import QtQuick
import qs.config
import qs.components
import qs.services

Column {
    id: root

    property string expanded: ""

    spacing: 8
    Component.onCompleted: Network.scan()

    Txt {
        visible: Network.error !== ""
        width: parent.width
        text: Network.error
        color: Theme.danger
        wrapMode: Text.Wrap
    }

    Txt {
        visible: !Network.wifiEnabled
        text: "Wi-Fi is turned off"
        color: Theme.textMute
    }

    Txt {
        visible: Network.wifiEnabled && Network.networks.length === 0
        text: Network.scanning ? "Scanning…" : "No networks found"
        color: Theme.textMute
    }

    Repeater {
        model: Network.wifiEnabled ? Network.networks : []

        Card {
            id: net

            required property var modelData
            readonly property bool open: root.expanded === modelData.ssid
            readonly property bool joining: Network.connecting === modelData.ssid

            width: root.width
            height: open ? 112 : 54
            color: modelData.active ? Theme.accentSoft : Theme.layer
            clip: true

            Behavior on height { Anim { ms: 300 } }

            StateLayer {
                height: 54
                anchors.fill: undefined
                width: parent.width
                onClicked: {
                    if (net.modelData.active) Network.disconnect();
                    else if (net.modelData.secure) root.expanded = net.open ? "" : net.modelData.ssid;
                    else Network.connect(net.modelData.ssid, "");
                }
            }

            Icon {
                id: sig
                x: 16
                y: 17
                name: net.modelData.strength > 66 ? "wifi-high" : net.modelData.strength > 33 ? "wifi-medium" : "wifi-low"
                size: 20
                color: net.modelData.active ? Theme.softInk : Theme.text
            }

            Txt {
                x: 48
                y: net.modelData.active || net.joining ? 9 : 18
                width: parent.width - 100
                text: net.modelData.ssid
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                color: net.modelData.active ? Theme.softInk : Theme.text
            }

            Txt {
                x: 48
                y: 28
                visible: net.modelData.active || net.joining
                text: net.joining ? "Connecting…" : "Connected · tap to disconnect"
                size: 11.5
                color: Theme.alpha(net.modelData.active ? Theme.softInk : Theme.text, 0.7)
            }

            Icon {
                anchors.right: parent.right
                anchors.rightMargin: 16
                y: 19
                visible: net.modelData.secure
                name: "lock-simple"
                size: 15
                color: Theme.textMute
            }

            Field {
                id: pass
                x: 12
                y: 60
                width: parent.width - 124
                implicitHeight: 40
                visible: net.height > 60
                password: true
                icon: "key"
                placeholder: "Password (blank if saved)"
                onAccepted: Network.connect(net.modelData.ssid, text)
            }

            Btn {
                anchors.right: parent.right
                anchors.rightMargin: 12
                y: 62
                visible: net.height > 60
                kind: "filled"
                text: "Connect"
                onClicked: Network.connect(net.modelData.ssid, pass.text)
            }
        }
    }
}
