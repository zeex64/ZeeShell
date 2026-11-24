import QtQuick
import qs.config
import qs.components

// Segmented control with a sliding highlight. options: [[key, label], ...]
Rectangle {
    id: root

    property var options: []
    property var current
    signal picked(var key)

    readonly property int index: Math.max(0, options.findIndex(o => o[0] === current))

    implicitHeight: 34
    implicitWidth: row.implicitWidth + 6
    width: implicitWidth
    height: implicitHeight
    radius: Math.min(Theme.radius.full, height / 2)
    color: Theme.layerHi

    Rectangle {
        readonly property Item target: seg.count > root.index ? seg.itemAt(root.index) : null

        x: 3 + (target ? target.x : 0)
        y: 3
        width: target ? target.width : 0
        height: parent.height - 6
        radius: Math.min(Theme.radius.full, height / 2)
        color: Theme.accent

        Behavior on x { Anim { ms: 340; curve: Theme.curve.springSoft } }
        Behavior on width { Anim { ms: 260 } }
    }

    Row {
        id: row
        x: 3
        y: 3
        height: parent.height - 6

        Repeater {
            id: seg
            model: root.options

            Item {
                id: item
                required property var modelData
                required property int index
                width: label.implicitWidth + 26
                height: row.height

                Txt {
                    id: label
                    anchors.centerIn: parent
                    text: item.modelData[1]
                    size: 12.5
                    font.weight: Font.DemiBold
                    color: item.index === root.index ? Theme.accentInk : Theme.textDim
                    Behavior on color { CAnim {} }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(item.modelData[0])
                }
            }
        }
    }
}
