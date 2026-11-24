import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components
import qs.services

// Opens under the bar's media item: artwork, seek bar, transport, and a
// switcher when more than one player is running.
Overlay {
    id: ov

    open: Ui.active === "media"
    layerName: "media"
    enterMs: 380
    exitMs: 180
    onDismiss: Ui.hide()

    Item {
        id: root

        readonly property Item panel: sheet
        readonly property bool atTop: Config.bar.position === "top"
        readonly property real edge: Config.bar.height + (Config.bar.floating ? Config.bar.margin : 0) + 8
        readonly property var player: Players.active

        Panel {
            id: sheet

            width: 360
            height: col.implicitHeight + 32
            x: Math.max(8, Math.min(root.width - width - 8, Ui.menuX - width / 2))
            y: root.atTop ? root.edge - (1 - ov.progress) * 16 : root.height - root.edge - height + (1 - ov.progress) * 16
            opacity: ov.progress
            scale: 0.94 + 0.06 * ov.progress
            transformOrigin: root.atTop ? Item.Top : Item.Bottom

            Column {
                id: col
                x: 16
                y: 16
                width: parent.width - 32
                spacing: 12

                ClippingRectangle {
                    width: parent.width
                    height: width * 0.62
                    radius: Theme.radius.md
                    color: Theme.accentSoft

                    Icon {
                        anchors.centerIn: parent
                        name: "music-notes"
                        fill: true
                        size: 54
                        color: Theme.softInk
                    }

                    Image {
                        anchors.fill: parent
                        source: Players.art
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(720, 720)
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { Anim { ms: 400 } }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 2

                    Txt {
                        width: parent.width
                        text: Players.title || "Nothing playing"
                        size: 16
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Txt {
                        width: parent.width
                        text: Players.artist
                        color: Theme.textDim
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }

                // seek bar
                Item {
                    width: parent.width
                    height: 34
                    visible: root.player !== null && root.player.length > 0

                    Rectangle {
                        id: track
                        width: parent.width
                        height: 6
                        radius: 3
                        color: Theme.layerHi

                        Rectangle {
                            width: Math.max(height, parent.width * Players.progress)
                            height: parent.height
                            radius: 3
                            color: Theme.accent
                            Behavior on width { Anim { ms: 900; easing.type: Easing.Linear } }
                        }
                    }

                    MouseArea {
                        width: parent.width
                        height: 18
                        y: -6
                        enabled: root.player !== null && root.player.canSeek
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        preventStealing: true
                        onClicked: e => root.player.position = e.x / width * root.player.length
                    }

                    Txt {
                        anchors.bottom: parent.bottom
                        text: root.player ? Players.time(root.player.position) : ""
                        size: 11.5
                        color: Theme.textMute
                        font.features: { "tnum": 1 }
                    }

                    Txt {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        text: root.player ? Players.time(root.player.length) : ""
                        size: 11.5
                        color: Theme.textMute
                        font.features: { "tnum": 1 }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 14

                    IconBtn { anchors.verticalCenter: parent.verticalCenter; icon: "skip-back"; fill: true; size: 40; onClicked: Players.previous() }
                    IconBtn { anchors.verticalCenter: parent.verticalCenter; icon: Players.playing ? "pause" : "play"; fill: true; active: true; size: 52; onClicked: Players.toggle() }
                    IconBtn { anchors.verticalCenter: parent.verticalCenter; icon: "skip-forward"; fill: true; size: 40; onClicked: Players.next() }
                }

                // which player
                Flow {
                    width: parent.width
                    spacing: 6
                    visible: Players.list.length > 1

                    Repeater {
                        model: Players.list

                        Chip {
                            required property var modelData
                            text: modelData.identity || "Player"
                            icon: modelData.isPlaying ? "play" : "pause"
                            active: modelData === Players.active
                            onClicked: Players.pick(modelData)
                        }
                    }
                }
            }
        }
    }
}
