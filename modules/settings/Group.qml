import QtQuick
import qs.config
import qs.components

// Titled card that stacks option rows.
Card {
    id: root

    default property alias content: col.data
    property string title: ""

    width: parent ? parent.width : 0
    implicitHeight: col.implicitHeight + 18
    height: implicitHeight

    Column {
        id: col
        x: 18
        y: 9
        width: parent.width - 36

        Txt {
            visible: root.title !== ""
            height: 30
            verticalAlignment: Text.AlignVCenter
            text: root.title
            size: 12
            font.weight: Font.Bold
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 0.8
            color: Theme.accent
        }
    }
}
