import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// Package updates. Listing them is done here; installing happens in a
// terminal, where the package manager can ask for your password itself.
Column {
    id: page

    readonly property int limit: 120

    spacing: 12
    Component.onCompleted: if (!Updates.checked) Updates.check()

    Card {
        width: parent.width
        height: 104
        color: Updates.checked && Updates.count > 0 ? Theme.accentSoft : Theme.layer

        Rectangle {
            id: badge
            x: 22
            anchors.verticalCenter: parent.verticalCenter
            width: 56
            height: 56
            radius: 28
            color: Theme.accent

            Spinner { anchors.centerIn: parent; visible: Updates.checking; size: 26; color: Theme.accentInk }
            Icon {
                anchors.centerIn: parent
                visible: !Updates.checking
                name: !Updates.supported ? "warning" : Updates.count > 0 ? "download-simple" : "check"
                size: 26
                color: Theme.accentInk
            }
        }

        Column {
            anchors.left: badge.right
            anchors.leftMargin: 18
            anchors.right: buttons.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Txt {
                width: parent.width
                text: !Updates.supported ? "Updates are not available here"
                    : Updates.checking ? "Looking for updates…"
                    : !Updates.checked ? "Not checked yet"
                    : Updates.count === 0 ? "Everything is up to date"
                    : Updates.count + (Updates.count === 1 ? " update is ready" : " updates are ready")
                size: 19
                font.weight: Font.Bold
                elide: Text.ElideRight
                color: Updates.checked && Updates.count > 0 ? Theme.softInk : Theme.text
            }

            Txt {
                width: parent.width
                text: !Updates.supported ? "This page understands pacman (with checkupdates from pacman-contrib). Use your distribution's own updater."
                    : Updates.checkedAt !== "" ? "Last checked at " + Updates.checkedAt : "Checking only reads the package lists; nothing is installed"
                size: 12
                wrapMode: Text.Wrap
                color: Theme.alpha(Updates.checked && Updates.count > 0 ? Theme.softInk : Theme.text, 0.65)
            }
        }

        Row {
            id: buttons
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Btn { visible: Updates.supported && !Updates.checking; text: "Check"; icon: "arrows-clockwise"; kind: "ghost"; onClicked: Updates.check() }
            Btn { visible: Updates.count > 0 && !Updates.checking; text: "Update now"; icon: "download-simple"; kind: "filled"; onClicked: Updates.install() }
        }
    }

    Group {
        visible: Updates.count > 0
        title: "How it is installed"

        InfoOpt {
            label: "Opens a terminal and runs"
            hint: "It asks for your password there, not here"
            value: Updates.command
            mono: true
        }
    }

    Group {
        visible: Updates.count > 0
        title: "Waiting"

        Repeater {
            model: Updates.items.slice(0, page.limit)

            Item {
                id: row
                required property var modelData

                width: parent.width
                height: 36

                Txt { anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.42; text: row.modelData.name; font.weight: Font.Medium; elide: Text.ElideRight }

                Txt {
                    x: parent.width * 0.44
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.42
                    text: row.modelData.from !== "" ? row.modelData.from + "  →  " + row.modelData.to : row.modelData.to
                    size: 12
                    mono: true
                    color: Theme.textDim
                    elide: Text.ElideRight
                }

                Txt { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: row.modelData.source; size: 11; color: Theme.textMute }
            }
        }

        Txt {
            visible: Updates.count > page.limit
            height: 34
            verticalAlignment: Text.AlignVCenter
            text: "and " + (Updates.count - page.limit) + " more"
            color: Theme.textMute
        }
    }
}
