import QtQuick
import qs.config
import qs.components
import qs.services

// The explorer's sidebar: the usual folders, your favourites, every drive
// (connected or not), network locations, and the trash.
Rectangle {
    id: root

    required property var win

    // Saved servers plus anything connected that was not saved.
    readonly property var servers: {
        const out = Config.files.servers.map(s => {
            const live = Files.connected(s.uri);
            return { label: s.label, uri: s.uri, path: live ? live.path : "", saved: true, live: !!live };
        });
        for (const n of Files.network) {
            if (n.uri !== "" && Config.files.servers.some(s => Files.sameUri(s.uri, n.uri))) continue;
            out.push({ label: n.label, uri: n.uri, path: n.path, saved: false, live: true });
        }
        return out;
    }

    function connectDialog() {
        win.ask({
            kind: "name", title: "Connect to a server", accept: "Connect", value: "smb://",
            text: "Type its address, for example smb://nas/media, sftp://you@host/home/you, ftp://host or dav://host/files. If it needs a password, a terminal opens so you can type it there.",
            done: v => Files.connectServer(v, p => root.win.go(p))
        });
    }

    color: Theme.alpha(Theme.surfaceHi, 0.35)

    Scroll {
        anchors.fill: parent
        contentHeight: col.implicitHeight + 28

        Column {
            id: col
            x: 10
            y: 14
            width: parent.width - 20
            spacing: 2

            Row {
                x: 8
                height: 44
                spacing: 10

                Logo { anchors.verticalCenter: parent.verticalCenter; size: 26 }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: "Files"; size: 16; font.weight: Font.Bold }
            }

            Repeater {
                model: Files.places

                PlaceRow {
                    required property var modelData
                    win: root.win
                    icon: modelData.icon
                    label: modelData.label
                    path: modelData.path
                }
            }

            // ---- favourites ----
            Item {
                width: parent.width
                height: 36

                Txt {
                    x: 10
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 7
                    text: "Favourites"
                    size: 11
                    font.weight: Font.Bold
                    color: Theme.textMute
                }

                IconBtn {
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    visible: Config.files.bookmarks.indexOf(root.win.path) < 0
                    size: 24
                    iconSize: 12
                    icon: "plus"
                    onClicked: root.win.pin(root.win.path)
                }
            }

            Repeater {
                model: Config.files.bookmarks

                PlaceRow {
                    required property string modelData
                    win: root.win
                    icon: "star"
                    label: Files.nameOf(modelData)
                    path: modelData
                    removable: true
                    onRemoved: Config.files.bookmarks = Config.files.bookmarks.filter(p => p !== modelData)
                }
            }

            // Drop folders here to add them. Also explains the section while it is empty.
            Rectangle {
                width: parent.width
                height: Config.files.bookmarks.length === 0 || pinDrop.containsDrag ? 40 : 10
                radius: Theme.radius.sm
                color: pinDrop.containsDrag ? Theme.accentSoft : "transparent"
                border.width: pinDrop.containsDrag ? 1 : 0
                border.color: Theme.accent

                Behavior on height { Anim { ms: 200 } }

                Txt {
                    anchors.centerIn: parent
                    visible: parent.height > 30
                    width: parent.width - 16
                    horizontalAlignment: Text.AlignHCenter
                    text: pinDrop.containsDrag ? "Drop to add" : "Drag a folder here, or press +"
                    size: 11
                    color: pinDrop.containsDrag ? Theme.softInk : Theme.textMute
                    elide: Text.ElideRight
                }

                DropArea {
                    id: pinDrop
                    anchors.fill: parent
                    anchors.topMargin: -6
                    anchors.bottomMargin: -6
                    keys: ["text/uri-list"]
                    onDropped: d => {
                        for (const u of d.urls) {
                            const p = Files.fromUri(u.toString());
                            Files.isFolder(p, ok => { if (ok) root.win.pin(p); });
                        }
                        d.accept();
                    }
                }
            }

            // ---- drives ----
            Txt {
                x: 10
                height: 30
                verticalAlignment: Text.AlignBottom
                bottomPadding: 6
                text: "Drives"
                size: 11
                font.weight: Font.Bold
                color: Theme.textMute
            }

            Repeater {
                model: Files.drives

                PlaceRow {
                    id: drive
                    required property var modelData
                    readonly property bool live: modelData.mount !== ""

                    win: root.win
                    icon: modelData.system ? "hard-drives" : modelData.removable ? "usb" : "hard-drive"
                    label: modelData.label
                    detail: live ? Files.size(Math.max(0, modelData.total - modelData.used)) + " free of " + Files.size(modelData.total) : "Not connected  ·  " + Files.size(modelData.size)
                    path: modelData.mount
                    used: live ? modelData.used : -1
                    total: modelData.total
                    // The system drive cannot be disconnected.
                    action: modelData.system ? "" : live ? "eject" : "plugs"
                    onActed: live ? Files.disconnectDrive(modelData.dev) : Files.connectDrive(modelData.dev, p => root.win.go(p))
                    onPicked: Files.connectDrive(modelData.dev, p => root.win.go(p))
                }
            }

            // ---- network ----
            Item {
                width: parent.width
                height: 36

                Txt {
                    x: 10
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 7
                    text: "Network"
                    size: 11
                    font.weight: Font.Bold
                    color: Theme.textMute
                }

                IconBtn {
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    size: 24
                    iconSize: 12
                    icon: "plus"
                    onClicked: root.connectDialog()
                }
            }

            Repeater {
                model: root.servers

                PlaceRow {
                    id: server
                    required property var modelData

                    win: root.win
                    icon: modelData.live ? "globe-hemisphere-west" : "globe-simple"
                    label: modelData.label
                    detail: modelData.live ? (modelData.uri || "Connected") : "Not connected"
                    path: modelData.path
                    removable: modelData.saved && !modelData.live
                    action: modelData.uri === "" ? "" : modelData.live ? "eject" : "plugs"
                    onActed: modelData.live ? Files.disconnectServer(modelData.uri) : Files.connectServer(modelData.uri, p => root.win.go(p))
                    onPicked: Files.connectServer(modelData.uri, p => root.win.go(p))
                    onRemoved: Files.forget(modelData.uri)
                }
            }

            PlaceRow {
                win: root.win
                visible: root.servers.length === 0
                icon: "plugs-connected"
                label: "Connect to a server…"
                onPicked: root.connectDialog()
            }

            Item { width: 1; height: 10 }

            PlaceRow {
                win: root.win
                icon: "trash"
                label: "Trash"
                path: Files.trashPath
            }

            Btn {
                visible: root.win.path === Files.trashPath && root.win.entries.length > 0
                x: 6
                implicitHeight: 30
                pad: 12
                kind: "danger"
                icon: "broom"
                text: "Empty the trash"
                onClicked: root.win.ask({ kind: "confirm", title: "Empty the trash?", text: "Everything in it is deleted for good.", accept: "Empty", danger: true, done: () => Files.emptyTrash() })
            }
        }
    }

    Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.outline }
}
