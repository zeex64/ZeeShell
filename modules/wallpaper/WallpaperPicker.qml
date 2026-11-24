import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components
import qs.services

// Wallpaper browser: local library and wallhaven.cc search.
Overlay {
    id: ov

    open: Ui.active === "wallpaper"
    layerName: "wallpapers"
    dim: true
    onDismiss: Ui.hide()

    Item {
        id: root

        readonly property Item panel: sheet
        readonly property string tab: Ui.wallpaperTab
        readonly property bool haven: tab === "haven"
        // The folder as the user knows it: ~/Pictures/Wallpapers, not /home/name/…
        readonly property string shortDir: Wallpapers.dir.startsWith(Config.home + "/") ? "~" + Wallpapers.dir.slice(Config.home.length) : Wallpapers.dir
        readonly property var w: Config.wallpaper

        function flip(bit) {
            const c = w.havenCategories.split("");
            c[bit] = c[bit] === "1" ? "0" : "1";
            if (c.join("") === "000") return;
            w.havenCategories = c.join("");
            Wallpapers.search(search.text);
        }

        onTabChanged: if (haven && Wallpapers.results.length === 0) Wallpapers.search("")
        Component.onCompleted: {
            Wallpapers.scan();
            if (haven && Wallpapers.results.length === 0) Wallpapers.search("");
        }

        Panel {
            id: sheet

            anchors.centerIn: parent
            anchors.verticalCenterOffset: (1 - ov.progress) * 40
            width: Math.min(root.width - 100, 1340)
            height: Math.min(root.height - 100, 880)
            opacity: ov.progress
            scale: 0.95 + 0.05 * ov.progress

            // ---- header ----
            Row {
                id: head
                x: 24
                y: 20
                spacing: 12

                Icon { anchors.verticalCenter: parent.verticalCenter; name: "image"; fill: true; size: 24; color: Theme.accent }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: "Wallpapers"; size: 20; font.weight: Font.Bold }
                Item { width: 8; height: 1 }
                Chip { text: "Library  " + Wallpapers.local.length; icon: "folder"; active: !root.haven; onClicked: Ui.wallpaperTab = "local" }
                Chip { text: "wallhaven"; icon: "globe-hemisphere-west"; active: root.haven; onClicked: Ui.wallpaperTab = "haven" }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: head.verticalCenter
                spacing: 6

                Field {
                    id: search
                    visible: root.haven
                    width: 300
                    implicitHeight: 38
                    icon: "magnifying-glass"
                    placeholder: "Search wallhaven"
                    autoFocus: true
                    onAccepted: Wallpapers.search(text)
                }

                IconBtn { icon: "shuffle"; flat: false; visible: !root.haven; onClicked: Wallpapers.random() }
                IconBtn { icon: "arrows-clockwise"; flat: false; onClicked: root.haven ? Wallpapers.search(search.text) : Wallpapers.scan() }
                IconBtn { icon: "folder-open"; flat: false; onClicked: Quickshell.execDetached(["xdg-open", Wallpapers.dir]) }
            }

            // ---- wallhaven filters ----
            Row {
                id: filters
                x: 24
                y: 70
                height: root.haven ? 32 : 0
                visible: root.haven
                spacing: 6

                Repeater {
                    model: [["toplist", "Top", "trophy"], ["hot", "Hot", "fire"], ["date_added", "New", "sparkle"], ["views", "Views", "eye"], ["random", "Random", "shuffle"]]

                    Chip {
                        required property var modelData
                        text: modelData[1]
                        icon: modelData[2]
                        active: root.w.havenSorting === modelData[0]
                        onClicked: { root.w.havenSorting = modelData[0]; Wallpapers.search(search.text); }
                    }
                }

                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 18; color: Theme.outlineHi }

                Repeater {
                    model: root.w.havenSorting === "toplist" ? ["1d", "1w", "1M", "1y"] : []

                    Chip {
                        required property string modelData
                        text: modelData
                        active: root.w.havenRange === modelData
                        onClicked: { root.w.havenRange = modelData; Wallpapers.search(search.text); }
                    }
                }

                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 18; color: Theme.outlineHi; visible: root.w.havenSorting === "toplist" }

                Repeater {
                    model: ["General", "Anime", "People"]

                    Chip {
                        required property string modelData
                        required property int index
                        text: modelData
                        active: root.w.havenCategories.charAt(index) === "1"
                        onClicked: root.flip(index)
                    }
                }
            }

            // ---- grid ----
            ScrollHandle {
                flick: grid
                z: 5
                anchors.top: grid.top
                anchors.bottom: grid.bottom
                anchors.right: parent.right
                anchors.rightMargin: 2
            }

            GridView {
                id: grid

                readonly property int columns: Math.max(2, Math.floor(width / 270))

                anchors.fill: parent
                anchors.topMargin: filters.y + filters.height + 14
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.bottomMargin: 44
                clip: true
                cellWidth: Math.floor(width / columns)
                cellHeight: Math.round(cellWidth * 0.6)
                cacheBuffer: 600
                model: ScriptModel { values: root.haven ? Wallpapers.results : Wallpapers.local }
                onAtYEndChanged: if (atYEnd && root.haven && count > 0) Wallpapers.more()

                delegate: Item {
                    id: tile

                    required property var modelData
                    readonly property bool remote: typeof modelData !== "string"
                    readonly property string file: remote ? Wallpapers.fileFor(modelData) : modelData
                    readonly property bool current: Wallpapers.current === file
                    readonly property bool busy: remote && Wallpapers.busy[modelData.id] === true
                    readonly property bool saved: remote && Wallpapers.local.indexOf(file) >= 0

                    width: grid.cellWidth
                    height: grid.cellHeight

                    ClippingRectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: Theme.radius.md
                        color: Theme.layer
                        scale: hit.pressed ? 0.96 : hit.containsMouse ? 1.025 : 1

                        Behavior on scale { Anim { ms: 340; curve: Theme.curve.spring } }

                        Image {
                            anchors.fill: parent
                            source: tile.remote ? tile.modelData.thumb : "file://" + tile.modelData
                            sourceSize: Qt.size(560, 336)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            opacity: status === Image.Ready ? 1 : 0
                            scale: hit.containsMouse ? 1.06 : 1

                            Behavior on opacity { Anim { ms: 420 } }
                            Behavior on scale { Anim { ms: 600 } }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 40
                            opacity: hit.containsMouse || tile.busy ? 1 : 0
                            gradient: Gradient {
                                GradientStop { position: 0; color: "transparent" }
                                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.7) }
                            }

                            Behavior on opacity { Anim { ms: 200 } }

                            Txt {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 9
                                text: tile.remote ? tile.modelData.resolution + "  ·  " + SysInfo.bytes(tile.modelData.size) : tile.modelData.split("/").pop()
                                size: 11.5
                                color: "white"
                                elide: Text.ElideMiddle
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: tile.busy
                            color: Qt.rgba(0, 0, 0, 0.5)
                            Spinner { anchors.centerIn: parent; size: 30; color: "white" }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radius.md
                            color: "transparent"
                            border.width: 3
                            border.color: Theme.accent
                            visible: tile.current
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 8
                            width: 26
                            height: 26
                            radius: 13
                            visible: tile.current || tile.saved
                            color: tile.current ? Theme.accent : Qt.rgba(0, 0, 0, 0.55)

                            Icon {
                                anchors.centerIn: parent
                                name: tile.current ? "check" : "download-simple"
                                size: 14
                                color: tile.current ? Theme.accentInk : "white"
                            }
                        }
                    }

                    MouseArea {
                        id: hit
                        anchors.fill: parent
                        anchors.margins: 6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tile.remote ? Wallpapers.grab(tile.modelData) : Wallpapers.apply(tile.modelData)
                    }
                }

                Column {
                    anchors.centerIn: parent
                    visible: grid.count === 0 && !Wallpapers.loading
                    spacing: 10

                    Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "image-broken"; size: 44; color: Theme.textMute }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.haven ? (Wallpapers.error || "No results") : "No images in " + Wallpapers.dir
                        color: Theme.textMute
                    }
                }

                Spinner {
                    anchors.centerIn: parent
                    size: 34
                    visible: root.haven && Wallpapers.loading && grid.count === 0
                }
            }

            // ---- footer ----
            Txt {
                x: 24
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 15
                width: parent.width - 48
                elide: Text.ElideMiddle
                size: 12
                color: Wallpapers.error !== "" && root.haven ? Theme.danger : Theme.textMute
                text: root.haven
                    ? (Wallpapers.error !== "" ? Wallpapers.error : Wallpapers.loading ? "Loading…" : Wallpapers.results.length + " results  ·  click to download into " + root.shortDir + " and apply")
                    : root.shortDir + "  ·  click to apply"
            }
        }
    }
}
