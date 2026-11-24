import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components

// A square tile in the start layout: an app icon or a shell action.
Item {
    id: root

    property string name: ""
    property string iconSource: ""
    property string glyph: ""
    property bool marked: false

    signal clicked()
    signal rightClicked()

    width: 104
    height: 96
    scale: hit.pressed ? 0.94 : 1

    Behavior on scale { Anim { ms: 280; curve: Theme.curve.spring } }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: Theme.radius.md
        color: hit.containsMouse ? Theme.layerHi : Theme.layer

        Behavior on color { CAnim {} }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 14
        spacing: 7

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40
            height: 40

            IconImage {
                anchors.fill: parent
                visible: root.glyph === ""
                source: root.glyph === "" ? root.iconSource : ""
            }

            Rectangle {
                anchors.fill: parent
                visible: root.glyph !== ""
                radius: Theme.radius.sm
                color: Theme.accent

                Icon {
                    anchors.centerIn: parent
                    name: root.glyph || "circle"
                    fill: true
                    size: 21
                    color: Theme.accentInk
                }
            }
        }

        Txt {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.name
            size: 11.5
            font.weight: Font.Medium
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    Icon {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 9
        visible: root.marked
        name: "push-pin"
        fill: true
        size: 11
        color: Theme.accent
    }

    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: e => e.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}
