import QtQuick
import qs.config
import qs.components

// The explorer's right-click menu, drawn inside the window.
Item {
    id: root

    required property var win
    readonly property var request: win.menu
    readonly property bool open: request !== null

    visible: open || sheet.opacity > 0

    MouseArea {
        anchors.fill: parent
        enabled: root.open
        acceptedButtons: Qt.AllButtons
        onPressed: root.win.menu = null
        onWheel: e => e.accepted = true
    }

    Panel {
        id: sheet

        // Stay inside the window.
        x: root.request ? Math.max(8, Math.min(root.width - width - 8, root.request.x)) : x
        y: root.request ? Math.max(8, Math.min(root.height - height - 8, root.request.y)) : y
        width: 250
        height: col.implicitHeight + 14
        radius: Theme.radius.md
        color: Theme.alpha(Theme.bg, Math.max(0.94, Theme.panelAlpha))
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.94
        transformOrigin: Item.TopLeft

        Behavior on opacity { Anim { ms: 140 } }
        Behavior on scale { Anim { ms: 240; curve: Theme.curve.springSoft } }

        Column {
            id: col
            x: 7
            y: 7
            width: parent.width - 14

            Repeater {
                model: root.request ? root.request.items : []

                Item {
                    id: row
                    required property var modelData
                    readonly property bool line: modelData.separator === true

                    width: col.width
                    height: line ? 9 : 34

                    Rectangle {
                        visible: row.line
                        anchors.centerIn: parent
                        width: parent.width - 14
                        height: 1
                        color: Theme.outlineHi
                    }

                    Icon {
                        visible: !row.line
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        name: row.modelData.icon || "circle"
                        size: 16
                        color: row.modelData.danger ? Theme.danger : Theme.textDim
                    }

                    Txt {
                        visible: !row.line
                        x: 36
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.label || ""
                        color: row.modelData.danger ? Theme.danger : Theme.text
                    }

                    Txt {
                        visible: !row.line && !!row.modelData.hint
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.hint || ""
                        size: 11
                        color: Theme.textMute
                    }

                    Icon {
                        visible: !row.line && !!row.modelData.mark
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        name: row.modelData.mark || "check"
                        size: 14
                        color: Theme.accent
                    }

                    StateLayer {
                        enabled: !row.line
                        radius: Theme.radius.sm
                        tint: row.modelData.danger ? Theme.danger : Theme.text
                        onClicked: {
                            const run = row.modelData.run;
                            root.win.menu = null;
                            if (run) run();
                        }
                    }
                }
            }
        }
    }
}
