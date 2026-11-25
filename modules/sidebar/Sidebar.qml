import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.notifications

// Quick settings pull-out.
Overlay {
    id: ov

    open: Ui.active === "sidebar"
    layerName: "sidebar"
    enterMs: 520
    exitMs: 260
    onDismiss: Ui.hide()

    Item {
        id: root

        readonly property Item panel: sheet
        readonly property bool leftSide: Config.sidebar.side === "left"
        readonly property bool barTop: Config.bar.position === "top"
        readonly property real barSpace: Ui.barOn(Ui.screen) ? Config.bar.height + (Config.bar.floating ? Config.bar.margin : 0) : 0
        readonly property var bt: Bluetooth.defaultAdapter
        property string page: "main" // main | wifi | bluetooth
        property real slide: page === "main" ? 0 : 1

        Behavior on slide { Anim { ms: 420 } }

        Panel {
            id: sheet

            width: Config.sidebar.width
            y: (root.barTop ? root.barSpace : 0) + 10
            height: root.height - root.barSpace - 20
            x: root.leftSide ? -width - 20 + ov.progress * (width + 30) : root.width + 20 - ov.progress * (width + 30)
            opacity: Math.min(1, ov.progress * 1.6)

            Item {
                anchors.fill: parent
                anchors.margins: 1
                clip: true

                // ---------------- main page ----------------
                Scroll {
                    id: main

                    width: parent.width
                    height: parent.height
                    x: -root.slide * width * 0.35
                    opacity: 1 - root.slide
                    visible: opacity > 0
                    contentHeight: col.implicitHeight + 32

                    Column {
                        id: col
                        x: 16
                        y: 16
                        width: parent.width - 32
                        spacing: 12

                        // header
                        Item {
                            width: parent.width
                            height: 48

                            Logo { id: avatar; size: 44; anchors.verticalCenter: parent.verticalCenter }

                            Column {
                                anchors.left: avatar.right
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter

                                Txt { text: SysInfo.user; size: 16; font.weight: Font.Bold }
                                Txt { text: Time.longDate + "  ·  up " + SysInfo.uptimeText(); size: 11.5; color: Theme.textDim }
                            }

                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                IconBtn { icon: "gear"; flat: false; onClicked: Ui.settings() }
                                IconBtn { icon: "lock"; flat: false; onClicked: { Ui.hide(); Ui.locked = true; } }
                                IconBtn { icon: "power"; flat: false; tint: Theme.danger; onClicked: Ui.show("power") }
                            }
                        }

                        // toggles
                        Grid {
                            id: tiles
                            width: parent.width
                            columns: 2
                            spacing: 8

                            readonly property real tw: (width - spacing) / 2

                            QuickTile {
                                width: tiles.tw
                                icon: Network.icon
                                label: "Network"
                                detail: Network.label
                                active: Network.connected
                                more: true
                                onToggled: Network.setWifi(!Network.wifiEnabled)
                                onOpened: root.page = "wifi"
                            }

                            QuickTile {
                                width: tiles.tw
                                icon: "bluetooth"
                                label: "Bluetooth"
                                detail: {
                                    if (!root.bt) return "Unavailable";
                                    if (!root.bt.enabled) return "Off";
                                    const n = Bluetooth.devices.values.filter(d => d.connected);
                                    return n.length === 0 ? "On" : n.length === 1 ? n[0].name : n.length + " devices";
                                }
                                active: root.bt !== null && root.bt.enabled
                                more: root.bt !== null
                                onToggled: if (root.bt) root.bt.enabled = !root.bt.enabled
                                onOpened: root.page = "bluetooth"
                            }

                            QuickTile {
                                width: tiles.tw
                                icon: Notifs.dnd ? "bell-slash" : "bell"
                                label: "Do not disturb"
                                detail: Notifs.dnd ? "Silenced" : "Off"
                                active: Notifs.dnd
                                onToggled: Config.notifications.dnd = !Config.notifications.dnd
                            }

                            QuickTile {
                                width: tiles.tw
                                icon: "moon-stars"
                                label: "Night light"
                                detail: Toggles.nightLight ? Config.sidebar.nightTemp + " K" : "Off"
                                active: Toggles.nightLight
                                onToggled: Toggles.nightLight = !Toggles.nightLight
                            }

                            QuickTile {
                                width: tiles.tw
                                icon: "coffee"
                                label: "Caffeine"
                                detail: Toggles.caffeine ? "Staying awake" : "Off"
                                active: Toggles.caffeine
                                onToggled: Toggles.caffeine = !Toggles.caffeine
                            }

                            QuickTile {
                                width: tiles.tw
                                icon: Config.appearance.dark ? "moon" : "sun"
                                label: "Dark mode"
                                detail: Config.appearance.dark ? "On" : "Off"
                                active: Config.appearance.dark
                                onToggled: Config.appearance.dark = !Config.appearance.dark
                            }

                            // Power mode, and the battery when there is one.
                            QuickTile {
                                width: tiles.tw
                                visible: Power.profiles || Power.hasBattery
                                icon: Power.hasBattery
                                    ? (Power.charging ? "battery-charging" : Power.percent > 0.8 ? "battery-full" : Power.percent > 0.5 ? "battery-high" : Power.percent > 0.2 ? "battery-medium" : "battery-low")
                                    : Power.profile === PowerProfile.PowerSaver ? "leaf" : Power.profile === PowerProfile.Performance ? "lightning" : "gauge"
                                label: Power.profiles ? Power.profileName : "Battery"
                                detail: Power.hasBattery ? Math.round(Power.percent * 100) + "%" + (Power.charging ? " · charging" : "") : "Power mode"
                                active: Power.profiles && Power.profile !== PowerProfile.Balanced
                                more: true
                                onToggled: {
                                    if (!Power.profiles) return;
                                    const order = Power.hasPerformance ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance] : [PowerProfile.PowerSaver, PowerProfile.Balanced];
                                    Power.setProfile(order[(order.indexOf(Power.profile) + 1) % order.length]);
                                }
                                onOpened: Ui.settings("power")
                            }

                            QuickTile {
                                width: tiles.tw
                                icon: "clipboard-text"
                                label: "Clipboard"
                                detail: Clipboard.available ? "History" : "Not installed"
                                onToggled: Ui.show("clipboard")
                            }
                        }

                        // shortcuts
                        Row {
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: [
                                    { icon: "image", label: "Wallpaper", run: () => Ui.show("wallpaper") },
                                    { icon: "keyboard", label: "Keys", run: () => Ui.show("keybinds") },
                                    { icon: "camera", label: "Capture", run: () => { Ui.hide(); Quickshell.execDetached(["hyprshot", "-m", "region"]); } },
                                    { icon: Audio.micMuted ? "microphone-slash" : "microphone", label: "Mic", run: () => Audio.toggleMic() }
                                ]

                                Card {
                                    id: shortcut
                                    required property var modelData
                                    width: (col.width - 24) / 4
                                    height: 58
                                    scale: tap.pressed ? 0.94 : 1
                                    Behavior on scale { Anim { ms: 300; curve: Theme.curve.spring } }

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: shortcut.modelData.icon; size: 19 }
                                        Txt { anchors.horizontalCenter: parent.horizontalCenter; text: shortcut.modelData.label; size: 11; color: Theme.textDim }
                                    }

                                    StateLayer { id: tap; onClicked: shortcut.modelData.run() }
                                }
                            }
                        }

                        // sliders
                        Slide {
                            width: parent.width
                            icon: Audio.icon
                            value: Audio.volume
                            dimmed: Audio.muted
                            onMoved: v => Audio.setVolume(v)
                            onIconClicked: Audio.toggleMute()
                        }

                        Slide {
                            width: parent.width
                            visible: Brightness.available
                            icon: "sun"
                            value: Brightness.value
                            onMoved: v => Brightness.set(v)
                        }

                        MediaCard { width: parent.width; visible: Players.active !== null }
                        WeatherCard { width: parent.width }
                        CalendarCard { width: parent.width }

                        // notifications
                        Item {
                            width: parent.width
                            height: 30

                            Txt {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Notifications" + (Notifs.count > 0 ? "  ·  " + Notifs.count : "")
                                font.weight: Font.Bold
                                size: 14
                            }

                            Btn {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                visible: Notifs.count > 0
                                implicitHeight: 28
                                pad: 12
                                kind: "ghost"
                                icon: "broom"
                                text: "Clear"
                                onClicked: Notifs.clear()
                            }
                        }

                        Column {
                            width: parent.width
                            visible: Notifs.count === 0
                            topPadding: 14
                            bottomPadding: 14
                            spacing: 8

                            Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "bell-z"; size: 34; color: Theme.textMute }
                            Txt { anchors.horizontalCenter: parent.horizontalCenter; text: "All caught up"; color: Theme.textMute }
                        }

                        Repeater {
                            model: Config.notifications.group ? [] : Notifs.all

                            NotifCard {
                                required property var modelData
                                width: col.width
                                entry: modelData
                            }
                        }

                        Repeater {
                            model: Config.notifications.group ? Notifs.groups : []

                            NotifGroup {
                                required property var modelData
                                width: col.width
                                group: modelData
                            }
                        }
                    }
                }

                // ---------------- detail pages ----------------
                Item {
                    width: parent.width
                    height: parent.height
                    x: (1 - root.slide) * width * 0.5
                    opacity: root.slide
                    visible: opacity > 0

                    Row {
                        id: bar
                        x: 12
                        y: 14
                        spacing: 8

                        IconBtn { icon: "arrow-left"; flat: false; onClicked: root.page = "main" }
                        Txt {
                            anchors.verticalCenter: parent.verticalCenter
                            text: sub.shown === "wifi" ? "Wi-Fi" : "Bluetooth"
                            size: 17
                            font.weight: Font.Bold
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: bar.verticalCenter
                        spacing: 10

                        IconBtn {
                            icon: "arrows-clockwise"
                            visible: sub.shown === "wifi"
                            rotation: Network.scanning ? 360 : 0
                            onClicked: Network.scan()
                            Behavior on rotation { Anim { ms: 900 } }
                        }

                        Toggle {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: sub.shown === "wifi" ? Network.wifiEnabled : (root.bt !== null && root.bt.enabled)
                            onToggled: v => {
                                if (sub.shown === "wifi") Network.setWifi(v);
                                else if (root.bt) root.bt.enabled = v;
                            }
                        }
                    }

                    Scroll {
                        anchors.fill: parent
                        anchors.topMargin: 62
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        anchors.bottomMargin: 12
                        contentHeight: sub.item ? sub.item.implicitHeight : 0

                        Loader {
                            id: sub

                            // Keep the last page mounted while it slides away.
                            property string shown: "wifi"

                            width: parent.width
                            active: root.slide > 0
                            source: shown === "wifi" ? "WifiPage.qml" : "BluetoothPage.qml"

                            Connections {
                                target: root
                                function onPageChanged() { if (root.page !== "main") sub.shown = root.page; }
                            }
                        }
                    }
                }
            }
        }
    }
}
