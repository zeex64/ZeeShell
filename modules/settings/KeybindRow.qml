import QtQuick
import qs.config
import qs.components
import qs.services

// One line of the keybind list.
Item {
    id: root

    required property var row
    readonly property bool mine: row.kind === "managed"
    signal edit()

    width: parent ? parent.width : 0
    height: 48

    Column {
        anchors.left: parent.left
        anchors.right: side.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        opacity: root.row.disabled ? 0.55 : 1

        Txt {
            width: parent.width
            text: root.row.description
            elide: Text.ElideRight
            font.weight: Font.Medium
            font.strikeout: root.row.shadowed === true
        }

        Txt {
            width: parent.width
            text: root.row.detail
            elide: Text.ElideRight
            size: 11
            color: root.mine ? Theme.accent : Theme.textMute
        }
    }

    Row {
        id: side
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: Keybinds.caps(root.row.combo)

            Keycap {
                required property string modelData
                anchors.verticalCenter: parent.verticalCenter
                label: modelData
                dim: root.row.disabled
            }
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.row.combo === ""
            text: "No keys"
            size: 12
            color: Theme.textMute
        }

        Item { width: 4; height: 1 }

        IconBtn {
            anchors.verticalCenter: parent.verticalCenter
            size: 30
            icon: "pencil-simple"
            visible: root.row.movable && root.row.shadowed !== true && root.row.mouse !== true
            onClicked: root.edit()
        }

        // Yours: delete, or put the original back. From the config: switch it off.
        IconBtn {
            anchors.verticalCenter: parent.verticalCenter
            size: 30
            icon: root.mine ? (root.row.restorable ? "arrow-counter-clockwise" : "trash") : "prohibit"
            tint: root.mine && !root.row.restorable ? Theme.danger : Theme.textDim
            visible: root.row.shadowed !== true
            onClicked: root.mine ? Keybinds.remove(root.row.id) : Keybinds.disable(root.row)
        }
    }
}
