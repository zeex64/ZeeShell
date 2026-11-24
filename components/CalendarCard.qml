import QtQuick
import qs.config
import qs.services

Card {
    id: root

    property int offset: 0 // months from the current one
    readonly property date today: Time.now
    readonly property date first: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    readonly property int lead: (first.getDay() + 6) % 7 // Monday first
    readonly property int days: new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate()
    readonly property real cell: (width - 28) / 7

    implicitWidth: 380
    implicitHeight: 62 + cell * 0.82 * Math.ceil((lead + days) / 7) + 14

    Behavior on implicitHeight { Anim { ms: 260 } }

    Txt {
        x: 18
        y: 14
        text: Qt.formatDate(root.first, "MMMM yyyy")
        font.weight: Font.Bold
        size: 14
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 10
        y: 8
        spacing: 2

        IconBtn { icon: "caret-left"; size: 28; onClicked: root.offset-- }
        IconBtn { icon: "dot-outline"; size: 28; visible: root.offset !== 0; onClicked: root.offset = 0 }
        IconBtn { icon: "caret-right"; size: 28; onClicked: root.offset++ }
    }

    Row {
        x: 14
        y: 42

        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]

            Txt {
                required property string modelData
                required property int index
                width: root.cell
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                size: 11
                font.weight: Font.DemiBold
                color: index >= 5 ? Theme.accent : Theme.textMute
            }
        }
    }

    Grid {
        x: 14
        y: 62
        columns: 7

        Repeater {
            model: root.lead + root.days

            Item {
                id: day

                required property int index
                readonly property int number: index - root.lead + 1
                readonly property bool isToday: root.offset === 0 && number === root.today.getDate()

                width: root.cell
                height: root.cell * 0.82

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) - 4
                    height: width
                    radius: Math.min(Theme.radius.full, width / 2)
                    color: Theme.accent
                    visible: day.isToday
                }

                Txt {
                    anchors.centerIn: parent
                    visible: day.number > 0
                    text: day.number
                    size: 12
                    font.weight: day.isToday ? Font.Bold : Font.Normal
                    color: day.isToday ? Theme.accentInk : day.index % 7 >= 5 ? Theme.textDim : Theme.text
                }
            }
        }
    }
}
