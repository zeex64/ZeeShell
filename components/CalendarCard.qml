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
    readonly property real gridHeight: cell * 0.82 * Math.ceil((lead + days) / 7)
    // The day whose events are listed; today until another day is clicked.
    property var picked: null
    readonly property date shown: picked || today
    readonly property var dayEvents: Calendar.active ? Calendar.eventsOn(shown) : []

    implicitWidth: 380
    implicitHeight: 62 + gridHeight + 14 + (Calendar.active ? agenda.implicitHeight + 6 : 0)

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
                readonly property date when: new Date(root.first.getFullYear(), root.first.getMonth(), number)
                readonly property bool isPicked: root.picked !== null && number > 0 && Calendar.key(root.picked) === Calendar.key(when)
                readonly property bool busy: number > 0 && Calendar.active && Calendar.days[Calendar.key(when)] === true

                width: root.cell
                height: root.cell * 0.82

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) - 4
                    height: width
                    radius: Math.min(Theme.radius.full, width / 2)
                    color: day.isToday ? Theme.accent : Theme.accentSoft
                    visible: day.isToday || day.isPicked
                }

                Rectangle {
                    visible: day.busy
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1
                    width: 4
                    height: 4
                    radius: 2
                    color: day.isToday ? Theme.accentInk : Theme.accent
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: day.number > 0 && Calendar.active
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.picked = day.isPicked || day.isToday ? null : day.when
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

    // What is on the shown day.
    Column {
        id: agenda

        visible: Calendar.active
        x: 18
        y: 62 + root.gridHeight + 10
        width: parent.width - 36
        spacing: 6

        Txt {
            text: (root.picked ? Qt.formatDate(root.shown, "dddd d MMMM") : "Today") + (root.dayEvents.length ? "" : "  ·  nothing planned")
            size: 12
            font.weight: Font.DemiBold
            color: Theme.textDim
        }

        Repeater {
            model: root.dayEvents.slice(0, 5)

            Row {
                required property var modelData
                width: agenda.width
                spacing: 10

                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 28; radius: 2; color: Theme.accent }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 13

                    Txt { width: parent.width; text: modelData.title; elide: Text.ElideRight; size: 12.5; font.weight: Font.DemiBold }
                    Txt {
                        width: parent.width
                        text: Calendar.timeText(modelData) + (modelData.location ? "  ·  " + modelData.location : "")
                        elide: Text.ElideRight
                        size: 11.5
                        color: Theme.textMute
                    }
                }
            }
        }

        Txt {
            visible: root.dayEvents.length > 5
            text: "+ " + (root.dayEvents.length - 5) + " more"
            size: 11.5
            color: Theme.textMute
        }
    }
}
