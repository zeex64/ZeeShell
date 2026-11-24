import QtQuick
import qs.config
import qs.components

// A settings row whose value is picked from a list that unfolds under it.
// options: [[key, label, detail], ...]; long lists can be made searchable.
Column {
    id: root

    property string label: ""
    property string hint: ""
    property var options: []
    property var current
    property bool searchable: false
    property string placeholder: "Choose"
    property real buttonWidth: 250
    property bool open: false
    property string query: ""

    signal picked(var key)
    signal opened()

    readonly property var chosen: options.find(o => o[0] === current)
    readonly property var shown: {
        const q = query.trim().toLowerCase();
        if (q === "") return options;
        return options.filter(o => String(o[1]).toLowerCase().indexOf(q) >= 0 || String(o[2] || "").toLowerCase().indexOf(q) >= 0 || String(o[0]).toLowerCase().indexOf(q) >= 0);
    }
    readonly property real listHeight: Math.min(shown.length, 6) * 38 + (searchable ? 48 : 0) + 12

    width: parent ? parent.width : 0
    onOpenChanged: { query = ""; if (open) opened(); }

    Opt {
        label: root.label
        hint: root.hint

        Rectangle {
            width: root.buttonWidth
            height: 36
            radius: Math.min(Theme.radius.full, 18)
            color: root.open ? Theme.accentSoft : Theme.layerHi

            Behavior on color { CAnim {} }

            Txt {
                x: 16
                width: parent.width - 48
                anchors.verticalCenter: parent.verticalCenter
                text: root.chosen ? root.chosen[1] : root.placeholder
                font.weight: Font.DemiBold
                size: 12.5
                elide: Text.ElideRight
                color: root.open ? Theme.softInk : root.chosen ? Theme.text : Theme.textMute
            }

            Icon {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                name: "caret-down"
                size: 14
                color: root.open ? Theme.softInk : Theme.textDim
                rotation: root.open ? 180 : 0
                Behavior on rotation { Anim { ms: 300; curve: Theme.curve.springSoft } }
            }

            StateLayer { onClicked: root.open = !root.open }
        }
    }

    Item {
        width: parent.width
        height: root.open ? root.listHeight : 0
        visible: height > 0.5
        clip: true

        Behavior on height { Anim { ms: 320; curve: Theme.curve.enter } }

        Rectangle {
            width: parent.width
            height: root.listHeight - 6
            radius: Theme.radius.sm
            color: Theme.alpha(Theme.surfaceTop, 0.5)
            border.width: 1
            border.color: Theme.border

            Field {
                id: search
                x: 8
                y: 8
                width: parent.width - 16
                implicitHeight: 34
                visible: root.searchable
                icon: "magnifying-glass"
                placeholder: "Search"
                onTextChanged: root.query = text
                Connections {
                    target: root
                    function onOpenChanged() { search.text = ""; if (root.open && root.searchable) search.input.forceActiveFocus(); }
                }
            }

            ListView {
                id: list
                x: 4
                y: root.searchable ? 48 : 4
                width: parent.width - 8
                height: parent.height - y - 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.open ? root.shown : []

                delegate: Item {
                    id: row
                    required property var modelData
                    readonly property bool current: modelData[0] === root.current

                    width: list.width
                    height: 38

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: Theme.radius.xs + 2
                        color: row.current ? Theme.accentSoft : "transparent"
                    }

                    Txt {
                        id: name
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, parent.width - 60)
                        text: row.modelData[1]
                        elide: Text.ElideRight
                        font.weight: row.current ? Font.DemiBold : Font.Medium
                        color: row.current ? Theme.softInk : Theme.text
                    }

                    Txt {
                        anchors.left: name.right
                        anchors.leftMargin: 10
                        anchors.right: tick.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        visible: (row.modelData[2] || "") !== ""
                        text: row.modelData[2] || ""
                        size: 11.5
                        elide: Text.ElideRight
                        color: Theme.textMute
                    }

                    Icon {
                        id: tick
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        visible: row.current
                        name: "check"
                        size: 15
                        color: Theme.softInk
                    }

                    StateLayer {
                        radius: Theme.radius.xs + 2
                        onClicked: { root.picked(row.modelData[0]); root.open = false; }
                    }
                }
            }
        }
    }
}
