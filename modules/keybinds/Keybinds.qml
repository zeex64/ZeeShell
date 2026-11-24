import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// Cheat sheet built live from `hyprctl binds`.
Overlay {
    id: ov

    open: Ui.active === "keybinds"
    layerName: "keybinds"
    dim: true
    onDismiss: Ui.hide()
    onOpenChanged: if (open) Hypr.refreshBinds()

    component Key: Rectangle {
        property string label

        implicitWidth: Math.max(26, cap.implicitWidth + 14)
        implicitHeight: 24
        radius: Theme.radius.xs
        color: Theme.layerHi
        border.width: 1
        border.color: Theme.outlineHi

        Txt {
            id: cap
            anchors.centerIn: parent
            text: parent.label
            size: 11.5
            font.weight: Font.DemiBold
            color: Theme.text
        }
    }

    Item {
        id: root

        readonly property Item panel: sheet
        readonly property int columns: sheet.width > 1000 ? 3 : 2
        readonly property var order: ["Shell", "Windows", "Workspaces", "Apps", "Media", "Capture", "Other"]
        readonly property var icons: ({ Shell: "sparkle", Windows: "app-window", Workspaces: "circles-three", Apps: "rocket-launch", Media: "music-notes", Capture: "camera", Other: "dots-three-circle" })

        // Filter, group by category, then deal groups into balanced columns.
        readonly property var layout: {
            const q = search.text.trim().toLowerCase();
            const groups = {};
            for (const b of Hypr.binds) {
                if (q !== "" && (b.description + " " + b.mods.join(" ") + " " + b.key).toLowerCase().indexOf(q) < 0) continue;
                (groups[b.category] = groups[b.category] || []).push(b);
            }
            const cols = [];
            for (let i = 0; i < columns; i++) cols.push({ size: 0, groups: [] });
            for (const name of order) {
                if (!groups[name]) continue;
                let c = cols[0];
                for (const x of cols) if (x.size < c.size) c = x;
                c.groups.push({ name: name, binds: groups[name] });
                c.size += groups[name].length + 2;
            }
            return cols;
        }

        Panel {
            id: sheet

            anchors.centerIn: parent
            anchors.verticalCenterOffset: (1 - ov.progress) * 36
            width: Math.min(root.width - 100, 1180)
            height: Math.min(root.height - 110, 780)
            opacity: ov.progress
            scale: 0.95 + 0.05 * ov.progress

            Row {
                id: head
                x: 24
                y: 22
                spacing: 12

                Icon { anchors.verticalCenter: parent.verticalCenter; name: "keyboard"; size: 24; fill: true; color: Theme.accent }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: "Keybindings"; size: 20; font.weight: Font.Bold }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: Hypr.binds.length + " active"; color: Theme.textMute }
            }

            Field {
                id: search
                anchors.right: parent.right
                anchors.rightMargin: 22
                y: 14
                width: 300
                icon: "magnifying-glass"
                placeholder: "Filter"
                autoFocus: true
            }

            Scroll {
                anchors.fill: parent
                anchors.topMargin: 72
                anchors.margins: 20
                contentHeight: cols.implicitHeight

                Row {
                    id: cols
                    width: parent.width
                    spacing: 16

                    Repeater {
                        model: root.layout

                        Column {
                            id: column
                            required property var modelData
                            width: (cols.width - cols.spacing * (root.columns - 1)) / root.columns
                            spacing: 16

                            Repeater {
                                model: column.modelData.groups

                                Card {
                                    id: group
                                    required property var modelData
                                    width: column.width
                                    height: list.implicitHeight + 24

                                    Column {
                                        id: list
                                        x: 14
                                        y: 12
                                        width: parent.width - 28
                                        spacing: 2

                                        Row {
                                            height: 30
                                            spacing: 8
                                            Icon { anchors.verticalCenter: parent.verticalCenter; name: root.icons[group.modelData.name]; size: 16; color: Theme.accent }
                                            Txt { anchors.verticalCenter: parent.verticalCenter; text: group.modelData.name; font.weight: Font.Bold; color: Theme.accent }
                                        }

                                        Repeater {
                                            model: group.modelData.binds

                                            Item {
                                                id: bind
                                                required property var modelData
                                                width: list.width
                                                height: 32

                                                Txt {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: parent.width - keys.width - 12
                                                    text: bind.modelData.description + (bind.modelData.submap !== "" ? "  (" + bind.modelData.submap + ")" : "")
                                                    elide: Text.ElideRight
                                                    color: Theme.textDim
                                                }

                                                Row {
                                                    id: keys
                                                    anchors.right: parent.right
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    spacing: 4

                                                    Repeater {
                                                        model: bind.modelData.mods.concat([bind.modelData.key])
                                                        Key { required property string modelData; label: modelData }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Txt {
                anchors.centerIn: parent
                visible: Hypr.binds.length === 0
                text: "No keybindings reported by Hyprland"
                color: Theme.textMute
            }
        }
    }
}
