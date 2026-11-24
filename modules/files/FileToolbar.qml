import QtQuick
import qs.config
import qs.components
import qs.services

// Back / forward / up, the path (as crumbs, or typed), search and view controls.
Item {
    id: root

    required property var win
    property bool editing: false

    // Home is shown as one crumb rather than /home/you.
    readonly property var crumbs: {
        const out = [], home = Config.home, p = win.path;
        let rest = p;
        if (p === home || p.indexOf(home + "/") === 0) {
            out.push({ label: "Home", path: home, icon: "house" });
            rest = p.slice(home.length);
        } else {
            out.push({ label: "/", path: "/", icon: "hard-drives" });
        }
        let at = out[0].path === "/" ? "" : out[0].path;
        for (const part of rest.split("/")) {
            if (part === "") continue;
            at += "/" + part;
            out.push({ label: part, path: at, icon: "" });
        }
        return out;
    }

    function editPath() {
        editing = true;
        typed.text = win.path;
        typed.input.forceActiveFocus();
        typed.input.selectAll();
    }

    function focusSearch(text) {
        search.input.forceActiveFocus();
        if (text !== "") {
            search.text += text;
            win.filter = search.text;
        }
    }

    Row {
        id: nav
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        IconBtn { icon: "arrow-left"; opacity: root.win.back.length ? 1 : 0.35; onClicked: root.win.goBack() }
        IconBtn { icon: "arrow-right"; opacity: root.win.forward.length ? 1 : 0.35; onClicked: root.win.goForward() }
        IconBtn { icon: "arrow-up"; opacity: root.win.path !== "/" ? 1 : 0.35; onClicked: root.win.goUp() }
    }

    // ---- path ----
    Rectangle {
        id: pathBox

        anchors.left: nav.right
        anchors.leftMargin: 10
        anchors.right: actions.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        height: 38
        radius: Math.min(Theme.radius.full, 19)
        color: Theme.layer
        clip: true

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: root.editPath()
        }

        Row {
            visible: !root.editing
            // When the path is too long, keep its end in view.
            x: Math.min(8, parent.width - implicitWidth - 8)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Repeater {
                model: root.crumbs

                Row {
                    id: crumb
                    required property var modelData
                    required property int index
                    readonly property bool last: index === root.crumbs.length - 1

                    spacing: 0

                    Icon {
                        visible: crumb.index > 0
                        anchors.verticalCenter: parent.verticalCenter
                        name: "caret-right"
                        size: 11
                        color: Theme.textMute
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: inner.implicitWidth + 16
                        height: 28
                        radius: Math.min(Theme.radius.full, 14)
                        color: crumb.last ? Theme.accentSoft : "transparent"

                        Row {
                            id: inner
                            anchors.centerIn: parent
                            spacing: 6

                            Icon {
                                visible: crumb.modelData.icon !== ""
                                anchors.verticalCenter: parent.verticalCenter
                                name: crumb.modelData.icon || "folder"
                                size: 14
                                color: crumb.last ? Theme.softInk : Theme.textDim
                            }

                            Txt {
                                anchors.verticalCenter: parent.verticalCenter
                                text: crumb.modelData.label
                                size: 12.5
                                font.weight: crumb.last ? Font.DemiBold : Font.Medium
                                color: crumb.last ? Theme.softInk : Theme.textDim
                            }
                        }

                        StateLayer {
                            radius: parent.radius
                            onClicked: root.win.go(crumb.modelData.path)
                        }

                        DropArea {
                            anchors.fill: parent
                            keys: ["text/uri-list"]
                            onDropped: d => {
                                root.win.receive(d.urls, crumb.modelData.path, d.proposedAction === Qt.MoveAction);
                                d.acceptProposedAction();
                            }
                        }
                    }
                }
            }
        }

        Field {
            id: typed
            visible: root.editing
            anchors.fill: parent
            color: "transparent"
            border.width: 0
            icon: "folder-open"
            placeholder: "Type a folder"
            onAccepted: {
                root.win.tryGo(text);
                root.editing = false;
                root.win.stage.forceActiveFocus();
            }

            Connections {
                target: typed.input
                function onActiveFocusChanged() { if (!typed.input.activeFocus) root.editing = false; }
            }
        }
    }

    // ---- search and view ----
    Row {
        id: actions
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Field {
            id: search
            anchors.verticalCenter: parent.verticalCenter
            width: 190
            implicitHeight: 38
            icon: "magnifying-glass"
            placeholder: "Filter this folder"
            onAccepted: root.win.stage.forceActiveFocus()

            Connections {
                target: search.input
                function onTextEdited() { root.win.filter = search.text; }
            }

            Connections {
                target: root.win
                function onFilterChanged() { if (search.text !== root.win.filter) search.text = root.win.filter; }
            }
        }

        Item { width: 6; height: 1 }

        IconBtn {
            icon: root.win.grid ? "list-dashes" : "squares-four"
            onClicked: Config.files.view = root.win.grid ? "list" : "grid"
        }

        IconBtn {
            id: sortBtn
            icon: Config.files.sortReversed ? "sort-descending" : "sort-ascending"
            onClicked: {
                const p = sortBtn.mapToItem(root.win.stage, 0, sortBtn.height + 6);
                root.win.sortMenu(p.x - 150, p.y);
            }
        }

        IconBtn { icon: "folder-plus"; onClicked: root.win.newFolder() }

        IconBtn {
            id: moreBtn
            icon: "dots-three"
            onClicked: {
                const p = moreBtn.mapToItem(root.win.stage, 0, moreBtn.height + 6);
                root.win.clearSelection();
                root.win.showMenu(p.x - 220, p.y, null);
            }
        }
    }
}
