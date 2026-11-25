import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components
import qs.services

// Every workspace at once, with live pictures of its windows. Click a window
// to go to it, click a workspace to switch, drag a window onto another
// workspace to move it there. Typing narrows the windows down.
Overlay {
    id: ov

    open: Ui.active === "overview"
    layerName: "overview"
    dim: true
    onDismiss: Ui.hide()
    onOpenChanged: if (open) Windows.refresh()
    onAliveChanged: if (!alive) Windows.panelGone()

    Item {
        id: root

        readonly property Item panel: sheet
        readonly property string query: search.text.trim().toLowerCase()
        readonly property var clients: Windows.clients

        readonly property int count: {
            let n = Math.max(1, Config.workspaces.count);
            for (const c of clients) n = Math.max(n, c.workspace);
            return Math.min(n, 12);
        }
        readonly property int cols: count <= 4 ? count : Math.ceil(count / 2)
        readonly property int rows: Math.ceil(count / cols)
        readonly property real gap: 18
        readonly property real label: 26

        // Tiles take the shape of the monitor the overview is on.
        readonly property var mon: {
            const name = Ui.screen ? Ui.screen.name : "";
            for (const m of Windows.monitors) if (m.name === name) return m;
            return { width: Ui.screen ? Ui.screen.width : 1920, height: Ui.screen ? Ui.screen.height : 1080 };
        }
        readonly property real aspect: mon.width / Math.max(1, mon.height)
        readonly property real tileH: Math.max(60, Math.min(
            (height * 0.86 - 130 - (rows - 1) * gap) / rows - label,
            (width * 0.92 - 56 - (cols - 1) * gap) / cols / aspect))
        readonly property real tileW: tileH * aspect

        readonly property var matches: query === "" ? clients
            : clients.filter(c => (c.title + " " + c.cls).toLowerCase().indexOf(query) >= 0)
        property int selected: 0
        readonly property var current: matches.length ? matches[Math.min(selected, matches.length - 1)] : null
        property var hovered: null

        onQueryChanged: selected = 0

        function isMatch(c) { return query === "" || matches.indexOf(c) >= 0; }

        // Focus follows once the overview has let go of the keyboard.
        function go(c) {
            if (!c) return;
            Windows.afterClose = c;
            Ui.hide();
        }

        function moved() { refreshSoon.restart(); }

        Timer { id: refreshSoon; interval: 260; onTriggered: Windows.refresh() }

        Panel {
            id: sheet

            anchors.centerIn: parent
            anchors.verticalCenterOffset: (1 - ov.progress) * 30
            width: Math.max(520, root.cols * root.tileW + (root.cols - 1) * root.gap + 56)
            height: grid.y + grid.height + 58
            opacity: ov.progress
            scale: 0.96 + 0.04 * ov.progress

            Field {
                id: search
                anchors.horizontalCenter: parent.horizontalCenter
                y: 20
                width: Math.min(parent.width - 48, 460)
                implicitHeight: 44
                icon: "magnifying-glass"
                placeholder: "Type to find a window"
                autoFocus: true
                onAccepted: root.go(root.current)
                onKey: e => {
                    const n = root.matches.length;
                    if (n === 0) return;
                    if (e.key === Qt.Key_Right || e.key === Qt.Key_Down || e.key === Qt.Key_Tab) root.selected = (root.selected + 1) % n;
                    else if (e.key === Qt.Key_Left || e.key === Qt.Key_Up || e.key === Qt.Key_Backtab) root.selected = (root.selected - 1 + n) % n;
                    else return;
                    e.accepted = true;
                }
            }

            Grid {
                id: grid

                x: 28
                y: search.y + search.height + 20
                columns: root.cols
                spacing: root.gap

                Repeater {
                    model: root.count

                    Item {
                        id: ws

                        required property int index
                        readonly property int num: index + 1
                        readonly property bool active: Hypr.activeId === num
                        readonly property var here: root.clients.filter(c => c.workspace === ws.num)
                            .sort((a, b) => (a.floating - b.floating) || (b.history - a.history))

                        width: root.tileW
                        height: root.tileH + root.label

                        Txt {
                            x: 4
                            height: root.label
                            verticalAlignment: Text.AlignVCenter
                            text: "Workspace " + ws.num + (ws.here.length ? "  ·  " + ws.here.length : "")
                            size: 12
                            font.weight: ws.active ? Font.DemiBold : Font.Medium
                            color: ws.active ? Theme.accent : Theme.textDim
                        }

                        Rectangle {
                            id: tile

                            y: root.label
                            width: root.tileW
                            height: root.tileH
                            radius: Theme.radius.md
                            color: drop.containsDrag ? Theme.accentSoft : Theme.layer
                            border.width: ws.active || drop.containsDrag ? 2 : 1
                            border.color: ws.active || drop.containsDrag ? Theme.accent : Theme.border
                            clip: true

                            Behavior on color { CAnim {} }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { Ui.hide(); Hypr.workspace(ws.num); }
                            }

                            DropArea {
                                id: drop
                                anchors.fill: parent
                                keys: ["zeewin"]
                                onDropped: d => {
                                    if (d.source && d.source.client) Windows.moveTo(d.source.client, ws.num);
                                    root.moved();
                                }
                            }

                            Txt {
                                anchors.centerIn: parent
                                visible: ws.here.length === 0
                                text: "Empty"
                                size: 12
                                color: Theme.textMute
                            }

                            Repeater {
                                model: ws.here

                                Item {
                                    id: win

                                    required property var modelData
                                    readonly property var m: Windows.monitor(modelData.monitor)
                                    readonly property real sx: tile.width / Math.max(1, m ? m.width : 1)
                                    readonly property real sy: tile.height / Math.max(1, m ? m.height : 1)
                                    readonly property bool picked: root.current === modelData
                                    readonly property bool hot: area.containsMouse

                                    x: modelData.fullscreen ? 0 : Math.max(0, (modelData.x - (m ? m.x : 0)) * sx)
                                    y: modelData.fullscreen ? 0 : Math.max(0, (modelData.y - (m ? m.y : 0)) * sy)
                                    width: Math.max(24, Math.min(tile.width - x, (modelData.fullscreen ? (m ? m.width : 0) : modelData.w) * sx))
                                    height: Math.max(18, Math.min(tile.height - y, (modelData.fullscreen ? (m ? m.height : 0) : modelData.h) * sy))
                                    opacity: root.isMatch(modelData) ? (area.drag.active ? 0.35 : 1) : 0.22
                                    scale: hot && !area.pressed ? 1.025 : 1

                                    Behavior on opacity { Anim { ms: 160 } }
                                    Behavior on scale { Anim { ms: 220; curve: Theme.curve.spring } }

                                    WindowThumb {
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        client: win.modelData
                                        live: ov.open
                                        highlighted: win.picked || win.hot
                                    }

                                    MouseArea {
                                        id: area
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                        drag.target: ghost
                                        drag.threshold: 8
                                        onContainsMouseChanged: root.hovered = containsMouse ? win.modelData : (root.hovered === win.modelData ? null : root.hovered)
                                        onPressed: e => {
                                            if (e.button !== Qt.LeftButton) return;
                                            const p = mapToItem(root, e.x, e.y);
                                            ghost.client = win.modelData;
                                            ghost.x = p.x - ghost.width / 2;
                                            ghost.y = p.y - ghost.height / 2;
                                        }
                                        onPositionChanged: if (drag.active && !ghost.dragging) ghost.dragging = true
                                        onReleased: {
                                            if (ghost.dragging) ghost.Drag.drop();
                                            ghost.dragging = false;
                                            ghost.client = null;
                                        }
                                        onClicked: e => {
                                            if (e.button === Qt.MiddleButton) { Windows.close(win.modelData); root.moved(); }
                                            else root.go(win.modelData);
                                        }
                                    }

                                    IconBtn {
                                        visible: win.hot && win.width > 70 && win.height > 44 && !area.drag.active
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 6
                                        size: 24
                                        iconSize: 12
                                        icon: "x"
                                        flat: false
                                        onClicked: { Windows.close(win.modelData); root.moved(); }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // What the pointer (or the keyboard selection) is on.
            Row {
                id: foot
                readonly property var c: root.hovered || (root.query !== "" ? root.current : null)
                anchors.horizontalCenter: parent.horizontalCenter
                y: grid.y + grid.height + 18
                spacing: 10

                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: foot.c !== null
                    implicitSize: 18
                    source: foot.c ? Hypr.appIcon(foot.c.cls) : ""
                }

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, sheet.width - 120)
                    elide: Text.ElideRight
                    text: foot.c ? foot.c.title : root.clients.length === 0 && Windows.loaded ? "No windows open" : "Click a window to go to it  ·  drag it to another workspace  ·  middle-click to close"
                    color: foot.c ? Theme.text : Theme.textMute
                    size: 12.5
                }
            }
        }

        // What follows the pointer while a window is dragged.
        Item {
            id: ghost

            property var client: null
            property bool dragging: false

            width: 180
            height: 180 / root.aspect
            visible: dragging
            z: 50
            Drag.active: dragging
            Drag.keys: ["zeewin"]
            Drag.source: ghost
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2

            WindowThumb {
                anchors.fill: parent
                client: ghost.client
                live: false
                highlighted: true
                opacity: 0.92
            }
        }
    }
}
