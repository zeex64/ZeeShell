import QtQuick
import qs.config
import qs.components

// One audio device or app stream: mute, volume, and (for devices) a mark that
// makes it the one in use.
Item {
    id: root

    property var node: null
    property string icon: "speaker-high"
    property string mutedIcon: "speaker-x"
    property string title: ""
    property string detail: ""
    property bool selectable: false
    property bool chosen: false

    signal choose()

    readonly property var audio: node ? node.audio : null
    readonly property real volume: audio ? audio.volume : 0
    readonly property bool muted: audio ? audio.muted : false

    width: parent ? parent.width : 0
    height: 58

    IconBtn {
        id: mute
        anchors.verticalCenter: parent.verticalCenter
        icon: root.muted ? root.mutedIcon : root.icon
        flat: false
        size: 38
        tint: root.muted ? Theme.danger : root.chosen ? Theme.accent : Theme.text
        onClicked: if (root.audio) root.audio.muted = !root.audio.muted
    }

    Column {
        anchors.left: mute.right
        anchors.leftMargin: 12
        anchors.right: slide.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Txt { width: parent.width; text: root.title; font.weight: root.chosen ? Font.DemiBold : Font.Medium; elide: Text.ElideRight }
        Txt { width: parent.width; visible: root.detail !== ""; text: root.detail; size: 11.5; color: Theme.textMute; elide: Text.ElideRight }
    }

    Slide {
        id: slide
        anchors.right: pct.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 200
        implicitHeight: 28
        width: implicitWidth
        height: implicitHeight
        dimmed: root.muted
        value: Math.min(1, root.volume)
        step: 0.02
        onMoved: v => { if (root.audio) { root.audio.muted = false; root.audio.volume = v; } }
    }

    Txt {
        id: pct
        anchors.right: pick.left
        anchors.rightMargin: root.selectable ? 10 : 0
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.volume * 100) + "%"
        color: Theme.textDim
        font.features: { "tnum": 1 }
    }

    IconBtn {
        id: pick
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.selectable
        width: root.selectable ? size : 0
        icon: root.chosen ? "check-circle" : "circle"
        fill: root.chosen
        tint: root.chosen ? Theme.accent : Theme.textMute
        onClicked: root.choose()
    }
}
