import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components
import qs.services

// What the bottom drawer shows before you type: every app A to Z (most used
// first) on the left, and your pinned apps plus the shell's own pages on the
// right. Right-click an app to pin or unpin it.
Item {
    id: view

    property var actions: []
    signal launch(var item)

    readonly property var pinned: Config.launcher.pinned.map(id => Apps.all.find(a => a.id === id)).filter(a => a)
    readonly property bool hasPins: pinned.length > 0
    readonly property var tiles: hasPins ? pinned : Apps.search("", "all").slice(0, 12)
    readonly property var rows: {
        const out = [];
        const used = Apps.all.filter(a => Apps.usage[a.id] > 0).sort((a, b) => Apps.usage[b.id] - Apps.usage[a.id]).slice(0, 5);
        if (used.length) {
            out.push({ header: "Most used" });
            for (const a of used) out.push({ app: a });
        }
        let letter = "";
        for (const a of Apps.all) {
            const first = (a.name.charAt(0) || "#").toUpperCase(), key = first >= "A" && first <= "Z" ? first : "#";
            if (key !== letter) {
                letter = key;
                out.push({ header: key });
            }
            out.push({ app: a });
        }
        return out;
    }

    function isPinned(app) { return Config.launcher.pinned.indexOf(app.id) >= 0; }
    function togglePin(app) {
        const p = Config.launcher.pinned.slice(), i = p.indexOf(app.id);
        if (i >= 0) p.splice(i, 1);
        else p.push(app.id);
        Config.launcher.pinned = p;
    }

    // ---- all apps ----
    ListView {
        id: list

        x: 16
        y: 14
        width: 290
        height: parent.height - 14
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: view.rows

        delegate: Item {
            id: row

            required property var modelData
            readonly property var app: modelData.app || null
            readonly property string header: modelData.header || ""

            width: list.width - 12
            height: header !== "" ? 36 : 42

            // section heading: a boxed letter, or a title
            Rectangle {
                visible: row.header.length === 1
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 26
                radius: Theme.radius.xs
                color: Theme.accentSoft

                Txt {
                    anchors.centerIn: parent
                    text: row.header
                    size: 12.5
                    font.weight: Font.Bold
                    color: Theme.softInk
                }
            }

            Txt {
                visible: row.header.length > 1
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                text: row.header
                size: 12
                font.weight: Font.Bold
                color: Theme.accent
            }

            // app
            IconImage {
                visible: row.app !== null
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 28
                source: row.app ? Apps.icon(row.app) : ""
            }

            Txt {
                visible: row.app !== null
                x: 46
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 46 - 26
                text: row.app ? row.app.name : ""
                elide: Text.ElideRight
                font.weight: Font.Medium
            }

            Icon {
                visible: row.app !== null && view.isPinned(row.app)
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                name: "push-pin"
                fill: true
                size: 12
                color: Theme.accent
            }

            StateLayer {
                enabled: row.app !== null
                showHover: row.app !== null
                radius: Theme.radius.sm
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: e => e.button === Qt.RightButton ? view.togglePin(row.app) : view.launch(row.app)
            }
        }
    }

    ScrollHandle {
        flick: list
        anchors.top: list.top
        anchors.bottom: list.bottom
        anchors.right: list.right
    }

    Rectangle {
        x: list.x + list.width + 8
        y: 20
        width: 1
        height: parent.height - 30
        color: Theme.outline
    }

    // ---- pinned and shell tiles ----
    Scroll {
        id: side

        x: list.x + list.width + 18
        y: 14
        width: parent.width - x - 8
        height: parent.height - 14
        contentHeight: col.implicitHeight + 8

        Column {
            id: col
            width: side.width - 14
            spacing: 8

            Txt {
                x: 4
                height: 26
                verticalAlignment: Text.AlignVCenter
                text: view.hasPins ? "Pinned" : "Suggested"
                size: 12
                font.weight: Font.Bold
                color: Theme.accent
            }

            Grid {
                columns: Math.max(1, Math.floor(col.width / 104))

                Repeater {
                    model: view.tiles

                    StartTile {
                        required property var modelData
                        name: modelData.name
                        iconSource: Apps.icon(modelData)
                        marked: view.hasPins
                        onClicked: view.launch(modelData)
                        onRightClicked: view.togglePin(modelData)
                    }
                }
            }

            Txt {
                x: 4
                width: parent.width - 8
                wrapMode: Text.Wrap
                text: view.hasPins ? "Right-click a tile to unpin it." : "Right-click any app to pin it here."
                size: 11.5
                color: Theme.textMute
            }

            Txt {
                x: 4
                height: 30
                verticalAlignment: Text.AlignBottom
                text: "ZeeShell"
                size: 12
                font.weight: Font.Bold
                color: Theme.accent
            }

            Grid {
                columns: Math.max(1, Math.floor(col.width / 104))

                Repeater {
                    model: view.actions

                    StartTile {
                        required property var modelData
                        name: modelData.name
                        glyph: modelData.glyph
                        onClicked: view.launch(modelData)
                    }
                }
            }
        }
    }
}
