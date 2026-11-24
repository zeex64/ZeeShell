import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components
import qs.services
import "SettingsIndex.js" as Index

// Settings: one window for the whole computer, not just the shell. The
// sidebar lists areas, each area has its pages as tabs, and search finds a
// setting by name. Non-modal: the desktop stays usable so changes can be
// judged live. Drag the top of the window to move it out of the way.
Overlay {
    id: ov

    open: Ui.settingsOpen
    layerName: "settings"
    modal: false
    onDismiss: Ui.settingsOpen = false

    Item {
        id: root

        readonly property Item panel: sheet
        property real dx: 0
        property real dy: 0
        property real grabX: 0
        property real grabY: 0
        property string query: ""

        // An unknown page (an older config, a typo over IPC) lands on Home.
        readonly property string page: Index.pages[Ui.settingsPage] ? Ui.settingsPage : "home"
        readonly property var info: Index.pages[page]
        readonly property var cats: Index.categories
        readonly property int catIndex: Math.max(0, cats.findIndex(c => c.pages.indexOf(page) >= 0))
        readonly property var cat: cats[catIndex]
        readonly property bool tabbed: cat.pages.length > 1
        readonly property bool searching: query.trim() !== ""
        readonly property var hits: searching ? Index.search(query) : []

        function go(where) {
            search.text = "";
            Ui.settingsPage = where;
        }

        // Window dragging. Offsets are kept inside the screen so the panel
        // never ends up somewhere it cannot be grabbed again.
        function grab(p) { grabX = p.x - dx; grabY = p.y - dy; }
        function drag(p) {
            const mx = (width - sheet.width) / 2, my = (height - sheet.height) / 2;
            dx = Math.max(-mx, Math.min(mx, p.x - grabX));
            dy = Math.max(-my, Math.min(my, p.y - grabY));
        }

        // Remembers the tab last open in each area.
        property var lastIn: ({})

        onPageChanged: {
            const l = Object.assign({}, lastIn);
            l[cat.key] = page;
            lastIn = l;
            search.text = ""; // going somewhere ends a search
            swap.restart();
        }
        onSearchingChanged: swap.restart()

        Connections {
            target: Ui
            function onSettingsQueryChanged() {
                if (Ui.settingsQuery === "") return;
                search.text = Ui.settingsQuery;
                Ui.settingsQuery = "";
            }
            function onSettingsOpenChanged() { if (!Ui.settingsOpen) search.text = ""; }
        }

        Panel {
            id: sheet

            width: Math.min(root.width - 60, 1120)
            height: Math.min(root.height - 80, 780)
            x: Math.max(0, Math.min(root.width - width, (root.width - width) / 2 + root.dx))
            y: Math.max(0, Math.min(root.height - height, (root.height - height) / 2 + root.dy + (1 - ov.progress) * 40))
            opacity: ov.progress
            scale: 0.95 + 0.05 * ov.progress

            // ---- sidebar ----
            Rectangle {
                id: nav

                x: 1
                y: 1
                width: 240
                height: parent.height - 2
                topLeftRadius: sheet.radius
                bottomLeftRadius: sheet.radius
                color: Theme.alpha(Theme.surfaceHi, 0.35)

                MouseArea {
                    width: parent.width
                    height: 60
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    preventStealing: true
                    onPressed: e => root.grab(mapToItem(root, e.x, e.y))
                    onPositionChanged: e => { if (pressed) root.drag(mapToItem(root, e.x, e.y)); }
                }

                Row {
                    x: 18
                    y: 18
                    spacing: 10

                    Logo { size: 30 }
                    Txt { anchors.verticalCenter: parent.verticalCenter; text: "Settings"; size: 18; font.weight: Font.Bold }
                }

                Field {
                    id: search
                    x: 12
                    y: 64
                    width: parent.width - 24
                    implicitHeight: 38
                    icon: "magnifying-glass"
                    placeholder: "Find a setting"
                    onTextChanged: root.query = text
                    onAccepted: if (root.hits.length) root.go(root.hits[0].page)
                }

                Rectangle {
                    x: 10
                    y: 116 + root.catIndex * 42
                    width: parent.width - 20
                    height: 38
                    radius: Math.min(Theme.radius.full, 19)
                    color: Theme.accent
                    opacity: root.searching ? 0.35 : 1

                    Behavior on y { Anim { ms: 380; curve: Theme.curve.springSoft } }
                    Behavior on opacity { Anim { ms: 200 } }
                }

                Column {
                    x: 10
                    y: 116
                    width: parent.width - 20
                    spacing: 4

                    Repeater {
                        model: root.cats

                        Item {
                            id: entry

                            required property var modelData
                            required property int index
                            readonly property bool current: root.catIndex === index

                            width: parent.width
                            height: 38

                            Row {
                                x: 14
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: entry.modelData.icon
                                    fill: entry.current
                                    size: 18
                                    color: entry.current ? Theme.accentInk : Theme.textDim
                                    Behavior on color { CAnim {} }
                                }

                                Txt {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: entry.modelData.label
                                    font.weight: entry.current ? Font.DemiBold : Font.Medium
                                    color: entry.current ? Theme.accentInk : Theme.text
                                    Behavior on color { CAnim {} }
                                }
                            }

                            // A dot when this area wants attention.
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                visible: entry.modelData.key === "updates" && Updates.checked && Updates.count > 0
                                width: 8
                                height: 8
                                radius: 4
                                color: entry.current ? Theme.accentInk : Theme.accent
                            }

                            StateLayer {
                                radius: Math.min(Theme.radius.full, 19)
                                showHover: !entry.current
                                // Back to the page last used in that area, or its first.
                                onClicked: root.go(entry.current && !root.searching ? root.page : (root.lastIn[entry.modelData.key] || entry.modelData.pages[0]))
                            }
                        }
                    }
                }

                // Who is signed in; leads to the account page.
                Item {
                    x: 10
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    width: parent.width - 20
                    height: 48

                    ClippingRectangle {
                        id: face
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        radius: 16
                        color: Theme.accent

                        Txt {
                            anchors.centerIn: parent
                            visible: Device.avatar === ""
                            text: Device.user.charAt(0).toUpperCase()
                            font.weight: Font.Bold
                            color: Theme.accentInk
                        }

                        Image {
                            anchors.fill: parent
                            visible: Device.avatar !== ""
                            source: Device.avatar !== "" ? "file://" + Device.avatar + "?" + Device.avatarStamp : ""
                            sourceSize.width: 80
                            fillMode: Image.PreserveAspectCrop
                            cache: false
                            asynchronous: true
                        }
                    }

                    Column {
                        anchors.left: face.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Txt { width: parent.width; text: Device.fullName !== "" ? Device.fullName : Device.user; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        Txt { width: parent.width; text: "ZeeShell " + Device.version + "  ·  Esc closes"; size: 10.5; color: Theme.textMute; elide: Text.ElideRight }
                    }

                    StateLayer {
                        radius: Theme.radius.sm
                        onClicked: root.go("account")
                    }
                }
            }

            // The strip above the page moves the window too.
            MouseArea {
                x: nav.width
                width: parent.width - nav.width - 64
                height: 60
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                preventStealing: true
                onPressed: e => root.grab(mapToItem(root, e.x, e.y))
                onPositionChanged: e => { if (pressed) root.drag(mapToItem(root, e.x, e.y)); }
            }

            // ---- heading ----
            Row {
                x: nav.width + 28
                y: 22
                spacing: 10

                Txt {
                    id: heading
                    text: root.searching ? "Search" : root.cat.label
                    size: 20
                    font.weight: Font.Bold
                }

                Txt {
                    anchors.baseline: heading.baseline
                    visible: root.searching
                    text: root.hits.length === 0 ? "nothing found" : root.hits.length + (root.hits.length === 1 ? " setting" : " settings")
                    color: Theme.textMute
                }
            }

            IconBtn {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                icon: "x"
                flat: false
                onClicked: ov.dismiss()
            }

            // The pages of this area.
            Choice {
                id: tabs
                x: nav.width + 24
                y: 62
                visible: root.tabbed && !root.searching
                options: root.cat.pages.map(p => [p, Index.pages[p].label])
                current: root.page
                onPicked: k => root.go(k)
            }

            Scroll {
                id: scroll

                x: nav.width + 12
                y: tabs.visible ? 108 : 64
                width: parent.width - nav.width - 24
                height: parent.height - y - 12
                contentHeight: (root.searching ? results.implicitHeight : loader.item ? loader.item.implicitHeight : 0) + 20

                Behavior on y { Anim { ms: 260 } }

                Loader {
                    id: loader
                    x: 12
                    width: scroll.width - 24
                    visible: !root.searching
                    source: Qt.resolvedUrl(root.info.file + ".qml")
                    onLoaded: scroll.contentY = 0
                }

                Column {
                    id: results
                    x: 12
                    width: scroll.width - 24
                    visible: root.searching
                    spacing: 8

                    Txt {
                        visible: root.hits.length === 0
                        width: parent.width
                        height: 120
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "No setting matches “" + root.query.trim() + "”"
                        color: Theme.textMute
                    }

                    Repeater {
                        model: root.hits

                        HomeTile {
                            required property var modelData
                            width: results.width
                            height: 64
                            icon: modelData.icon
                            title: modelData.title
                            status: modelData.where
                            onClicked: root.go(modelData.page)
                        }
                    }
                }
            }

            ParallelAnimation {
                id: swap
                Anim { target: scroll; property: "opacity"; from: 0; to: 1; ms: 300 }
                Anim { target: loader; property: "y"; from: 18; to: 0; ms: 380; curve: Theme.curve.enter }
            }
        }
    }
}
