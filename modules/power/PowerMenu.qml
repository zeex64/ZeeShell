import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

Overlay {
    id: ov

    open: Ui.active === "power"
    layerName: "power"
    dim: true
    onDismiss: Ui.hide()

    Item {
        id: root

        readonly property Item panel: sheet
        property int current: 0
        property int armed: -1

        readonly property var actions: [
            { label: "Lock", icon: "lock", key: "L", confirm: false, run: () => { Ui.hide(); Ui.locked = true; } },
            { label: "Sleep", icon: "moon", key: "S", confirm: false, run: () => { Ui.hide(); Quickshell.execDetached(["systemctl", "suspend"]); } },
            { label: "Log out", icon: "sign-out", key: "O", confirm: true, run: () => Quickshell.execDetached(["sh", "-c", "loginctl terminate-session \"$XDG_SESSION_ID\" || hyprctl dispatch exit"]) },
            { label: "Restart", icon: "arrow-clockwise", key: "R", confirm: true, run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
            { label: "Shut down", icon: "power", key: "P", confirm: true, run: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
        ]

        function trigger(i) {
            current = i;
            const a = actions[i];
            if (a.confirm && armed !== i) { armed = i; return; }
            a.run();
        }

        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) { current = (current + 1) % actions.length; armed = -1; }
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) { current = (current + actions.length - 1) % actions.length; armed = -1; }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) trigger(current);
            else {
                const i = actions.findIndex(a => a.key === e.text.toUpperCase());
                if (i < 0) return;
                trigger(i);
            }
            e.accepted = true;
        }

        Panel {
            id: sheet

            anchors.centerIn: parent
            width: row.implicitWidth + 40
            height: col.implicitHeight + 44
            opacity: ov.progress
            scale: 0.92 + 0.08 * ov.progress

            Column {
                id: col
                anchors.centerIn: parent
                spacing: 18

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 2

                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.armed >= 0 ? root.actions[root.armed].label + "?" : "See you soon, " + SysInfo.user
                        size: 19
                        font.weight: Font.Bold
                    }

                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.armed >= 0 ? "Press again to confirm, Esc to cancel" : "Up for " + SysInfo.uptimeText()
                        color: Theme.textDim
                    }
                }

                Row {
                    id: row
                    spacing: 12

                    Repeater {
                        model: root.actions

                        Rectangle {
                            id: tile

                            required property var modelData
                            required property int index
                            readonly property bool current: root.current === index
                            readonly property bool armed: root.armed === index
                            readonly property real appear: Math.max(0, Math.min(1, ov.progress * 2 - index * 0.14))

                            width: 116
                            height: 128
                            radius: Theme.radius.lg
                            color: armed ? Theme.danger : current ? Theme.accent : Theme.layer
                            opacity: appear
                            scale: (0.8 + 0.2 * appear) * (hit.pressed ? 0.94 : 1)
                            transform: Translate { y: (1 - tile.appear) * 26 }

                            Behavior on color { CAnim {} }
                            Behavior on scale { enabled: ov.progress === 1; Anim { ms: 300; curve: Theme.curve.spring } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 10

                                Icon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    name: tile.armed ? "warning" : tile.modelData.icon
                                    size: 34
                                    fill: tile.current || tile.armed
                                    color: tile.armed || tile.current ? Theme.accentInk : Theme.text
                                }

                                Txt {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: tile.armed ? "Confirm" : tile.modelData.label
                                    font.weight: Font.DemiBold
                                    color: tile.armed || tile.current ? Theme.accentInk : Theme.text
                                }
                            }

                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 8
                                width: 20
                                height: 20
                                radius: Theme.radius.xs
                                color: Theme.alpha(tile.armed || tile.current ? Theme.accentInk : Theme.text, 0.12)

                                Txt {
                                    anchors.centerIn: parent
                                    text: tile.modelData.key
                                    size: 10.5
                                    font.weight: Font.Bold
                                    color: tile.armed || tile.current ? Theme.accentInk : Theme.textDim
                                }
                            }

                            MouseArea {
                                id: hit
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: { if (root.current !== tile.index) { root.current = tile.index; root.armed = -1; } }
                                onClicked: root.trigger(tile.index)
                            }
                        }
                    }
                }
            }
        }
    }
}
