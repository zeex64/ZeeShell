import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components
import qs.services

// Context menu for a tray icon, drawn in the shell's own style.
Overlay {
    id: ov

    open: Ui.active === "traymenu"
    layerName: "menu"
    enterMs: 300
    exitMs: 150
    onDismiss: Ui.hide()

    Item {
        id: root

        readonly property Item panel: sheet
        readonly property bool atTop: Config.bar.position === "top"
        readonly property real edge: Config.bar.height + (Config.bar.floating ? Config.bar.margin : 0) + 8
        property var stack: [Ui.menuHandle]

        QsMenuOpener {
            id: opener
            menu: root.stack[root.stack.length - 1]
        }

        Panel {
            id: sheet

            width: 264
            height: col.implicitHeight + 16
            x: Math.max(8, Math.min(root.width - width - 8, Ui.menuX - width / 2))
            y: root.atTop ? root.edge : root.height - root.edge - height
            radius: Theme.radius.lg
            opacity: ov.progress
            scale: 0.92 + 0.08 * ov.progress
            transformOrigin: root.atTop ? Item.Top : Item.Bottom

            Behavior on height { Anim { ms: 260 } }

            Column {
                id: col
                x: 8
                y: 8
                width: parent.width - 16

                Item {
                    visible: root.stack.length > 1
                    width: parent.width
                    height: 34

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 8
                        spacing: 8
                        Icon { name: "caret-left"; size: 15; color: Theme.textDim }
                        Txt { text: "Back"; color: Theme.textDim; font.weight: Font.Medium }
                    }

                    StateLayer {
                        radius: Theme.radius.sm
                        onClicked: root.stack = root.stack.slice(0, -1)
                    }
                }

                Repeater {
                    model: opener.children

                    Item {
                        id: row
                        required property var modelData

                        width: col.width
                        height: modelData.isSeparator ? 9 : 34
                        opacity: modelData.enabled || modelData.isSeparator ? 1 : 0.4

                        Rectangle {
                            visible: row.modelData.isSeparator
                            anchors.centerIn: parent
                            width: parent.width - 16
                            height: 1
                            color: Theme.outlineHi
                        }

                        Row {
                            visible: !row.modelData.isSeparator
                            anchors.verticalCenter: parent.verticalCenter
                            x: 10
                            spacing: 10

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: row.modelData.buttonType !== QsMenuButtonType.None
                                name: row.modelData.checkState === Qt.Checked ? "check-circle" : "circle"
                                fill: row.modelData.checkState === Qt.Checked
                                size: 16
                                color: row.modelData.checkState === Qt.Checked ? Theme.accent : Theme.textMute
                            }

                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: row.modelData.icon !== ""
                                implicitSize: 16
                                source: row.modelData.icon
                            }

                            Txt {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, col.width - 70)
                                text: row.modelData.text
                                elide: Text.ElideRight
                            }
                        }

                        Icon {
                            visible: !row.modelData.isSeparator && row.modelData.hasChildren
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            name: "caret-right"
                            size: 14
                            color: Theme.textDim
                        }

                        StateLayer {
                            enabled: !row.modelData.isSeparator && row.modelData.enabled
                            radius: Theme.radius.sm
                            onClicked: {
                                if (row.modelData.hasChildren) {
                                    root.stack = root.stack.concat([row.modelData]);
                                } else {
                                    row.modelData.triggered();
                                    Ui.hide();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
