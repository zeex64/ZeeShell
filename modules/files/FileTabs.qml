import QtQuick
import qs.config
import qs.components
import qs.services

// The explorer's tab strip. Click to switch, middle-click or the x to close,
// drop files on a tab to move them into its folder.
Item {
    id: root

    required property var win
    readonly property real each: Math.max(110, Math.min(220, (width - 60) / Math.max(1, win.tabs.length) - 4))

    Row {
        x: 10
        anchors.bottom: parent.bottom
        spacing: 4

        Repeater {
            model: root.win.tabs

            Rectangle {
                id: tab

                required property var modelData
                required property int index
                readonly property bool current: index === root.win.current
                // The current tab's folder lives in the window, not in its snapshot.
                readonly property string folder: current ? root.win.path : modelData.path

                width: root.each
                height: 34
                topLeftRadius: Theme.radius.sm
                topRightRadius: Theme.radius.sm
                color: drop.containsDrag ? Theme.accent : current ? Theme.layerHi : hit.containsMouse ? Theme.layer : "transparent"

                Behavior on color { CAnim {} }
                Behavior on width { Anim { ms: 220 } }

                Icon {
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    name: tab.folder === Config.home ? "house" : "folder"
                    fill: tab.current
                    size: 15
                    color: drop.containsDrag ? Theme.accentInk : tab.current ? Theme.accent : Theme.textDim
                }

                Txt {
                    x: 32
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 32 - 30
                    text: tab.folder === Config.home ? "Home" : Files.nameOf(tab.folder)
                    elide: Text.ElideRight
                    size: 12.5
                    font.weight: tab.current ? Font.DemiBold : Font.Medium
                    color: drop.containsDrag ? Theme.accentInk : tab.current ? Theme.text : Theme.textDim
                }

                MouseArea {
                    id: hit
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: e => e.button === Qt.MiddleButton ? root.win.closeTab(tab.index) : root.win.switchTab(tab.index)
                }

                IconBtn {
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    visible: tab.current || hit.containsMouse || hovered
                    size: 22
                    iconSize: 11
                    icon: "x"
                    onClicked: root.win.closeTab(tab.index)
                }

                DropArea {
                    id: drop
                    anchors.fill: parent
                    keys: ["text/uri-list"]
                    onDropped: d => {
                        root.win.receive(d.urls, tab.folder, d.proposedAction === Qt.MoveAction);
                        d.acceptProposedAction();
                    }
                }
            }
        }

        IconBtn {
            anchors.verticalCenter: parent.verticalCenter
            size: 28
            iconSize: 14
            icon: "plus"
            onClicked: root.win.newTab("", false)
        }
    }

    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.outline }
}
