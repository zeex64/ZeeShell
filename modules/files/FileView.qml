import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components
import qs.services

// The folder's contents, as a grid of tiles or a detailed list. Handles
// clicking, selecting, dragging files out and dropping files in.
Item {
    id: root

    required property var win
    readonly property int columns: win.grid ? Math.max(1, Math.floor(grid.width / grid.cellWidth)) : 1
    readonly property real tile: Config.files.iconSize

    function reveal(index) {
        if (win.grid) grid.positionViewAtIndex(index, GridView.Contain);
        else rows.positionViewAtIndex(index, ListView.Contain);
    }

    // What a click on an item does, shared by both views.
    function press(entry, mouse) {
        root.win.stage.forceActiveFocus();
        root.win.menu = null;
        const picked = root.win.selected[entry.path] === true;
        if (mouse.button === Qt.MiddleButton) {
            // Folders open in a tab behind this one.
            if (entry.dir) root.win.newTab(entry.path, true);
            return;
        }
        if (mouse.button === Qt.RightButton) {
            if (!picked) root.win.selectOnly(entry.path);
            return;
        }
        if (mouse.modifiers & Qt.ControlModifier) root.win.toggle(entry.path);
        else if (mouse.modifiers & Qt.ShiftModifier) root.win.selectTo(entry.path);
        else if (!picked) root.win.selectOnly(entry.path);
    }

    function release(entry, mouse, item) {
        if (mouse.button === Qt.MiddleButton) return;
        if (mouse.button === Qt.RightButton) {
            const p = item.mapToItem(root.win.stage, mouse.x, mouse.y);
            root.win.showMenu(p.x, p.y, entry);
        } else if (!(mouse.modifiers & (Qt.ControlModifier | Qt.ShiftModifier))) {
            // A plain click on one of several selected items narrows to it,
            // but only on release, so the group can still be dragged.
            root.win.selectOnly(entry.path);
        }
    }

    readonly property string dragList: win.chosen.map(Files.uri).join("\r\n")

    // Empty space: clear the selection, or open the folder's own menu.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: e => {
            root.win.stage.forceActiveFocus();
            root.win.clearSelection();
            if (e.button === Qt.RightButton) root.win.showMenu(e.x + root.x, e.y + root.y, null);
            else root.win.menu = null;
        }
    }

    // Files dropped on empty space land in this folder.
    DropArea {
        id: landing
        anchors.fill: parent
        keys: ["text/uri-list"]
        onDropped: d => {
            root.win.receive(d.urls, root.win.path, d.proposedAction === Qt.MoveAction);
            d.acceptProposedAction();
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 6
        radius: Theme.radius.md
        color: "transparent"
        border.width: 2
        border.color: Theme.accent
        opacity: landing.containsDrag ? 0.7 : 0

        Behavior on opacity { Anim { ms: 160 } }
    }

    // ------------------------------------------------------------------ grid
    GridView {
        id: grid

        visible: root.win.grid
        anchors.fill: parent
        anchors.margins: 10
        anchors.rightMargin: 14
        clip: true
        cellWidth: Math.floor(width / Math.max(1, Math.floor(width / (root.tile + 52))))
        cellHeight: root.tile + 58
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 400
        model: root.win.grid ? root.win.entries : []
        interactive: true

        delegate: Item {
            id: cell

            required property var modelData
            required property int index
            readonly property bool picked: root.win.selected[modelData.path] === true
            readonly property bool held: Files.clip.mode === "cut" && Files.clip.paths.indexOf(modelData.path) >= 0
            readonly property bool here: root.win.cursor === index
            readonly property bool picture: !modelData.dir && Files.isImage(modelData.suffix) && modelData.size < 40000000

            width: grid.cellWidth
            height: grid.cellHeight
            opacity: held ? 0.45 : 1

            Drag.active: tap.drag.active
            Drag.dragType: Drag.Automatic
            Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
            Drag.proposedAction: Qt.MoveAction
            Drag.mimeData: ({ "text/uri-list": root.dragList })

            Rectangle {
                anchors.fill: parent
                anchors.margins: 3
                radius: Theme.radius.md
                color: into.containsDrag ? Theme.accent : cell.picked ? Theme.accentSoft : tap.containsMouse ? Theme.layer : "transparent"
                border.width: cell.here && !cell.picked ? 1 : 0
                border.color: Theme.outlineHi

                Behavior on color { CAnim {} }
            }

            Item {
                id: art
                anchors.horizontalCenter: parent.horizontalCenter
                y: 12
                width: root.tile
                height: root.tile
                scale: tap.pressed ? 0.94 : 1

                Behavior on scale { Anim { ms: 260; curve: Theme.curve.spring } }

                IconImage {
                    anchors.fill: parent
                    visible: !cell.picture || thumb.status !== Image.Ready
                    source: Files.icon(cell.modelData)
                }

                ClippingRectangle {
                    anchors.centerIn: parent
                    visible: cell.picture && thumb.status === Image.Ready
                    width: thumb.paintedWidth
                    height: thumb.paintedHeight
                    radius: Theme.radius.xs
                    color: "transparent"

                    Image {
                        id: thumb
                        anchors.centerIn: parent
                        width: art.width
                        height: art.height
                        source: cell.picture ? Files.uri(cell.modelData.path) : ""
                        sourceSize: Qt.size(256, 256)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                }
            }

            Txt {
                anchors.top: art.bottom
                anchors.topMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 14
                horizontalAlignment: Text.AlignHCenter
                text: cell.modelData.name
                size: 12
                font.weight: cell.picked ? Font.DemiBold : Font.Normal
                color: into.containsDrag ? Theme.accentInk : cell.picked ? Theme.softInk : Theme.text
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 2
                elide: Text.ElideRight
                lineHeight: 0.95
            }

            Item { id: ghost }

            MouseArea {
                id: tap
                anchors.fill: parent
                anchors.margins: 3
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                drag.target: ghost
                onPressed: e => root.press(cell.modelData, e)
                onClicked: e => root.release(cell.modelData, e, tap)
                onDoubleClicked: e => { if (e.button === Qt.LeftButton) root.win.open(cell.modelData); }
            }

            // Drop onto a folder to put files inside it.
            DropArea {
                id: into
                anchors.fill: parent
                enabled: cell.modelData.dir && !cell.picked
                keys: ["text/uri-list"]
                onDropped: d => {
                    root.win.receive(d.urls, cell.modelData.path, d.proposedAction === Qt.MoveAction);
                    d.acceptProposedAction();
                }
            }
        }
    }

    ScrollHandle {
        visible: root.win.grid && grid.contentHeight > grid.height + 1
        flick: grid
        anchors.top: grid.top
        anchors.bottom: grid.bottom
        anchors.right: parent.right
    }

    // ------------------------------------------------------------------ list
    Item {
        id: head

        visible: !root.win.grid
        x: 12
        y: 4
        width: parent.width - 30
        height: 30

        Repeater {
            model: [
                { key: "name", label: "Name", x: 44, w: -1 },
                { key: "size", label: "Size", x: -370, w: 90 },
                { key: "modified", label: "Changed", x: -270, w: 160 },
                { key: "type", label: "Kind", x: -100, w: 100 }
            ]

            Item {
                id: column
                required property var modelData

                x: modelData.x >= 0 ? modelData.x : head.width + modelData.x
                width: modelData.w > 0 ? modelData.w : head.width - 44 - 380
                height: head.height

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Txt {
                        text: column.modelData.label
                        size: 11.5
                        font.weight: Font.Bold
                        color: Config.files.sortBy === column.modelData.key ? Theme.accent : Theme.textMute
                    }

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Config.files.sortBy === column.modelData.key
                        name: Config.files.sortReversed ? "caret-up" : "caret-down"
                        size: 11
                        color: Theme.accent
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.win.setSort(column.modelData.key)
                }
            }
        }

        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.outline }
    }

    ListView {
        id: rows

        visible: !root.win.grid
        anchors.fill: parent
        anchors.topMargin: 38
        anchors.leftMargin: 12
        anchors.rightMargin: 18
        anchors.bottomMargin: 6
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 400
        model: root.win.grid ? [] : root.win.entries

        delegate: Item {
            id: line

            required property var modelData
            required property int index
            readonly property bool picked: root.win.selected[modelData.path] === true
            readonly property bool held: Files.clip.mode === "cut" && Files.clip.paths.indexOf(modelData.path) >= 0
            readonly property color ink: under.containsDrag ? Theme.accentInk : picked ? Theme.softInk : Theme.text
            readonly property color faint: under.containsDrag ? Theme.accentInk : picked ? Theme.softInk : Theme.textDim

            width: rows.width
            height: 36
            opacity: held ? 0.45 : 1

            Drag.active: touch.drag.active
            Drag.dragType: Drag.Automatic
            Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
            Drag.proposedAction: Qt.MoveAction
            Drag.mimeData: ({ "text/uri-list": root.dragList })

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 1
                anchors.bottomMargin: 1
                radius: Theme.radius.sm
                color: under.containsDrag ? Theme.accent : line.picked ? Theme.accentSoft : touch.containsMouse ? Theme.layer : "transparent"
                border.width: root.win.cursor === line.index && !line.picked ? 1 : 0
                border.color: Theme.outlineHi
            }

            IconImage {
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 24
                source: Files.icon(line.modelData)
            }

            Txt {
                x: 44
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 44 - 384
                text: line.modelData.name
                elide: Text.ElideMiddle
                font.weight: line.picked ? Font.DemiBold : Font.Normal
                color: line.ink
            }

            Txt {
                x: parent.width - 370
                anchors.verticalCenter: parent.verticalCenter
                width: 90
                text: line.modelData.dir ? "" : Files.size(line.modelData.size)
                size: 12
                color: line.faint
                font.features: { "tnum": 1 }
            }

            Txt {
                x: parent.width - 270
                anchors.verticalCenter: parent.verticalCenter
                width: 160
                text: Qt.formatDateTime(line.modelData.modified, "d MMM yyyy  " + (Config.clock.use24h ? "HH:mm" : "h:mm AP"))
                size: 12
                color: line.faint
                elide: Text.ElideRight
            }

            Txt {
                x: parent.width - 100
                anchors.verticalCenter: parent.verticalCenter
                width: 96
                text: Files.kindLabel(line.modelData)
                size: 12
                color: line.faint
                elide: Text.ElideRight
            }

            Item { id: shadow }

            MouseArea {
                id: touch
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                drag.target: shadow
                onPressed: e => root.press(line.modelData, e)
                onClicked: e => root.release(line.modelData, e, touch)
                onDoubleClicked: e => { if (e.button === Qt.LeftButton) root.win.open(line.modelData); }
            }

            DropArea {
                id: under
                anchors.fill: parent
                enabled: line.modelData.dir && !line.picked
                keys: ["text/uri-list"]
                onDropped: d => {
                    root.win.receive(d.urls, line.modelData.path, d.proposedAction === Qt.MoveAction);
                    d.acceptProposedAction();
                }
            }
        }
    }

    ScrollHandle {
        visible: !root.win.grid && rows.contentHeight > rows.height + 1
        flick: rows
        anchors.top: rows.top
        anchors.bottom: rows.bottom
        anchors.right: parent.right
    }

    // ------------------------------------------------------------ empty state
    Column {
        anchors.centerIn: parent
        visible: root.win.entries.length === 0
        spacing: 10

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: root.win.filter !== "" ? "magnifying-glass" : "folder-open"
            size: 46
            color: Theme.textMute
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.win.filter !== "" ? "Nothing here matches “" + root.win.filter + "”" : "This folder is empty"
            color: Theme.textMute
        }
    }
}
