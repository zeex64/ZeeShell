import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components
import qs.services

// A live picture of one window, with its app icon. Used by the overview and
// the Alt-Tab switcher.
ClippingRectangle {
    id: root

    required property var client
    property bool live: true
    property bool highlighted: false
    property real iconSize: Math.max(18, Math.min(48, Math.min(width, height) * 0.32))
    readonly property var source: client ? Windows.toplevel(client.address) : null

    radius: Theme.radius.sm
    color: Theme.layerHi
    border.width: highlighted ? 2 : 1
    border.color: highlighted ? Theme.accent : Theme.outline

    ScreencopyView {
        id: shot
        anchors.fill: parent
        captureSource: root.source
        live: root.live
        paintCursor: false
    }

    IconImage {
        anchors.centerIn: parent
        visible: !shot.hasContent
        implicitSize: root.iconSize
        source: root.client ? Hypr.appIcon(root.client.cls) : ""
    }

    // App badge in the corner once the picture is there.
    Rectangle {
        visible: shot.hasContent && root.width > 90
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 6
        width: 26
        height: 26
        radius: Theme.radius.xs
        color: Theme.alpha(Theme.bg, 0.8)

        IconImage {
            anchors.centerIn: parent
            implicitSize: 18
            source: root.client ? Hypr.appIcon(root.client.cls) : ""
        }
    }
}
