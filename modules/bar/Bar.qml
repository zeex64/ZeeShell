import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.components
import qs.services

PanelWindow {
    id: win

    required property var modelData
    readonly property bool top: Config.bar.position === "top"
    readonly property int gap: Config.bar.floating ? Config.bar.margin : 0
    readonly property string style: Config.bar.style
    readonly property real shift: Ui.booted ? 0 : (top ? -1 : 1) * (implicitHeight + 12)

    screen: modelData
    color: "transparent"
    implicitHeight: Config.bar.height + gap
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "zeeshell-bar"
    BackgroundEffect.blurRegion: Config.appearance.blur && Ui.booted && style !== "pills" ? blur : null

    anchors {
        top: win.top
        bottom: !win.top
        left: true
        right: true
    }

    Region {
        id: blur
        regions: [
            Region { item: win.style === "solid" ? plate : null; radius: plate.radius },
            Region { item: win.style === "islands" && left.visible ? left : null; radius: left.radius },
            Region { item: win.style === "islands" && center.visible ? center : null; radius: center.radius },
            Region { item: win.style === "islands" && right.visible ? right : null; radius: right.radius }
        ]
    }

    IdleInhibitor {
        window: win
        enabled: Toggles.caffeine
    }

    Item {
        id: bar

        anchors.fill: parent
        anchors.leftMargin: win.gap
        anchors.rightMargin: win.gap
        anchors.topMargin: win.top ? win.gap : 0
        anchors.bottomMargin: win.top ? 0 : win.gap
        opacity: Ui.booted ? 1 : 0
        transform: Translate { y: win.shift; Behavior on y { Anim { ms: 900; curve: Theme.curve.springSoft } } }

        Behavior on opacity { Anim { ms: 500 } }

        Rectangle {
            id: plate
            anchors.fill: parent
            visible: win.style === "solid"
            radius: Config.bar.floating ? Math.min(Theme.radius.lg, height / 2) : 0
            color: Theme.panel
            border.width: Config.bar.floating ? 1 : 0
            border.color: Theme.border
        }

        Section {
            id: left
            anchors.left: parent.left
            modules: Config.bar.left
            screen: win.modelData
        }

        Section {
            id: center
            anchors.horizontalCenter: parent.horizontalCenter
            modules: Config.bar.center
            screen: win.modelData
        }

        Section {
            id: right
            anchors.right: parent.right
            modules: Config.bar.right
            screen: win.modelData
        }
    }
}
