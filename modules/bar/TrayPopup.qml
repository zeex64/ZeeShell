import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import qs.config
import qs.components
import qs.services

// The collapsed tray's icons, shown under its arrow.
Overlay {
    id: ov

    open: Ui.active === "tray"
    layerName: "tray"
    enterMs: 320
    exitMs: 160
    onDismiss: Ui.hide()

    Item {
        id: root

        readonly property Item panel: sheet
        readonly property bool atTop: Config.bar.position === "top"
        readonly property real edge: Config.bar.height + (Config.bar.floating ? Config.bar.margin : 0) + 8
        readonly property int columns: Math.max(1, Math.min(5, SystemTray.items.values.length))

        Panel {
            id: sheet

            width: root.columns * 42 + 20
            height: grid.implicitHeight + 20
            x: Math.max(8, Math.min(root.width - width - 8, Ui.menuX - width / 2))
            y: root.atTop ? root.edge : root.height - root.edge - height
            radius: Theme.radius.lg
            opacity: ov.progress
            scale: 0.9 + 0.1 * ov.progress
            transformOrigin: root.atTop ? Item.Top : Item.Bottom

            Grid {
                id: grid
                x: 10
                y: 10
                columns: root.columns
                spacing: 4

                Repeater {
                    model: SystemTray.items.values

                    TraySlot {
                        required property var modelData
                        required property int index
                        readonly property real appear: Math.max(0, Math.min(1, ov.progress * 2 - index * 0.12))

                        size: 38
                        iconSize: 22
                        item: modelData
                        opacity: appear
                        onActivated: Ui.hide()
                        onMenu: Ui.trayMenu(modelData.menu, Ui.menuX, 0, Ui.screen)
                    }
                }
            }
        }
    }
}
