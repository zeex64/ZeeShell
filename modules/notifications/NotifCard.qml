import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components
import qs.services

// One notification. Used by both the popup stack and the sidebar history.
Item {
    id: root

    required property var entry
    property bool popup: false
    readonly property bool hasImage: entry.image !== ""
    readonly property string appIcon: {
        const i = entry.appIcon;
        if (i === "") return "";
        if (i.startsWith("/")) return "file://" + i;
        if (i.indexOf("://") >= 0) return i;
        return Quickshell.iconPath(i, true);
    }

    implicitHeight: card.height
    height: implicitHeight

    Rectangle {
        id: card

        width: parent.width
        height: body.implicitHeight + 24
        radius: Theme.radius.lg
        color: root.popup ? Theme.alpha(Theme.bg, Math.max(0.94, Theme.panelAlpha)) : Theme.layer
        border.width: 1
        border.color: root.entry.critical ? Theme.alpha(Theme.danger, 0.6) : Theme.border
        opacity: 1 - Math.min(1, Math.abs(x) / (width * 0.7))

        Behavior on x { enabled: !drag.pressed; Anim { ms: 300; curve: Theme.curve.springSoft } }

        MouseArea {
            id: drag

            anchors.fill: parent
            hoverEnabled: true
            drag.target: card
            drag.axis: Drag.XAxis
            onContainsMouseChanged: root.entry.hovered = containsMouse
            onReleased: {
                if (Math.abs(card.x) > card.width * 0.3) root.entry.dismiss();
                else card.x = 0;
            }
            onClicked: {
                const def = (root.entry.actions || []).find(a => a.identifier === "default");
                if (def) { def.invoke(); return; }
                if (root.popup) root.entry.popup = false;
            }
        }

        Row {
            id: body
            x: 14
            y: 12
            width: parent.width - 28
            spacing: 12

            Rectangle {
                id: tile
                width: 40
                height: 40
                radius: Theme.radius.sm
                color: root.entry.critical ? Theme.alpha(Theme.danger, 0.2) : Theme.accentSoft

                ClippingRectangle {
                    anchors.fill: parent
                    visible: root.hasImage
                    radius: parent.radius
                    color: "transparent"

                    Image {
                        anchors.fill: parent
                        source: root.hasImage ? root.entry.image : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(96, 96)
                    }
                }

                IconImage {
                    anchors.centerIn: parent
                    visible: !root.hasImage && root.appIcon !== ""
                    implicitSize: 24
                    source: root.hasImage ? "" : root.appIcon
                }

                Icon {
                    anchors.centerIn: parent
                    visible: !root.hasImage && root.appIcon === ""
                    name: root.entry.glyph
                    fill: true
                    size: 20
                    color: root.entry.critical ? Theme.danger : Theme.softInk
                }
            }

            Column {
                width: parent.width - tile.width - parent.spacing
                spacing: 3

                Item {
                    width: parent.width
                    height: 16

                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 60
                        text: (root.entry.appName || "Notification") + "  ·  " + Qt.formatTime(root.entry.time, Config.clock.use24h ? "HH:mm" : "h:mm AP")
                        size: 11.5
                        color: Theme.textMute
                        elide: Text.ElideRight
                    }

                    IconBtn {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        size: 22
                        iconSize: 12
                        icon: "x"
                        flat: false
                        opacity: drag.containsMouse || hovered ? 1 : 0
                        onClicked: root.entry.dismiss()

                        Behavior on opacity { Anim { ms: 160 } }
                    }
                }

                Txt {
                    width: parent.width
                    text: root.entry.summary
                    size: 13.5
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                Txt {
                    width: parent.width
                    text: root.entry.body
                    textFormat: Text.StyledText
                    color: Theme.textDim
                    wrapMode: Text.Wrap
                    maximumLineCount: root.popup ? 3 : 5
                    elide: Text.ElideRight
                    linkColor: Theme.accent
                    visible: text !== ""
                }

                Flow {
                    width: parent.width
                    spacing: 6
                    topPadding: 6
                    visible: buttons.count > 0

                    Repeater {
                        id: buttons
                        model: (root.entry.actions || []).filter(a => a.identifier !== "default" && a.text !== "")

                        Btn {
                            required property var modelData
                            implicitHeight: 30
                            pad: 12
                            text: modelData.text
                            onClicked: modelData.invoke()
                        }
                    }
                }
            }
        }
    }
}
