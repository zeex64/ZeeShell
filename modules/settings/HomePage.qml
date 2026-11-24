import Quickshell
import Quickshell.Widgets
import Quickshell.Bluetooth
import QtQuick
import qs.config
import qs.components
import qs.services

// The first page: this computer at a glance, and a way into every area with
// its current state on the tile.
Column {
    id: page

    signal go(string where)
    onGo: where => Ui.settingsPage = where

    readonly property var mon: Displays.monitors.find(m => m.focused) || Displays.monitors[0] || null
    readonly property var sys: Storage.volumes.find(v => v.mount === "/") || Storage.volumes[0] || null
    readonly property int btConnected: Bluetooth.devices.values.filter(d => d.connected).length

    spacing: 12
    Component.onCompleted: { Displays.refresh(); Storage.refresh(); }

    Card {
        width: parent.width
        height: 148

        ClippingRectangle {
            id: shot
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 206
            height: 116
            radius: Theme.radius.sm + 2
            color: Theme.layerHi

            Image {
                anchors.fill: parent
                source: Config.wallpaper.path !== "" ? "file://" + Config.wallpaper.path : ""
                sourceSize.width: 420
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Logo {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 10
                size: 28
            }
        }

        Column {
            anchors.left: shot.right
            anchors.leftMargin: 20
            anchors.right: rings.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Txt {
                width: parent.width
                text: Device.host !== "" ? Device.host : "This computer"
                size: 24
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Txt {
                width: parent.width
                visible: Device.model !== ""
                text: Device.model
                color: Theme.textDim
                elide: Text.ElideRight
            }

            Txt {
                width: parent.width
                text: Device.os + (Device.hyprland !== "" ? "  ·  " + Device.hyprland : "")
                size: 12
                color: Theme.textMute
                elide: Text.ElideRight
            }

            Item { width: 1; height: 6 }

            Row {
                spacing: 8
                Chip { icon: "user"; text: Device.user; onClicked: page.go("account") }
                Chip { icon: "clock-countdown"; text: "Up " + SysInfo.uptimeText(); onClicked: page.go("about") }
            }
        }

        Row {
            id: rings
            anchors.right: parent.right
            anchors.rightMargin: 22
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16

            Repeater {
                model: [
                    { label: "CPU", value: SysInfo.cpu / 100, text: SysInfo.cpu + "%" },
                    { label: "Memory", value: SysInfo.mem, text: Math.round(SysInfo.mem * 100) + "%" },
                    { label: "Disk", value: SysInfo.disk, text: Math.round(SysInfo.disk * 100) + "%" }
                ]

                Column {
                    id: gauge
                    required property var modelData
                    spacing: 6

                    Ring {
                        width: 58
                        height: 58
                        thickness: 5
                        value: gauge.modelData.value

                        Txt {
                            anchors.centerIn: parent
                            text: gauge.modelData.text
                            size: 12
                            font.weight: Font.Bold
                            font.features: { "tnum": 1 }
                        }
                    }

                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: gauge.modelData.label
                        size: 11
                        color: Theme.textMute
                    }
                }
            }
        }
    }

    Grid {
        id: grid

        readonly property real cell: (width - spacing * 2) / 3

        width: parent.width
        columns: 3
        spacing: 10

        HomeTile {
            width: grid.cell
            icon: "monitor"
            title: "Display"
            status: page.mon ? page.mon.width + " × " + page.mon.height + "  ·  " + Math.round(page.mon.refreshRate) + " Hz"
                + (Displays.monitors.length > 1 ? "  ·  " + Displays.monitors.length + " screens" : "") : "Screens and brightness"
            onClicked: page.go("display")
        }

        HomeTile {
            width: grid.cell
            icon: Audio.icon
            title: "Sound"
            status: Audio.sinkName + "  ·  " + (Audio.muted ? "muted" : Math.round(Audio.volume * 100) + "%")
            onClicked: page.go("sound")
        }

        HomeTile {
            width: grid.cell
            icon: Network.icon
            title: "Network"
            status: Network.label
            onClicked: page.go("network")
        }

        HomeTile {
            width: grid.cell
            icon: "bluetooth"
            title: "Bluetooth"
            status: !Bluetooth.defaultAdapter ? "No adapter" : !Bluetooth.defaultAdapter.enabled ? "Off"
                : page.btConnected > 0 ? page.btConnected + (page.btConnected === 1 ? " device connected" : " devices connected") : "On"
            onClicked: page.go("bluetooth")
        }

        HomeTile {
            width: grid.cell
            icon: "palette"
            title: "Personalisation"
            status: (Config.appearance.dark ? "Dark" : "Light") + (Config.appearance.dynamicColors ? "  ·  colours from wallpaper" : "  ·  your accent")
            onClicked: page.go("appearance")
        }

        HomeTile {
            width: grid.cell
            icon: "layout"
            title: "Bar & desktop"
            status: (Config.bar.position === "top" ? "Bar on top" : "Bar at the bottom") + "  ·  " + Config.widgets.items.length + (Config.widgets.items.length === 1 ? " widget" : " widgets")
            onClicked: page.go("bar")
        }

        HomeTile {
            width: grid.cell
            icon: "lightning"
            title: "Power"
            status: Power.hasBattery ? Power.batteryText : Power.profiles ? Power.profileName : "Sleep and screen"
            onClicked: page.go("power")
        }

        HomeTile {
            width: grid.cell
            icon: "hard-drives"
            title: "Storage"
            status: page.sys ? Storage.human(page.sys.free) + " free of " + Storage.human(page.sys.size) : "Disk space"
            onClicked: page.go("storage")
        }

        HomeTile {
            width: grid.cell
            icon: "keyboard"
            title: "Input & keybinds"
            status: String(Input.value("kb_layout", "")).toUpperCase() + (Hypr.binds.length ? "  ·  " + Hypr.binds.length + " keybinds" : "")
            onClicked: page.go("keyboard")
        }

        HomeTile {
            width: grid.cell
            icon: "squares-four"
            title: "Apps"
            status: DefaultApps.current.browser ? "Browser: " + DefaultApps.name(DefaultApps.current.browser) : "Defaults and startup"
            onClicked: page.go("defaults")
        }

        HomeTile {
            width: grid.cell
            icon: "clock"
            title: "Time & weather"
            status: DateTime.zone !== "" ? DateTime.zone.replace(/_/g, " ") : "Time zone and clock"
            onClicked: page.go("datetime")
        }

        HomeTile {
            width: grid.cell
            icon: Config.notifications.dnd ? "bell-slash" : "bell"
            title: "Notifications"
            status: Config.notifications.dnd ? "Do not disturb" : Notifs.count > 0 ? Notifs.count + " waiting" : "All caught up"
            onClicked: page.go("notifications")
        }

        HomeTile {
            width: grid.cell
            icon: "user-circle"
            title: "Account"
            status: Device.fullName !== "" ? Device.fullName : Device.user
            onClicked: page.go("account")
        }

        HomeTile {
            width: grid.cell
            icon: "arrows-clockwise"
            title: "Updates"
            highlight: Updates.checked && Updates.count > 0
            status: !Updates.supported ? "Not available here" : Updates.checking ? "Checking…" : !Updates.checked ? "Not checked yet"
                : Updates.count === 0 ? "Up to date" : Updates.count + (Updates.count === 1 ? " update ready" : " updates ready")
            onClicked: page.go("updates")
        }

        HomeTile {
            width: grid.cell
            icon: "info"
            title: "About"
            status: Device.os + (Device.kernel !== "" ? "  ·  " + Device.kernel : "")
            onClicked: page.go("about")
        }
    }
}
