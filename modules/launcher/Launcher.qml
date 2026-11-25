import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components
import qs.services

// App drawer: search, category chips and a keyboard-navigable grid.
Overlay {
    id: ov

    open: Ui.active === "launcher"
    layerName: "launcher"
    dim: Config.launcher.position === "center"
    onDismiss: Ui.hide()

    Item {
        id: root

        readonly property Item panel: sheet
        // Where the drawer sits: center | side | bottom-left | bottom-center
        readonly property string position: Config.launcher.position
        readonly property bool side: position === "side"
        readonly property bool low: position === "bottom-left" || position === "bottom-center"
        readonly property bool barTop: Config.bar.position === "top"
        readonly property real barSpace: Ui.barOn(Ui.screen) ? Config.bar.height + (Config.bar.floating ? Config.bar.margin : 0) : 0
        readonly property int cols: side ? Math.min(4, Math.max(3, Config.launcher.columns)) : low ? 6 : Math.max(3, Config.launcher.columns)
        // The bottom positions open as a start menu until you type.
        readonly property bool browsing: low && query === ""
        readonly property real cell: 118
        property string category: "all"
        readonly property string query: search.text
        readonly property bool isCommand: query.startsWith(">")
        readonly property bool isSlash: query.startsWith("/")
        readonly property string math: {
            if (isSlash) return "";
            const q = query.startsWith("=") ? query.slice(1) : query;
            if (!/^[\d\s+\-*/().%^,]+$/.test(q) || !/[+\-*/%^]/.test(q) || !/\d/.test(q)) return "";
            try {
                const v = Function('"use strict"; return (' + q.replace(/\^/g, "**").replace(/,/g, ".") + ")")();
                return typeof v === "number" && isFinite(v) ? String(Math.round(v * 1e10) / 1e10) : "";
            } catch (e) {
                return "";
            }
        }

        readonly property var actions: [
            { name: "Settings", glyph: "gear", run: () => Ui.settings() },
            { name: "Files", glyph: "folder", run: () => { Ui.hide(); Quickshell.execDetached([Quickshell.shellPath("zeeshell"), "files"]); } },
            { name: "Wallpapers", glyph: "image", run: () => Ui.show("wallpaper") },
            { name: "Keybindings", glyph: "keyboard", run: () => Ui.show("keybinds") },
            { name: "Power menu", glyph: "power", run: () => Ui.show("power") },
            { name: "Lock screen", glyph: "lock", run: () => { Ui.hide(); Ui.locked = true; } },
            { name: "Quick settings", glyph: "sliders-horizontal", run: () => Ui.show("sidebar") },
            { name: "Clipboard history", glyph: "clipboard-text", run: () => Ui.show("clipboard") },
            { name: "Window overview", glyph: "squares-four", run: () => Ui.show("overview") },
            { name: "Edit widgets", glyph: "cards", run: () => Ui.startWidgetEdit() },
            { name: "Steam workspace", glyph: "steam-logo", run: () => { Ui.hide(); Hypr.toggleSteam(); } }
        ]

        // Typed as /name, some with a value: /volume 40
        readonly property var slashCommands: [
            { name: "settings", arg: "what", hint: "Open settings, or find a setting", glyph: "gear", run: a => a.trim() !== "" ? Ui.findSetting(a.trim()) : Ui.settings() },
            { name: "files", arg: "folder", hint: "Open the file explorer", glyph: "folder", run: a => Quickshell.execDetached([Quickshell.shellPath("zeeshell"), "files"].concat(a !== "" ? [a.replace(/^~/, Config.home)] : [])) },
            { name: "clipboard", arg: "text", hint: "Open the clipboard history, or search it", glyph: "clipboard-text", run: a => { Ui.clipboardSeed = a; Ui.show("clipboard"); } },
            { name: "overview", hint: "Show every workspace and window", glyph: "squares-four", run: a => Ui.show("overview") },
            { name: "wallpaper", hint: "Browse wallpapers", glyph: "image", run: a => Ui.show("wallpaper") },
            { name: "random", hint: "Switch to a random wallpaper", glyph: "shuffle", run: a => Wallpapers.random() },
            { name: "keybinds", hint: "Show the keybinding cheat sheet", glyph: "keyboard", run: a => Ui.show("keybinds") },
            { name: "widgets", hint: "Arrange desktop widgets", glyph: "cards", run: a => Ui.startWidgetEdit() },
            { name: "sidebar", hint: "Open quick settings", glyph: "sliders-horizontal", run: a => Ui.show("sidebar") },
            { name: "lock", hint: "Lock the session", glyph: "lock", run: a => { Ui.locked = true; } },
            { name: "power", hint: "Open the power menu", glyph: "power", run: a => Ui.show("power") },
            { name: "sleep", hint: "Suspend the computer", glyph: "moon", run: a => Quickshell.execDetached(["systemctl", "suspend"]) },
            { name: "dark", hint: "Switch between dark and light", glyph: "circle-half", run: a => { Config.appearance.dark = !Config.appearance.dark; } },
            { name: "dnd", hint: "Toggle do not disturb", glyph: "bell-slash", run: a => { Config.notifications.dnd = !Config.notifications.dnd; } },
            { name: "night", hint: "Toggle night light", glyph: "moon-stars", run: a => { Toggles.nightLight = !Toggles.nightLight; } },
            { name: "caffeine", hint: "Keep the screen awake", glyph: "coffee", run: a => { Toggles.caffeine = !Toggles.caffeine; } },
            { name: "volume", arg: "0-100", hint: "Set the volume", glyph: "speaker-high", run: a => { const n = parseInt(a); if (!isNaN(n)) Audio.setVolume(n / 100); } },
            { name: "mute", hint: "Mute or unmute", glyph: "speaker-x", run: a => Audio.toggleMute() },
            { name: "brightness", arg: "0-100", hint: "Set the brightness", glyph: "sun", run: a => { const n = parseInt(a); if (!isNaN(n)) Brightness.set(n / 100); } },
            { name: "screenshot", hint: "Capture a region", glyph: "camera", run: a => Quickshell.execDetached(["hyprshot", "-m", "region"]) },
            { name: "pick", hint: "Pick a colour from the screen", glyph: "eyedropper", run: a => Quickshell.execDetached(["hyprpicker", "-a"]) },
            { name: "steam", hint: "Show the Steam workspace", glyph: "steam-logo", run: a => Hypr.toggleSteam() },
            { name: "clear", hint: "Clear all notifications", glyph: "broom", run: a => Notifs.clear() },
            { name: "reload", hint: "Reload Hyprland's config", glyph: "arrows-clockwise", run: a => Quickshell.execDetached(["hyprctl", "reload"]) }
        ]

        readonly property var results: {
            if (isCommand) return [];
            if (isSlash) {
                const body = query.slice(1), sp = body.indexOf(" ");
                const name = (sp < 0 ? body : body.slice(0, sp)).toLowerCase(), arg = sp < 0 ? "" : body.slice(sp + 1).trim();
                // Names that start with what was typed come first; the list order is kept otherwise.
                const hit = sp < 0
                    ? slashCommands.filter(c => c.name.indexOf(name) === 0).concat(slashCommands.filter(c => c.name.indexOf(name) > 0))
                    : slashCommands.filter(c => c.name === name);
                return hit
                    .map(c => ({
                        slash: true, name: "/" + c.name, glyph: c.glyph,
                        hint: c.arg ? (arg !== "" ? c.hint + " to " + arg : c.hint + "   ·   /" + c.name + " " + c.arg) : c.hint,
                        run: () => { Ui.hide(); c.run(arg); }
                    }));
            }
            const apps = Apps.search(query, category);
            const q = query.trim().toLowerCase();
            if (q === "" || category !== "all") return apps;
            return actions.filter(a => a.name.toLowerCase().indexOf(q) >= 0).concat(apps);
        }

        function activate(item) {
            if (!item) return;
            if (item.run) {
                item.run();
            } else {
                Ui.hide();
                Apps.launch(item);
            }
        }

        function submit() {
            if (isCommand) {
                const cmd = query.slice(1).trim();
                if (cmd !== "") Quickshell.execDetached(["sh", "-c", cmd]);
                Ui.hide();
            } else if (math !== "" && (query.startsWith("=") || results.length === 0)) {
                Quickshell.clipboardText = math;
                Ui.hide();
            } else {
                activate(results[grid.currentIndex]);
            }
        }

        onResultsChanged: grid.currentIndex = 0
        Component.onCompleted: {
            if (Ui.launcherSeed === "") return;
            search.text = Ui.launcherSeed;
            Ui.launcherSeed = "";
        }

        Panel {
            id: sheet

            readonly property real upper: root.barTop ? root.barSpace : 0
            readonly property real avail: root.height - root.barSpace

            readonly property real inset: root.low ? rail.width : 0 // room taken by the start rail

            width: root.low ? 60 + 16 + 290 + 18 + 4 * 104 + 22 : Math.max(root.cols * root.cell + 48, chips.implicitWidth + 40)
            height: root.side ? avail - 20 : Math.min(avail - (root.low ? 40 : 120), root.low ? 640 : 664)
            // Centre: rises into place. Side: slides in from the left edge.
            // Bottom: comes up from the bottom edge, like a start menu.
            x: root.side ? 10 - (1 - ov.progress) * (width + 30)
                : root.position === "bottom-left" ? 10
                : (root.width - width) / 2
            y: root.side ? upper + 10
                : root.low ? upper + avail - height - 10 + (1 - ov.progress) * 60
                : upper + (avail - height) / 2 + (1 - ov.progress) * 36
            opacity: root.side ? Math.min(1, ov.progress * 1.6) : ov.progress
            scale: root.side || root.low ? 1 : 0.94 + 0.06 * ov.progress

            StartRail {
                id: rail
                visible: root.low
                height: parent.height
                corner: sheet.radius
            }

            StartView {
                visible: root.browsing
                x: sheet.inset
                width: parent.width - sheet.inset
                height: search.y - 10
                actions: root.actions
                onLaunch: item => root.activate(item)
            }

            Field {
                id: search

                // On top normally; at the bottom, next to the bar, in the start layout.
                x: sheet.inset + (root.low ? 16 : 20)
                y: root.low ? sheet.height - height - 14 : 20
                width: sheet.width - x - (root.low ? 16 : 20)
                implicitHeight: 50
                icon: root.isCommand ? "terminal-window" : "magnifying-glass"
                placeholder: "Search apps   ·   / commands   ·   = calculate   ·   > run"
                autoFocus: true
                onAccepted: root.submit()
                onKey: e => {
                    const n = grid.count, c = root.isSlash ? 1 : root.cols;
                    let i = grid.currentIndex;
                    if (e.key === Qt.Key_Down) i = Math.min(n - 1, i + c);
                    else if (e.key === Qt.Key_Up) i = Math.max(0, i - c);
                    else if (e.key === Qt.Key_Right || (e.key === Qt.Key_Tab)) i = Math.min(n - 1, i + 1);
                    else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) i = Math.max(0, i - 1);
                    else return;
                    grid.currentIndex = i;
                    e.accepted = true;
                }
            }

            Row {
                id: chips

                y: search.y + search.height + 12
                anchors.horizontalCenter: parent.horizontalCenter
                visible: Config.launcher.showCategories && !root.isCommand && !root.isSlash && !root.low
                height: visible ? implicitHeight : 0
                spacing: 6

                Repeater {
                    model: Apps.categories

                    Chip {
                        required property var modelData
                        text: root.side ? "" : modelData.label // the side panel is narrow: icons only
                        icon: modelData.icon
                        active: root.category === modelData.key
                        onClicked: root.category = modelData.key
                    }
                }
            }

            // Calculator / command banner
            Rectangle {
                id: banner

                readonly property bool show: root.math !== "" || root.isCommand

                x: sheet.inset + 20
                y: root.low ? 16 : chips.y + chips.height + (show ? 12 : 0)
                width: sheet.width - sheet.inset - 40
                height: show ? 56 : 0
                radius: Theme.radius.md
                color: Theme.accentSoft
                clip: true
                opacity: show ? 1 : 0

                Behavior on height { Anim { ms: 280 } }
                Behavior on opacity { Anim { ms: 200 } }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 16
                    spacing: 12

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: root.isCommand ? "terminal-window" : "equals"
                        size: 20
                        color: Theme.softInk
                    }

                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.isCommand ? (root.query.slice(1).trim() || "Type a command") : root.math
                        mono: root.isCommand
                        size: root.isCommand ? 14 : 20
                        font.weight: Font.DemiBold
                        color: Theme.softInk
                    }
                }

                Txt {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.isCommand ? "Enter to run" : "Enter to copy"
                    size: 12
                    color: Theme.softInk
                    opacity: 0.7
                }
            }

            ScrollHandle {
                flick: grid
                z: 5
                visible: !root.browsing && grid.contentHeight > grid.height + 1
                anchors.top: grid.top
                anchors.bottom: grid.bottom
                anchors.right: parent.right
                anchors.rightMargin: 3
            }

            GridView {
                id: grid

                visible: !root.browsing
                x: sheet.inset + (sheet.width - sheet.inset - width) / 2
                y: banner.y + banner.height + 14
                height: (root.low ? search.y - 12 : sheet.height - 16) - y
                width: root.cols * root.cell
                cellWidth: root.isSlash ? width : root.cell
                cellHeight: root.isSlash ? 54 : 116
                clip: true
                model: root.results
                boundsBehavior: Flickable.DragAndOvershootBounds
                highlightMoveDuration: Theme.dur(180)
                highlightFollowsCurrentItem: true
                keyNavigationEnabled: false

                highlight: Rectangle {
                    radius: Theme.radius.md
                    color: Theme.accentSoft
                }

                delegate: Item {
                    id: app

                    required property var modelData
                    required property int index
                    readonly property bool current: GridView.isCurrentItem
                    // Stagger tiles in along the diagonal while the drawer opens.
                    readonly property real appear: Math.max(0, Math.min(1, ov.progress * 2.4 - (Math.floor(index / root.cols) + index % root.cols) * 0.09))

                    width: grid.cellWidth
                    height: grid.cellHeight
                    opacity: appear
                    scale: (0.82 + 0.18 * appear) * (area.pressed ? 0.94 : 1)

                    Behavior on scale { enabled: ov.progress === 1; Anim { ms: 260; curve: Theme.curve.spring } }

                    // A / command: one line with what it does.
                    Item {
                        anchors.fill: parent
                        visible: app.modelData.slash === true

                        Rectangle {
                            id: badge
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 36
                            height: 36
                            radius: Theme.radius.sm
                            color: app.current ? Theme.accent : Theme.layerHi

                            Behavior on color { CAnim {} }

                            Icon {
                                anchors.centerIn: parent
                                name: app.modelData.glyph || "circle"
                                size: 19
                                fill: app.current
                                color: app.current ? Theme.accentInk : Theme.text
                            }
                        }

                        Txt {
                            id: slashName
                            anchors.left: badge.right
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: app.modelData.name
                            mono: true
                            size: 13.5
                            font.weight: Font.DemiBold
                            color: app.current ? Theme.softInk : Theme.text
                        }

                        Txt {
                            anchors.left: slashName.right
                            anchors.leftMargin: 14
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: app.modelData.hint || ""
                            elide: Text.ElideRight
                            color: app.current ? Theme.softInk : Theme.textDim
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        spacing: 8
                        visible: app.modelData.slash !== true

                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 52
                            height: 52

                            IconImage {
                                anchors.fill: parent
                                visible: !app.modelData.glyph
                                source: app.modelData.glyph ? "" : Apps.icon(app.modelData)
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: !!app.modelData.glyph
                                radius: Theme.radius.md
                                color: Theme.accent

                                Icon {
                                    anchors.centerIn: parent
                                    name: app.modelData.glyph || "circle"
                                    size: 26
                                    fill: true
                                    color: Theme.accentInk
                                }
                            }
                        }

                        Txt {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: app.modelData.name
                            size: 12.5
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            lineHeight: 0.95
                            font.weight: app.current ? Font.DemiBold : Font.Medium
                            color: app.current ? Theme.softInk : Theme.text
                        }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: grid.currentIndex = app.index
                        onClicked: root.activate(app.modelData)
                    }
                }

                Column {
                    anchors.centerIn: parent
                    visible: grid.count === 0 && !banner.show
                    spacing: 10

                    Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "ghost"; size: 44; color: Theme.textMute }
                    Txt { anchors.horizontalCenter: parent.horizontalCenter; text: "Nothing matches “" + root.query + "”"; color: Theme.textMute }
                }
            }
        }
    }
}
