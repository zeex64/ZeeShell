import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services

// A full-screen layer that hosts one animated popup. The popup content reads
// `progress` (0 → 1) to drive its own entrance, and names the item that should
// be blurred / hit-tested through its `panel` property.
Scope {
    id: root

    property bool open: false
    property string layerName: "overlay"
    property bool modal: true
    property bool dim: false
    property int enterMs: 460
    property int exitMs: 230
    property var screen: Ui.screen
    default property Component content

    property bool alive: false
    property bool ready: false
    property real progress: open && ready ? 1 : 0

    signal dismiss()

    onOpenChanged: {
        if (open) alive = true;
        else if (progress === 0) { alive = false; ready = false; }
    }
    onProgressChanged: if (progress === 0 && !open) { alive = false; ready = false; }

    Behavior on progress {
        Anim {
            ms: root.open ? root.enterMs : root.exitMs
            curve: root.open ? Theme.curve.enter : Theme.curve.exit
        }
    }

    LazyLoader {
        active: root.alive

        PanelWindow {
            id: win

            screen: root.screen
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            mask: root.modal ? null : hit

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "zeeshell-" + root.layerName
            WlrLayershell.keyboardFocus: Quickshell.env("ZEE_NOGRAB") ? WlrKeyboardFocus.None : root.modal ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
            BackgroundEffect.blurRegion: Config.appearance.blur && root.progress > 0.5 ? blur : null

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Component.onCompleted: Qt.callLater(() => root.ready = true)

            Region { id: hit; item: holder.panel }
            Region { id: blur; item: holder.panel; radius: holder.panel ? holder.panel.radius : 0 }

            Rectangle {
                anchors.fill: parent
                visible: root.dim
                color: Theme.scrim
                opacity: root.progress
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.modal
                acceptedButtons: Qt.AllButtons
                onClicked: root.dismiss()
            }

            FocusScope {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.dismiss()

                Loader {
                    id: holder
                    readonly property Item panel: item && item.panel ? item.panel : null

                    anchors.fill: parent
                    focus: true
                    sourceComponent: root.content
                }
            }
        }
    }
}
