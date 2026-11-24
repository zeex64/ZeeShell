import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.bar

BarItem {
    id: root

    shown: Players.active !== null
    pad: 10
    spacing: 8
    active: Ui.active === "media"
    onClicked: Ui.popup("media", mapToItem(null, width / 2, 0).x, screen)
    onRightClicked: Players.toggle()
    onScrolled: dir => dir > 0 ? Players.next() : Players.previous()

    // Three bars that dance while music plays.
    Row {
        anchors.verticalCenter: parent.verticalCenter
        height: 14
        spacing: 2

        Repeater {
            model: 3

            Rectangle {
                id: beat
                required property int index

                anchors.bottom: parent.bottom
                width: 3
                radius: 1.5
                color: Theme.accent
                height: 4

                SequentialAnimation on height {
                    running: Players.playing
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) beat.height = 4

                    NumberAnimation { to: 14; duration: 300 + beat.index * 90; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 4; duration: 340 + beat.index * 70; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    Txt {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, 200)
        text: Players.title + (Players.artist !== "" ? "  ·  " + Players.artist : "")
        elide: Text.ElideRight
        font.weight: Font.Medium
        color: Theme.textDim
    }
}
