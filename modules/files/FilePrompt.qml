import QtQuick
import qs.config
import qs.components

// The explorer's dialogs, shown over the window: type a name, confirm
// something destructive, or read a file's properties.
//   { kind: "name" | "rename", title, value, stem, accept, done(value) }
//   { kind: "confirm", title, text, accept, danger, done() }
//   { kind: "info", title, rows: [[label, value], ...] }
Item {
    id: root

    required property var win
    readonly property var request: win.prompt
    readonly property bool open: request !== null
    readonly property bool naming: open && (request.kind === "name" || request.kind === "rename")
    readonly property alias typed: field.text

    function accept() {
        if (!request) return;
        const done = request.done, value = field.text;
        win.prompt = null;
        win.stage.forceActiveFocus();
        if (done) done(value);
    }

    function cancel() {
        win.prompt = null;
        win.stage.forceActiveFocus();
    }

    visible: open || sheet.opacity > 0

    // A new request arrived: for the naming kinds, fill the field and select
    // the part of the name before the extension.
    onRequestChanged: {
        if (!request || (request.kind !== "name" && request.kind !== "rename")) return;
        field.text = request.value || "";
        field.input.forceActiveFocus();
        field.input.select(0, request.stem !== undefined ? request.stem : field.text.length);
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.open ? 1 : 0

        Behavior on opacity { Anim { ms: 180 } }

        MouseArea {
            anchors.fill: parent
            enabled: root.open
            acceptedButtons: Qt.AllButtons
            onClicked: root.cancel()
            onWheel: e => e.accepted = true
        }
    }

    Panel {
        id: sheet

        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.open ? 0 : 20
        width: Math.min(parent.width - 60, root.request && root.request.kind === "info" ? 460 : 420)
        height: col.implicitHeight + 40
        color: Theme.alpha(Theme.bg, Math.max(0.95, Theme.panelAlpha))
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.95

        Behavior on opacity { Anim { ms: 160 } }
        Behavior on scale { Anim { ms: 300; curve: Theme.curve.springSoft } }
        Behavior on anchors.verticalCenterOffset { Anim { ms: 300; curve: Theme.curve.springSoft } }

        Column {
            id: col
            x: 22
            y: 20
            width: parent.width - 44
            spacing: 14

            Txt {
                width: parent.width
                text: root.request ? root.request.title || "" : ""
                size: 16
                font.weight: Font.Bold
                wrapMode: Text.Wrap
            }

            Txt {
                visible: !!(root.request && root.request.text)
                width: parent.width
                text: root.request && root.request.text ? root.request.text : ""
                color: Theme.textDim
                wrapMode: Text.Wrap
            }

            Field {
                id: field
                visible: root.naming
                width: parent.width
                icon: "pencil-simple"
                onAccepted: root.accept()
            }

            Column {
                visible: !!(root.request && root.request.kind === "info")
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.request && root.request.rows ? root.request.rows : []

                    Item {
                        id: line
                        required property var modelData
                        width: parent.width
                        height: Math.max(20, value.implicitHeight)

                        Txt { text: line.modelData[0]; color: Theme.textMute; width: 86 }

                        Txt {
                            id: value
                            x: 96
                            width: parent.width - 96
                            text: line.modelData[1]
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: 36

                Row {
                    anchors.right: parent.right
                    spacing: 8

                    Btn {
                        kind: "ghost"
                        text: root.request && root.request.kind === "info" ? "Close" : "Cancel"
                        onClicked: root.cancel()
                    }

                    Btn {
                        visible: !!(root.request && root.request.kind !== "info")
                        kind: root.request && root.request.danger ? "danger" : "filled"
                        text: root.request && root.request.accept ? root.request.accept : "OK"
                        enabled: !root.naming || field.text.trim() !== ""
                        onClicked: root.accept()
                    }
                }
            }
        }
    }
}
