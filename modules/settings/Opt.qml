import QtQuick
import qs.config
import qs.components

// One settings row: label + hint on the left, controls on the right.
Item {
    id: root

    property string label: ""
    property string hint: ""
    default property alias control: slot.data

    width: parent ? parent.width : 0
    implicitHeight: Math.max(52, text.implicitHeight + 18)
    height: implicitHeight

    Column {
        id: text
        anchors.left: parent.left
        anchors.right: slot.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Txt { width: parent.width; text: root.label; font.weight: Font.Medium; elide: Text.ElideRight }
        Txt { width: parent.width; visible: root.hint !== ""; text: root.hint; size: 11.5; color: Theme.textMute; wrapMode: Text.Wrap }
    }

    Row {
        id: slot
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
    }
}
