import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.components
import qs.services

// Stack of incoming notifications on the focused monitor.
PanelWindow {
    id: win

    readonly property string pos: Config.notifications.position
    readonly property bool atTop: pos.startsWith("top")
    readonly property bool atLeft: pos.endsWith("left")
    readonly property bool centered: pos.endsWith("center")
    readonly property int count: Notifs.popups.length

    onCountChanged: if (count === 0) linger.restart()

    // A chosen monitor if it is connected, otherwise wherever you are working.
    screen: {
        const want = Config.notifications.monitor;
        if (want !== "") for (const s of Quickshell.screens) if (s.name === want) return s;
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        for (const s of Quickshell.screens) if (s.name === name) return s;
        return Quickshell.screens[0];
    }
    visible: count > 0 || linger.running
    color: "transparent"
    implicitWidth: 400
    implicitHeight: Math.min(screen.height - 80, 760)
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    mask: Region { item: hitbox }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "zeeshell-notifications"
    // Only while typing a reply; otherwise popups never take the keyboard.
    WlrLayershell.keyboardFocus: Notifs.replying && !Quickshell.env("ZEE_NOGRAB") ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: win.atTop
        bottom: !win.atTop
        left: win.atLeft && !win.centered
        right: !win.atLeft && !win.centered
    }

    margins {
        top: 10
        bottom: 10
        left: 10
        right: 10
    }

    Timer { id: linger; interval: 600 }

    Item {
        id: hitbox
        width: parent.width
        height: Math.min(parent.height, list.contentHeight)
        y: win.atTop ? 0 : parent.height - height
    }

    ListView {
        id: list

        anchors.fill: parent
        interactive: false
        spacing: 10
        verticalLayoutDirection: win.atTop ? ListView.TopToBottom : ListView.BottomToTop
        model: ScriptModel { values: [...Notifs.popups] }

        delegate: NotifCard {
            required property var modelData
            width: list.width
            entry: modelData
            popup: true
        }

        add: Transition {
            Anim { property: "x"; from: win.centered ? 0 : (win.atLeft ? -420 : 420); to: 0; ms: 520; curve: Theme.curve.springSoft }
            Anim { property: "scale"; from: 0.9; to: 1; ms: 520; curve: Theme.curve.springSoft }
            Anim { property: "opacity"; from: 0; to: 1; ms: 260 }
        }
        remove: Transition {
            Anim { property: "x"; to: win.centered ? 0 : (win.atLeft ? -420 : 420); ms: 320; curve: Theme.curve.exit }
            Anim { property: "opacity"; to: 0; ms: 320 }
        }
        displaced: Transition {
            Anim { properties: "x,y"; ms: 420 }
            Anim { property: "opacity"; to: 1; ms: 200 }
        }
    }
}
