import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// Clipboard history: search on top, the list on the left, a preview of the
// selected entry on the right. Enter copies it back.
Overlay {
    id: ov

    open: Ui.active === "clipboard"
    layerName: "clipboard"
    dim: true
    onDismiss: Ui.hide()
    onOpenChanged: if (open) Clipboard.refresh()

    Item {
        id: root

        readonly property Item panel: sheet
        readonly property string query: search.text.trim().toLowerCase()

        readonly property var items: {
            const q = query, pins = Config.clipboard.pinned;
            const out = [];
            for (const t of pins) if (q === "" || t.toLowerCase().indexOf(q) >= 0) out.push({ pinned: true, text: t, image: false, id: "pin:" + t });
            for (const e of Clipboard.entries) {
                if (!e.image && pins.indexOf(e.text) >= 0) continue;
                const hay = e.image ? "image picture " + e.kind : e.text.toLowerCase();
                if (q === "" || hay.indexOf(q) >= 0) out.push(e);
            }
            return out;
        }
        readonly property var current: list.currentIndex >= 0 && list.currentIndex < items.length ? items[list.currentIndex] : null

        property string previewText: ""
        property string previewImage: ""
        property string previewFor: ""

        function choose(e) {
            if (!e) return;
            if (e.pinned) Clipboard.copyText(e.text);
            else Clipboard.copy(e);
            Ui.hide();
        }

        function removeCurrent() {
            const e = current;
            if (!e) return;
            if (e.pinned) Clipboard.unpin(e.text);
            else Clipboard.remove(e);
        }

        function togglePin() {
            const e = current;
            if (!e || e.image) return;
            if (e.pinned) { Clipboard.unpin(e.text); return; }
            // The list holds a preview only; pin the whole text.
            Clipboard.fullText(e, t => Clipboard.pin(t.replace(/\n$/, "")));
        }

        Component.onCompleted: {
            if (Ui.clipboardSeed === "") return;
            search.text = Ui.clipboardSeed;
            Ui.clipboardSeed = "";
        }

        onItemsChanged: if (list.currentIndex >= items.length) list.currentIndex = Math.max(0, items.length - 1)
        onCurrentChanged: previewDelay.restart()

        Timer {
            id: previewDelay
            interval: 60
            onTriggered: {
                const e = root.current;
                root.previewFor = e ? e.id : "";
                root.previewText = e && !e.image ? e.text : "";
                root.previewImage = "";
                if (!e || e.pinned) return;
                const want = e.id;
                if (e.image) Clipboard.thumb(e, src => { if (root.previewFor === want) root.previewImage = src; });
                else Clipboard.fullText(e, t => { if (root.previewFor === want) root.previewText = t; });
            }
        }

        Panel {
            id: sheet

            anchors.centerIn: parent
            anchors.verticalCenterOffset: (1 - ov.progress) * 36
            width: Math.min(root.width - 80, 880)
            height: Math.min(root.height - 120, 580)
            opacity: ov.progress
            scale: 0.95 + 0.05 * ov.progress

            Field {
                id: search
                x: 20
                y: 20
                width: parent.width - 40 - clearBtn.width - 12
                implicitHeight: 48
                icon: "clipboard-text"
                placeholder: "Search the clipboard history"
                autoFocus: true
                onAccepted: root.choose(root.current)
                onKey: e => {
                    const n = list.count;
                    if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab) list.currentIndex = Math.min(n - 1, list.currentIndex + 1);
                    else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab) list.currentIndex = Math.max(0, list.currentIndex - 1);
                    else if (e.key === Qt.Key_PageDown) list.currentIndex = Math.min(n - 1, list.currentIndex + 8);
                    else if (e.key === Qt.Key_PageUp) list.currentIndex = Math.max(0, list.currentIndex - 8);
                    else if (e.key === Qt.Key_Delete && (search.text === "" || search.input.cursorPosition === search.text.length)) root.removeCurrent();
                    else if (e.key === Qt.Key_P && (e.modifiers & Qt.ControlModifier)) root.togglePin();
                    else return;
                    e.accepted = true;
                }
            }

            Btn {
                id: clearBtn
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: search.verticalCenter
                kind: "ghost"
                icon: "broom"
                text: "Clear"
                enabled: Clipboard.entries.length > 0
                onClicked: Clipboard.wipe()
            }

            ListView {
                id: list

                x: 14
                y: search.y + search.height + 14
                width: 340
                height: foot.y - y - 8
                clip: true
                model: root.items
                spacing: 2
                currentIndex: 0
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: Theme.dur(160)
                highlight: Rectangle { radius: Theme.radius.md; color: Theme.accentSoft }

                delegate: Item {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem

                    width: list.width - 8
                    height: 46

                    Icon {
                        id: kindIcon
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        name: row.modelData.pinned ? "push-pin" : row.modelData.image ? "image" : "text-align-left"
                        fill: row.modelData.pinned
                        size: 17
                        color: row.current ? Theme.softInk : Theme.textDim
                    }

                    Txt {
                        anchors.left: kindIcon.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.image
                            ? "Image  ·  " + row.modelData.kind.toUpperCase() + (row.modelData.dims ? "  ·  " + row.modelData.dims.replace("x", " × ") : "")
                            : row.modelData.text.replace(/\s+/g, " ").trim()
                        elide: Text.ElideRight
                        color: row.current ? Theme.softInk : Theme.text
                        font.weight: row.current ? Font.DemiBold : Font.Normal
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: list.currentIndex = row.index
                        onClicked: root.choose(row.modelData)
                    }
                }

                Column {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    spacing: 10
                    width: parent.width - 40

                    Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "clipboard"; size: 40; color: Theme.textMute }
                    Txt {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        color: Theme.textMute
                        text: !Clipboard.available ? "Clipboard history needs cliphist and wl-clipboard."
                            : root.query !== "" ? "Nothing matches “" + search.text + "”"
                            : Clipboard.loading ? "Loading…" : "Nothing copied yet"
                    }
                }
            }

            ScrollHandle {
                flick: list
                visible: list.contentHeight > list.height + 1
                anchors.top: list.top
                anchors.bottom: list.bottom
                x: list.x + list.width - width + 2
            }

            // Preview of the selected entry.
            Rectangle {
                id: preview

                x: list.x + list.width + 12
                y: list.y
                width: parent.width - x - 20
                height: list.height
                radius: Theme.radius.lg
                color: Theme.layer
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: 14
                    visible: root.current !== null && root.current.image === true
                    source: root.previewImage
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    sourceSize: Qt.size(1200, 1200)
                }

                Scroll {
                    anchors.fill: parent
                    anchors.margins: 16
                    visible: root.current !== null && !root.current.image
                    contentHeight: body.implicitHeight

                    Text {
                        id: body
                        width: parent.width - 10
                        text: root.previewText
                        wrapMode: Text.WrapAnywhere
                        textFormat: Text.PlainText
                        color: Theme.text
                        font.family: Theme.mono
                        font.pixelSize: Theme.fs(13)
                        lineHeight: 1.15
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 12
                    spacing: 6
                    visible: root.current !== null

                    IconBtn {
                        visible: root.current !== null && !root.current.image
                        icon: root.current && root.current.pinned ? "push-pin-slash" : "push-pin"
                        flat: false
                        onClicked: root.togglePin()
                    }
                    IconBtn { icon: "trash"; flat: false; onClicked: root.removeCurrent() }
                    IconBtn { icon: "copy"; active: true; onClicked: root.choose(root.current) }
                }
            }

            Row {
                id: foot
                x: 22
                y: parent.height - height - 16
                spacing: 18

                Repeater {
                    model: [["Enter", "copy"], ["Del", "remove"], ["Ctrl P", "pin"], ["Esc", "close"]]

                    Row {
                        required property var modelData
                        spacing: 6

                        Keycap { anchors.verticalCenter: parent.verticalCenter; label: parent.modelData[0] }
                        Txt { anchors.verticalCenter: parent.verticalCenter; text: parent.modelData[1]; size: 12; color: Theme.textMute }
                    }
                }
            }
        }
    }
}
