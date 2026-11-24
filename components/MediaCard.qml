import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services

Card {
    id: root

    readonly property var player: Players.active

    implicitHeight: 104
    implicitWidth: 380

    ClippingRectangle {
        id: art
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 80
        height: 80
        radius: Theme.radius.sm
        color: Theme.accentSoft

        Icon {
            anchors.centerIn: parent
            name: "music-notes"
            fill: true
            size: 30
            color: Theme.softInk
        }

        Image {
            anchors.fill: parent
            source: Players.art
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(200, 200)
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { Anim { ms: 400 } }
        }
    }

    Column {
        anchors.left: art.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Txt {
            width: parent.width
            text: Players.title || "Nothing playing"
            font.weight: Font.DemiBold
            size: 14
            elide: Text.ElideRight
        }

        Txt {
            width: parent.width
            text: Players.artist
            color: Theme.textDim
            size: 12
            elide: Text.ElideRight
        }

        Item {
            width: parent.width
            height: 14

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Theme.layerHi

                Rectangle {
                    width: parent.width * Players.progress
                    height: parent.height
                    radius: 2
                    color: Theme.accent
                    Behavior on width { Anim { ms: 900; easing.type: Easing.Linear } }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.player !== null && root.player.canSeek && root.player.length > 0
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: e => root.player.position = e.x / width * root.player.length
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            IconBtn { icon: "skip-back"; fill: true; size: 30; onClicked: Players.previous() }
            IconBtn { icon: Players.playing ? "pause" : "play"; fill: true; active: true; size: 30; onClicked: Players.toggle() }
            IconBtn { icon: "skip-forward"; fill: true; size: 30; onClicked: Players.next() }
        }
    }
}
