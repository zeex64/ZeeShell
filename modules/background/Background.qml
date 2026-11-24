import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.widgets

// Wallpaper layer. A new wallpaper is revealed on top of the old one, then
// swapped underneath once the reveal completes.
PanelWindow {
    id: win

    required property var modelData
    readonly property string target: Wallpapers.current
    readonly property real diag: Math.sqrt(width * width + height * height)
    property real t: 0

    function load() {
        if (target === "") return;
        const url = "file://" + target;
        if (url == base.source && !reveal.visible) return;
        anim.stop();
        t = 0;
        if (base.source == "") {
            base.opacity = 0;
            base.source = url;
        } else {
            next.source = "";
            next.source = url;
        }
    }

    screen: modelData
    color: Theme.bg
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "zeeshell-wallpaper"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onTargetChanged: load()
    Component.onCompleted: load()

    Image {
        id: base
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(win.width, win.height)
        onStatusChanged: {
            if (status !== Image.Ready) return;
            opacity = 1;
            if (reveal.visible) settle.restart();
        }

        Behavior on opacity { Anim { ms: 900 } }
    }

    // Let the swapped base image paint for a frame before dropping the overlay.
    Timer {
        id: settle
        interval: 60
        onTriggered: {
            reveal.visible = false;
            next.source = "";
            win.t = 0;
        }
    }

    ClippingRectangle {
        id: reveal

        readonly property string mode: Config.wallpaper.transition

        visible: false
        color: "transparent"
        opacity: mode === "fade" ? win.t : 1
        width: mode === "circle" ? win.diag * win.t : mode === "wipe" ? win.width * win.t : win.width
        height: mode === "circle" ? width : win.height
        x: mode === "circle" ? (win.width - width) / 2 : 0
        y: mode === "circle" ? (win.height - height) / 2 : 0
        radius: mode === "circle" ? width / 2 : 0

        Image {
            id: next
            x: -reveal.x
            y: -reveal.y
            width: win.width
            height: win.height
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(win.width, win.height)
            onStatusChanged: {
                if (status === Image.Ready) {
                    reveal.visible = true;
                    anim.restart();
                } else if (status === Image.Error) {
                    reveal.visible = false;
                }
            }
        }
    }

    NumberAnimation {
        id: anim
        target: win
        property: "t"
        from: 0
        to: 1
        duration: Theme.dur(Config.wallpaper.transitionMs)
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.45, 0, 0.15, 1, 1, 1]
        onFinished: base.source = next.source
    }

    Loader {
        anchors.fill: parent
        active: Config.widgets.enabled
        sourceComponent: WidgetLayer { screen: win.modelData }
    }
}
