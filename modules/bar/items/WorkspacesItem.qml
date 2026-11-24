import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.bar

// Workspace switcher. Styles: dots, numbers, or the icons of the apps open on
// each workspace. The highlight stretches toward the workspace you switch to.
BarItem {
    id: root

    readonly property string style: Config.workspaces.style
    readonly property bool numbers: style === "numbers"
    readonly property bool apps: style === "apps"
    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property int activeId: Config.workspaces.perMonitor && monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : Hypr.activeId
    readonly property var occupied: {
        const o = {};
        for (const w of Hyprland.workspaces.values) if (w.id > 0) o[w.id] = true;
        return o;
    }
    // Always show 1..count, plus any occupied workspace beyond that (no empty gaps).
    readonly property var ids: {
        const set = {};
        for (let i = 1; i <= Config.workspaces.count; i++) set[i] = true;
        for (const k in occupied) set[k] = true;
        return Object.keys(set).map(k => parseInt(k)).sort((a, b) => a - b).slice(0, 20);
    }
    readonly property int count: ids.length
    readonly property int activeIndex: ids.indexOf(activeId)
    // workspace id -> icon urls of the apps on it (one per app)
    readonly property var icons: {
        const out = {};
        if (!apps) return out;
        const seen = {};
        for (const a in Hypr.windows) {
            const w = Hypr.windows[a];
            if (w.ws <= 0 || !w.cls || seen[w.ws + "/" + w.cls]) continue;
            seen[w.ws + "/" + w.cls] = true;
            (out[w.ws] = out[w.ws] || []).push(Hypr.appIcon(w.cls));
        }
        return out;
    }

    interactive: false
    pad: 8
    spacing: 0
    onScrolled: dir => {
        const to = activeIndex - dir;
        if (activeIndex >= 0 && to >= 0 && to < count) Hypr.workspace(ids[to]);
    }

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: cells.implicitWidth
        height: 28

        Rectangle {
            id: indicator

            readonly property Item cell: root.activeIndex >= 0 && root.activeIndex < list.count ? list.itemAt(root.activeIndex) : null
            readonly property real toLeft: cell ? cell.x + 2 : 0
            readonly property real toRight: cell ? cell.x + cell.width - 2 : 0
            property real lo: 0 // left edge
            property real hi: 0 // right edge
            property bool forward: true

            // The edge facing the direction of travel moves fast, the other catches up.
            function retarget() {
                forward = toLeft > lo;
                lo = toLeft;
                hi = toRight;
            }

            onToLeftChanged: retarget()
            onToRightChanged: retarget()

            anchors.verticalCenter: parent.verticalCenter
            x: lo
            width: Math.max(6, hi - lo)
            height: root.numbers ? 24 : root.apps ? 26 : 10
            radius: Math.min(Theme.radius.full, height / 2)
            color: root.apps ? Theme.alpha(Theme.accent, 0.26) : Theme.accent
            border.width: root.apps ? 1 : 0
            border.color: Theme.alpha(Theme.accent, 0.8)
            visible: cell !== null

            Behavior on lo { Anim { ms: indicator.forward ? 520 : 260; curve: indicator.forward ? Theme.curve.standard : Theme.curve.enter } }
            Behavior on hi { Anim { ms: indicator.forward ? 260 : 520; curve: indicator.forward ? Theme.curve.enter : Theme.curve.standard } }
            Behavior on height { Anim { ms: 260 } }
        }

        Row {
            id: cells
            height: parent.height

            Repeater {
                id: list
                model: root.ids

                Item {
                    id: cell

                    required property int modelData
                    readonly property int ws: modelData
                    readonly property bool current: ws === root.activeId
                    readonly property bool busy: root.occupied[ws] === true
                    readonly property var shown: root.apps && root.icons[ws] ? root.icons[ws].slice(0, 4) : []
                    readonly property int extra: root.apps && root.icons[ws] ? Math.max(0, root.icons[ws].length - 4) : 0

                    width: root.numbers ? 26 : shown.length ? shown.length * 21 + 11 + (extra ? 16 : 0) : (root.apps ? 22 : 20)
                    height: parent.height

                    Behavior on width { Anim { ms: 300 } }

                    Rectangle {
                        anchors.centerIn: parent
                        visible: !root.numbers && cell.shown.length === 0
                        width: cell.busy ? 8 : 6
                        height: width
                        radius: width / 2
                        color: cell.busy ? Theme.textDim : Theme.alpha(Theme.textMute, 0.55)
                        opacity: cell.current && !root.apps ? 0 : 1
                        scale: area.containsMouse ? 1.5 : 1

                        Behavior on opacity { Anim { ms: 200 } }
                        Behavior on scale { Anim { ms: 260; curve: Theme.curve.spring } }
                        Behavior on width { Anim { ms: 260 } }
                    }

                    Txt {
                        anchors.centerIn: parent
                        visible: root.numbers
                        text: cell.ws
                        size: 12
                        font.weight: cell.current ? Font.Bold : Font.Medium
                        color: cell.current ? Theme.accentInk : cell.busy ? Theme.text : Theme.textMute

                        Behavior on color { CAnim {} }
                    }

                    Row {
                        anchors.centerIn: parent
                        visible: cell.shown.length > 0
                        spacing: 4
                        scale: area.pressed ? 0.9 : 1

                        Behavior on scale { Anim { ms: 260; curve: Theme.curve.spring } }

                        Repeater {
                            model: cell.shown

                            IconImage {
                                required property string modelData
                                anchors.verticalCenter: parent.verticalCenter
                                implicitSize: 17
                                source: modelData
                                opacity: cell.current || area.containsMouse ? 1 : 0.72

                                Behavior on opacity { Anim { ms: 200 } }
                            }
                        }

                        Txt {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: cell.extra > 0
                            text: "+" + cell.extra
                            size: 10.5
                            font.weight: Font.DemiBold
                            color: Theme.textDim
                        }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hypr.workspace(cell.ws)
                    }
                }
            }
        }
    }
}
