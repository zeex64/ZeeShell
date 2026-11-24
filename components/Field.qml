import QtQuick
import qs.config

Rectangle {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder: ""
    property string icon: ""
    property bool password: false
    property bool autoFocus: false

    signal accepted()
    signal key(var event)
    signal editingDone()

    Component.onCompleted: if (autoFocus) input.forceActiveFocus()

    implicitHeight: 42
    implicitWidth: 260
    radius: Math.min(Theme.radius.full, height / 2)
    color: Theme.layer
    border.width: 1
    border.color: input.activeFocus ? Theme.alpha(Theme.accent, 0.7) : "transparent"

    Behavior on border.color { CAnim {} }

    Icon {
        id: glyph
        visible: root.icon !== ""
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: 17
        color: input.activeFocus ? Theme.accent : Theme.textDim

        Behavior on color { CAnim {} }
    }

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: root.icon !== "" ? 42 : 16
        anchors.rightMargin: 16
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        color: Theme.text
        selectionColor: Theme.accentSoft
        selectedTextColor: Theme.softInk
        font.family: Theme.font
        font.pixelSize: Theme.fs(14)
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        selectByMouse: true
        focus: root.autoFocus
        onAccepted: root.accepted()
        onEditingFinished: root.editingDone()
        Keys.onPressed: e => root.key(e)

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === "" && input.preeditText === ""
            text: root.placeholder
            size: 14
            color: Theme.textMute
        }
    }
}
