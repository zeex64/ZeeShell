import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components
import qs.services

// Alt-Tab: the windows in the order they were last used. Hold Alt and press
// Tab to move along, let go to switch. State lives in services/Windows.qml.
Overlay {
    id: ov

    open: Windows.switcherShown
    layerName: "switcher"
    screen: Ui.focusedScreen()
    enterMs: 260
    exitMs: 90
    onDismiss: Windows.cancel()
    onAliveChanged: if (!alive) Windows.panelGone()

    Item {
        id: root

        readonly property Item panel: sheet
        readonly property real cardW: 236
        readonly property real thumbH: 150

        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Tab || e.key === Qt.Key_Right) Windows.step(1);
            else if (e.key === Qt.Key_Backtab || e.key === Qt.Key_Left) Windows.step(-1);
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) Windows.commit();
            else return;
            e.accepted = true;
        }
        // Letting go of Alt switches (also covered by a release bind in Hyprland).
        Keys.onReleased: e => {
            if (e.key === Qt.Key_Alt || e.key === Qt.Key_AltGr || e.key === Qt.Key_Super_L || e.key === Qt.Key_Meta || !(e.modifiers & (Qt.AltModifier | Qt.MetaModifier))) Windows.commit();
        }

        Panel {
            id: sheet

            anchors.centerIn: parent
            width: Math.min(root.width - 80, list.contentWidth + 40)
            height: root.thumbH + 96
            opacity: ov.progress
            scale: 0.94 + 0.06 * ov.progress

            ListView {
                id: list

                x: 20
                y: 20
                width: parent.width - 40
                height: parent.height - 40
                orientation: ListView.Horizontal
                spacing: 12
                clip: true
                interactive: false
                model: Windows.clients
                currentIndex: Windows.index
                highlightMoveDuration: Theme.dur(160)
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: width * 0.2
                preferredHighlightEnd: width * 0.8
                highlight: Rectangle { radius: Theme.radius.lg; color: Theme.accentSoft }

                delegate: Item {
                    id: card

                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem

                    width: root.cardW
                    height: list.height

                    WindowThumb {
                        x: 10
                        y: 10
                        width: parent.width - 20
                        height: root.thumbH - 10
                        client: card.modelData
                        live: ov.open
                        highlighted: card.current
                    }

                    Row {
                        x: 12
                        y: root.thumbH + 10
                        width: parent.width - 24
                        spacing: 8

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 18
                            source: Hypr.appIcon(card.modelData.cls)
                        }

                        Txt {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 26
                            text: card.modelData.title
                            elide: Text.ElideRight
                            size: 12.5
                            font.weight: card.current ? Font.DemiBold : Font.Medium
                            color: card.current ? Theme.softInk : Theme.text
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: Windows.index = card.index
                        onClicked: { Windows.index = card.index; Windows.commit(); }
                    }
                }
            }
        }
    }
}
