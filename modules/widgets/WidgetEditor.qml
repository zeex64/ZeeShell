import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.settings

// Full-screen layout editor for desktop widgets: a grid with centre lines,
// snapping and alignment guides, and a tray to drag new widgets from.
Overlay {
    id: ov

    open: Ui.editWidgets
    layerName: "widget-editor"
    enterMs: 460
    exitMs: 220
    onDismiss: Ui.stopWidgetEdit()

    Item {
        id: root

        readonly property Item panel: null
        readonly property string screenName: Ui.screen ? Ui.screen.name : ""
        readonly property var items: Config.widgets.items.filter(w => !w.screen || w.screen === screenName)
        readonly property var byId: {
            const m = {};
            for (const w of items) m[w.id] = w;
            return m;
        }
        readonly property int grid: Math.max(10, Config.widgets.grid)
        readonly property real edge: 8
        readonly property bool barTop: Config.bar.position === "top"
        readonly property real barSpace: Ui.barOn(Ui.screen) ? Config.bar.height + (Config.bar.floating ? Config.bar.margin : 0) : 0
        readonly property var types: [
            { key: "clock", label: "Clock", icon: "clock" },
            { key: "weather", label: "Weather", icon: "cloud-sun" },
            { key: "system", label: "System", icon: "cpu" },
            { key: "media", label: "Media", icon: "music-notes" },
            { key: "calendar", label: "Calendar", icon: "calendar-blank" }
        ]

        property string selected: ""
        property Item selectedItem: null
        property Item dragItem: null // widget or ghost being moved
        property string ghostType: "" // set while dragging a new widget out of the tray
        property bool overTray: false
        property real guideX: -1
        property real guideY: -1

        function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }
        function r4(v) { return Math.round(v * 10000) / 10000; }

        function update(id, fn) {
            Config.widgets.items = Config.widgets.items.map(w => w.id === id ? fn(Object.assign({}, w)) : w).filter(w => w);
        }

        function place(id, item) {
            const fx = (item.x + item.width / 2) / width, fy = (item.y + item.height / 2) / height;
            update(id, w => { w.x = r4(fx); w.y = r4(fy); return w; });
        }

        function remove(id) {
            if (selected === id) { selected = ""; selectedItem = null; }
            update(id, w => null);
        }

        function add(type, cx, cy) {
            const id = "w" + Date.now();
            Config.widgets.items = Config.widgets.items.concat([{ id: id, type: type, x: r4(cx / width), y: r4(cy / height), screen: screenName }]);
            selected = id;
        }

        function rescale(id, delta) {
            update(id, w => { w.scale = clamp(Math.round(((w.scale || 1) + delta) * 20) / 20, 0.5, 2); return w; });
        }

        function nudge(id, dx, dy) {
            update(id, w => { w.x = r4(clamp(w.x + dx / width, 0, 1)); w.y = r4(clamp(w.y + dy / height, 0, 1)); return w; });
        }

        function toggleScreen(id) {
            update(id, w => { if (w.screen) delete w.screen; else w.screen = screenName; return w; });
        }

        function inTray(p) {
            const t = tray.mapFromItem(root, p.x, p.y);
            return t.x >= 0 && t.y >= 0 && t.x <= tray.width && t.y <= tray.height;
        }

        // Snap a moving item. Screen centre and the centres / edges of other
        // widgets win (and draw a guide); otherwise the top-left corner
        // settles on the grid, which is laid out from the screen centre.
        function snap(item, x, y) {
            const w = item.width, h = item.height;
            x = clamp(x, edge, width - w - edge);
            y = clamp(y, edge, height - h - edge);
            let gx = -1, gy = -1;
            if (Config.widgets.snap) {
                const reach = 12;
                const xs = [[width / 2, w / 2]], ys = [[height / 2, h / 2]];
                for (let i = 0; i < frames.count; i++) {
                    const f = frames.itemAt(i);
                    if (!f || f === item) continue;
                    xs.push([f.x + f.width / 2, w / 2], [f.x, 0], [f.x + f.width, w]);
                    ys.push([f.y + f.height / 2, h / 2], [f.y, 0], [f.y + f.height, h]);
                }
                let best = reach, sx = x, sy = y;
                for (const c of xs) { const d = Math.abs(x + c[1] - c[0]); if (d < best) { best = d; sx = c[0] - c[1]; gx = c[0]; } }
                best = reach;
                for (const c of ys) { const d = Math.abs(y + c[1] - c[0]); if (d < best) { best = d; sy = c[0] - c[1]; gy = c[0]; } }
                x = gx >= 0 ? sx : width / 2 + Math.round((x - width / 2) / grid) * grid;
                y = gy >= 0 ? sy : height / 2 + Math.round((y - height / 2) / grid) * grid;
                x = clamp(x, edge, width - w - edge);
                y = clamp(y, edge, height - h - edge);
            }
            guideX = gx;
            guideY = gy;
            return Qt.point(Math.round(x), Math.round(y));
        }

        function endDrag() {
            dragItem = null;
            ghostType = "";
            overTray = false;
            guideX = -1;
            guideY = -1;
        }

        focus: true
        Keys.onPressed: e => {
            if (selected === "") return;
            const step = (e.modifiers & Qt.ShiftModifier) ? grid : 1;
            if (e.key === Qt.Key_Left) nudge(selected, -step, 0);
            else if (e.key === Qt.Key_Right) nudge(selected, step, 0);
            else if (e.key === Qt.Key_Up) nudge(selected, 0, -step);
            else if (e.key === Qt.Key_Down) nudge(selected, 0, step);
            else if (e.key === Qt.Key_Delete || e.key === Qt.Key_Backspace) remove(selected);
            else if (e.key === Qt.Key_Plus || e.key === Qt.Key_Equal) rescale(selected, 0.05);
            else if (e.key === Qt.Key_Minus) rescale(selected, -0.05);
            else return;
            e.accepted = true;
        }

        onScreenNameChanged: { selected = ""; selectedItem = null; }

        // ---- backdrop: the desktop, without the windows ----
        Rectangle { anchors.fill: parent; color: Theme.bg; opacity: ov.progress }

        Image {
            anchors.fill: parent
            source: Wallpapers.current !== "" ? "file://" + Wallpapers.current : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(root.width, root.height)
            opacity: ov.progress
        }

        Rectangle { anchors.fill: parent; color: "black"; opacity: 0.28 * ov.progress }

        // Clicking empty space deselects (and keeps the click from closing the editor).
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: { root.selected = ""; root.selectedItem = null; root.forceActiveFocus(); }
        }

        // ---- grid ----
        Item {
            id: gridLines
            anchors.fill: parent
            opacity: (Config.widgets.showGrid ? 1 : 0) * ov.progress

            Behavior on opacity { Anim { ms: 260 } }

            Repeater {
                model: Config.widgets.showGrid ? Math.ceil(root.width / root.grid) + 1 : 0

                Rectangle {
                    required property int index
                    x: Math.round((root.width / 2) % root.grid + index * root.grid)
                    width: 1
                    height: root.height
                    color: Qt.rgba(1, 1, 1, 0.075)
                }
            }

            Repeater {
                model: Config.widgets.showGrid ? Math.ceil(root.height / root.grid) + 1 : 0

                Rectangle {
                    required property int index
                    y: Math.round((root.height / 2) % root.grid + index * root.grid)
                    width: root.width
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.075)
                }
            }
        }

        // Centre lines stay visible even with the grid hidden.
        Rectangle { x: Math.round(root.width / 2) - 1; width: 2; height: root.height; color: Theme.alpha(Theme.accent, 0.5); opacity: ov.progress }
        Rectangle { y: Math.round(root.height / 2) - 1; height: 2; width: root.width; color: Theme.alpha(Theme.accent, 0.5); opacity: ov.progress }

        Rectangle {
            anchors.centerIn: parent
            width: 12
            height: 12
            radius: 6
            color: Theme.accent
            opacity: ov.progress
        }

        // Where the bar sits, so nothing ends up hidden under it.
        Rectangle {
            width: parent.width
            height: root.barSpace
            y: root.barTop ? 0 : parent.height - height
            color: Theme.alpha(Theme.accent, 0.1)
            opacity: ov.progress

            Txt {
                anchors.centerIn: parent
                text: "Bar"
                size: 11.5
                font.weight: Font.DemiBold
                font.letterSpacing: 1.5
                font.capitalization: Font.AllUppercase
                color: Theme.alpha(Theme.accent, 0.8)
            }
        }

        // ---- alignment guides ----
        Rectangle { visible: root.guideX >= 0; x: root.guideX - 1; width: 2; height: root.height; color: Theme.accent; z: 5 }
        Rectangle { visible: root.guideY >= 0; y: root.guideY - 1; height: 2; width: root.width; color: Theme.accent; z: 5 }

        // ---- placed widgets ----
        Repeater {
            id: frames
            model: ScriptModel { values: root.items.map(w => w.id) }

            Item {
                id: frame

                required property string modelData
                readonly property var w: root.byId[modelData] || null
                readonly property real s: w && w.scale ? w.scale : 1
                readonly property bool selected: root.selected === modelData
                property bool dragging: false
                property real dragX: 0
                property real dragY: 0

                onSelectedChanged: if (selected) root.selectedItem = frame
                Component.onCompleted: if (selected) root.selectedItem = frame

                width: body.implicitWidth * s
                height: body.implicitHeight * s
                x: dragging ? dragX : w ? Math.round(root.clamp(w.x * root.width - width / 2, root.edge, root.width - width - root.edge)) : 0
                y: dragging ? dragY : w ? Math.round(root.clamp(w.y * root.height - height / 2, root.edge, root.height - height - root.edge)) : 0
                z: dragging ? 20 : selected ? 10 : 1
                opacity: ov.progress * (dragging && root.overTray ? 0.45 : 1)
                scale: (0.94 + 0.06 * ov.progress) * (dragging ? 1.03 : 1)

                Behavior on x { enabled: !frame.dragging; Anim { ms: 380; curve: Theme.curve.springSoft } }
                Behavior on y { enabled: !frame.dragging; Anim { ms: 380; curve: Theme.curve.springSoft } }
                Behavior on scale { enabled: ov.progress === 1; Anim { ms: 300; curve: Theme.curve.spring } }
                Behavior on opacity { enabled: ov.progress === 1; Anim { ms: 180 } }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -8
                    radius: Theme.radius.lg
                    color: Theme.alpha(Theme.accent, frame.dragging ? 0.16 : frame.selected ? 0.1 : grab.containsMouse ? 0.06 : 0)
                    border.width: frame.selected || frame.dragging ? 2 : 1
                    border.color: frame.selected || frame.dragging ? Theme.accent : Qt.rgba(1, 1, 1, grab.containsMouse ? 0.45 : 0.22)

                    Behavior on color { CAnim {} }
                    Behavior on border.color { CAnim {} }
                }

                WidgetBody {
                    id: body
                    type: frame.w ? frame.w.type : ""
                    zoom: frame.s
                }

                MouseArea {
                    id: grab

                    property real ox: 0
                    property real oy: 0

                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    onPressed: e => {
                        root.selected = frame.modelData;
                        root.forceActiveFocus();
                        const p = mapToItem(root, e.x, e.y);
                        ox = p.x - frame.x;
                        oy = p.y - frame.y;
                        frame.dragX = frame.x;
                        frame.dragY = frame.y;
                        frame.dragging = true;
                        root.dragItem = frame;
                    }
                    onPositionChanged: e => {
                        if (!pressed) return;
                        const p = mapToItem(root, e.x, e.y);
                        root.overTray = root.inTray(p);
                        if (root.overTray) {
                            frame.dragX = p.x - ox;
                            frame.dragY = p.y - oy;
                            root.guideX = -1;
                            root.guideY = -1;
                        } else {
                            const r = root.snap(frame, p.x - ox, p.y - oy);
                            frame.dragX = r.x;
                            frame.dragY = r.y;
                        }
                    }
                    onReleased: {
                        const drop = root.overTray;
                        if (!drop) root.place(frame.modelData, frame);
                        frame.dragging = false;
                        root.endDrag();
                        if (drop) root.remove(frame.modelData);
                    }
                    onCanceled: { frame.dragging = false; root.endDrag(); }
                    onWheel: e => root.rescale(frame.modelData, e.angleDelta.y > 0 ? 0.05 : -0.05)
                }
            }
        }

        // ---- ghost of a widget being dragged out of the tray ----
        Item {
            id: ghost

            visible: root.ghostType !== ""
            width: ghostBody.implicitWidth
            height: ghostBody.implicitHeight
            z: 30
            opacity: root.overTray ? 0.4 : 0.92
            scale: root.overTray ? 0.7 : 1

            Behavior on scale { Anim { ms: 240; curve: Theme.curve.spring } }
            Behavior on opacity { Anim { ms: 160 } }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -8
                radius: Theme.radius.lg
                color: Theme.alpha(Theme.accent, 0.16)
                border.width: 2
                border.color: Theme.accent
            }

            WidgetBody { id: ghostBody; type: root.ghostType }
        }

        // ---- position readout while dragging ----
        Rectangle {
            readonly property Item t: root.dragItem

            visible: t !== null && !root.overTray
            z: 40
            width: readout.implicitWidth + 20
            height: 26
            radius: 13
            color: Theme.accent
            x: t ? root.clamp(t.x + t.width / 2 - width / 2, 8, root.width - width - 8) : 0
            y: t ? (t.y + t.height + 16 + height < root.height ? t.y + t.height + 16 : t.y - height - 16) : 0

            Txt {
                id: readout
                anchors.centerIn: parent
                readonly property Item t: parent.t
                readonly property real fx: t ? (t.x + t.width / 2) / root.width : 0
                readonly property real fy: t ? (t.y + t.height / 2) / root.height : 0
                text: (Math.abs(fx - 0.5) < 0.0005 ? "centred" : Math.round(fx * 1000) / 10 + "%") + "  ×  " + (Math.abs(fy - 0.5) < 0.0005 ? "centred" : Math.round(fy * 1000) / 10 + "%")
                size: 11.5
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
                color: Theme.accentInk
            }
        }

        // ---- controls for the selected widget ----
        Panel {
            id: bubble

            readonly property Item t: root.selectedItem
            readonly property var w: root.byId[root.selected] || null
            readonly property bool show: t !== null && w !== null && root.dragItem === null

            z: 50
            visible: opacity > 0
            opacity: show ? ov.progress : 0
            scale: show ? 1 : 0.9
            width: tools.implicitWidth + 16
            height: 44
            radius: Math.min(Theme.radius.full, 22)
            x: t ? root.clamp(t.x + t.width / 2 - width / 2, 8, root.width - width - 8) : 0
            y: t ? (t.y - height - 18 > bar.y + bar.height + 8 ? t.y - height - 18 : t.y + t.height + 18) : 0

            Behavior on opacity { Anim { ms: 180 } }
            Behavior on scale { Anim { ms: 280; curve: Theme.curve.spring } }

            Row {
                id: tools
                anchors.centerIn: parent
                spacing: 2

                IconBtn { size: 32; icon: "minus"; onClicked: root.rescale(root.selected, -0.05) }

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    horizontalAlignment: Text.AlignHCenter
                    text: Math.round((bubble.w && bubble.w.scale ? bubble.w.scale : 1) * 100) + "%"
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                }

                IconBtn { size: 32; icon: "plus"; onClicked: root.rescale(root.selected, 0.05) }

                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 20; color: Theme.outlineHi }

                Chip {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Quickshell.screens.length > 1
                    icon: "monitor"
                    text: bubble.w && bubble.w.screen ? "This screen" : "All screens"
                    active: !!(bubble.w && bubble.w.screen)
                    onClicked: root.toggleScreen(root.selected)
                }

                IconBtn { size: 32; icon: "trash"; tint: Theme.danger; onClicked: root.remove(root.selected) }
            }
        }

        // ---- top toolbar ----
        Panel {
            id: bar

            anchors.horizontalCenter: parent.horizontalCenter
            y: (root.barTop ? root.barSpace : 0) + 16 - (1 - ov.progress) * 90
            z: 60
            width: top.implicitWidth + 28
            height: 54
            radius: Math.min(Theme.radius.full, 27)
            opacity: ov.progress

            Row {
                id: top
                anchors.centerIn: parent
                spacing: 8

                Icon { anchors.verticalCenter: parent.verticalCenter; name: "squares-four"; fill: true; size: 20; color: Theme.accent }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: "Widget layout"; size: 15; font.weight: Font.Bold; rightPadding: 6 }

                Repeater {
                    model: Quickshell.screens.length > 1 ? Quickshell.screens : []

                    Chip {
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "monitor"
                        text: modelData.name
                        active: root.screenName === modelData.name
                        onClicked: Ui.screen = modelData
                    }
                }

                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 22; color: Theme.outlineHi }

                Chip {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "magnet"
                    text: "Snap"
                    active: Config.widgets.snap
                    onClicked: Config.widgets.snap = !Config.widgets.snap
                }

                Chip {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "grid-four"
                    text: "Grid"
                    active: Config.widgets.showGrid
                    onClicked: Config.widgets.showGrid = !Config.widgets.showGrid
                }

                Choice {
                    anchors.verticalCenter: parent.verticalCenter
                    options: [[20, "Fine"], [40, "Medium"], [80, "Coarse"]]
                    current: Config.widgets.grid
                    onPicked: k => Config.widgets.grid = k
                }

                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 22; color: Theme.outlineHi }

                Btn { anchors.verticalCenter: parent.verticalCenter; kind: "filled"; icon: "check"; text: "Done"; onClicked: ov.dismiss() }
            }
        }

        // ---- widget tray ----
        Panel {
            id: tray

            readonly property bool removing: root.overTray && root.ghostType === "" && root.dragItem !== null

            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - height - (root.barTop ? 0 : root.barSpace) - 22 + (1 - ov.progress) * 200
            z: 60
            width: cards.implicitWidth + 32
            height: 168
            color: removing ? Theme.alpha(Theme.danger, 0.3) : Theme.panel
            opacity: ov.progress
            scale: root.overTray ? 1.03 : 1

            Behavior on color { CAnim {} }
            Behavior on scale { Anim { ms: 280; curve: Theme.curve.spring } }

            Txt {
                x: 20
                y: 12
                text: tray.removing ? "Release to remove" : root.ghostType !== "" && root.overTray ? "Release to cancel" : "Drag a widget onto the desktop, or click to drop it in the middle"
                size: 12
                font.weight: Font.DemiBold
                color: tray.removing ? Theme.danger : Theme.textDim
            }

            Txt {
                anchors.right: parent.right
                anchors.rightMargin: 20
                y: 12
                text: "Scroll to resize  ·  arrows to nudge  ·  Del to remove  ·  Esc when done"
                size: 11.5
                color: Theme.textMute
                visible: !tray.removing && parent.width > 900
            }

            Icon {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 12
                name: "trash"
                fill: true
                size: 46
                color: Theme.danger
                opacity: tray.removing ? 1 : 0
                scale: tray.removing ? 1 : 0.6

                Behavior on opacity { Anim { ms: 180 } }
                Behavior on scale { Anim { ms: 300; curve: Theme.curve.spring } }
            }

            Row {
                id: cards
                x: 16
                y: 38
                spacing: 10
                opacity: tray.removing ? 0.15 : 1

                Behavior on opacity { Anim { ms: 180 } }

                Repeater {
                    model: root.types

                    Card {
                        id: card

                        required property var modelData
                        readonly property bool lifted: root.ghostType === modelData.key

                        width: 176
                        height: 116
                        color: pick.containsMouse ? Theme.layerHi : Theme.layer
                        opacity: lifted ? 0.35 : 1
                        scale: pick.pressed && !lifted ? 0.96 : 1

                        Behavior on color { CAnim {} }
                        Behavior on scale { Anim { ms: 280; curve: Theme.curve.spring } }

                        // Live miniature of the real widget.
                        Item {
                            x: 8
                            y: 8
                            width: parent.width - 16
                            height: 70
                            clip: true

                            WidgetBody {
                                id: mini
                                type: card.modelData.key
                                anchors.centerIn: parent
                                transformOrigin: Item.Center
                                scale: Math.min(parent.width / Math.max(1, implicitWidth), parent.height / Math.max(1, implicitHeight), 1)
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 9
                            spacing: 6

                            Icon { anchors.verticalCenter: parent.verticalCenter; name: card.modelData.icon; size: 14; color: Theme.accent }
                            Txt { anchors.verticalCenter: parent.verticalCenter; text: card.modelData.label; size: 12.5; font.weight: Font.DemiBold }
                        }

                        MouseArea {
                            id: pick

                            property real sx: 0
                            property real sy: 0
                            property bool moved: false

                            function follow(p) {
                                root.overTray = root.inTray(p);
                                if (root.overTray) {
                                    ghost.x = p.x - ghost.width / 2;
                                    ghost.y = p.y - ghost.height / 2;
                                    root.guideX = -1;
                                    root.guideY = -1;
                                } else {
                                    const r = root.snap(ghost, p.x - ghost.width / 2, p.y - ghost.height / 2);
                                    ghost.x = r.x;
                                    ghost.y = r.y;
                                }
                            }

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                            onPressed: e => {
                                const p = mapToItem(root, e.x, e.y);
                                sx = p.x;
                                sy = p.y;
                                moved = false;
                                root.forceActiveFocus();
                            }
                            onPositionChanged: e => {
                                if (!pressed) return;
                                const p = mapToItem(root, e.x, e.y);
                                if (!moved && Math.abs(p.x - sx) + Math.abs(p.y - sy) > 8) {
                                    moved = true;
                                    root.ghostType = card.modelData.key;
                                    root.dragItem = ghost;
                                }
                                if (moved) follow(p);
                            }
                            onReleased: {
                                if (!moved) {
                                    root.add(card.modelData.key, root.width / 2, root.height / 2);
                                } else if (!root.overTray) {
                                    root.add(card.modelData.key, ghost.x + ghost.width / 2, ghost.y + ghost.height / 2);
                                }
                                moved = false;
                                root.endDrag();
                            }
                            onCanceled: { moved = false; root.endDrag(); }
                        }
                    }
                }
            }
        }
    }
}
