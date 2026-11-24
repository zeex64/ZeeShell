import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.bar

// App tray. Either every icon in the bar, or collapsed behind one arrow that
// opens them in a small popup.
BarItem {
    id: root

    readonly property bool collapsed: Config.tray.collapsed
    readonly property bool open: Ui.active === "tray"

    shown: SystemTray.items.values.length > 0
    interactive: collapsed
    active: collapsed && open
    pad: 10
    spacing: 4
    onClicked: if (collapsed) Ui.popup("tray", mapToItem(null, width / 2, 0).x, screen)

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.collapsed
        // Points away from the bar, toward where the icons appear.
        name: Config.bar.position === "top" ? "caret-down" : "caret-up"
        size: 15
        rotation: root.open ? 180 : 0

        Behavior on rotation { Anim { ms: 320; curve: Theme.curve.spring } }
    }

    Repeater {
        model: root.collapsed ? [] : SystemTray.items.values

        TraySlot {
            id: slot
            required property var modelData
            anchors.verticalCenter: parent.verticalCenter
            item: modelData
            onMenu: Ui.trayMenu(modelData.menu, slot.mapToItem(null, slot.width / 2, 0).x, 0, root.screen)
        }
    }
}
