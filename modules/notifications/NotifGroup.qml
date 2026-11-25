import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// One app's notifications in the quick settings history: the newest card,
// with the rest stacked under it until the header is clicked.
Column {
    id: root

    required property var group
    readonly property var items: group.items
    readonly property bool many: items.length > 1
    readonly property bool open: Notifs.expanded[group.app] === true
    readonly property string rule: Notifs.rule(group.app)
    property bool menu: false

    spacing: 8

    Item {
        width: parent.width
        height: 30

        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: 4
            spacing: 8

            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: root.group.app
                size: 12.5
                font.weight: Font.DemiBold
                color: Theme.textDim
            }

            Rectangle {
                visible: root.many
                anchors.verticalCenter: parent.verticalCenter
                width: countText.implicitWidth + 12
                height: 18
                radius: 9
                color: Theme.layerHi

                Txt { id: countText; anchors.centerIn: parent; text: root.items.length; size: 11; font.weight: Font.DemiBold; color: Theme.textDim }
            }

            Icon {
                visible: root.rule !== ""
                anchors.verticalCenter: parent.verticalCenter
                name: root.rule === "mute" ? "bell-slash" : root.rule === "quiet" ? "bell-simple-slash" : "push-pin"
                size: 13
                color: Theme.textMute
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.many
            cursorShape: root.many ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: Notifs.toggleGroup(root.group.app)
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            IconBtn {
                visible: root.many
                size: 26
                iconSize: 13
                icon: root.open ? "caret-up" : "caret-down"
                onClicked: Notifs.toggleGroup(root.group.app)
            }
            IconBtn {
                size: 26
                iconSize: 14
                icon: "dots-three"
                active: root.menu
                onClicked: root.menu = !root.menu
            }
            IconBtn {
                size: 26
                iconSize: 13
                icon: "x"
                onClicked: Notifs.clearGroup(root.group.app)
            }
        }
    }

    // What this app is allowed to do.
    Flow {
        width: parent.width
        visible: root.menu
        spacing: 6

        Repeater {
            model: [["", "Normal", "bell"], ["keep", "Keep on screen", "push-pin"], ["quiet", "History only", "bell-simple-slash"], ["mute", "Mute", "bell-slash"]]

            Chip {
                required property var modelData
                icon: modelData[2]
                text: modelData[1]
                active: root.rule === modelData[0]
                onClicked: { Notifs.setRule(root.group.app, modelData[0]); root.menu = false; }
            }
        }
    }

    Repeater {
        model: root.open ? root.items : root.items.slice(0, 1)

        NotifCard {
            required property var modelData
            width: root.width
            entry: modelData
        }
    }

    Txt {
        visible: root.many && !root.open
        x: 6
        text: "+ " + (root.items.length - 1) + " more"
        size: 12
        color: Theme.textMute

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: Notifs.toggleGroup(root.group.app)
        }
    }
}
