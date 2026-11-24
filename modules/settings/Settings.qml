import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// Settings window. Non-modal: the rest of the desktop stays usable so
// changes can be judged live. Drag the header to move it out of the way.
Overlay {
    id: ov

    open: Ui.settingsOpen
    layerName: "settings"
    modal: false
    onDismiss: Ui.settingsOpen = false

    Item {
        id: root

        readonly property Item panel: sheet
        property real dx: 0
        property real dy: 0
        property string page: Ui.settingsPage

        readonly property var pages: [
            { key: "appearance", label: "Appearance", icon: "palette" },
            { key: "bar", label: "Bar & layout", icon: "layout" },
            { key: "modules", label: "Modules", icon: "squares-four" },
            { key: "weather", label: "Weather", icon: "cloud-sun" },
            { key: "notifications", label: "Notifications", icon: "bell" },
            { key: "wallpaper", label: "Wallpaper", icon: "image" },
            { key: "widgets", label: "Widgets", icon: "cards" },
            { key: "lock", label: "Lock & startup", icon: "lock" },
            { key: "shortcuts", label: "Keybinds", icon: "keyboard" }
        ]
        readonly property int pageIndex: Math.max(0, pages.findIndex(p => p.key === page))
        readonly property var swatches: ["#8fb8ff", "#b9a5ff", "#ff9ecb", "#ff9a8f", "#ffc67a", "#e6d96a", "#9fe08a", "#74dcc0", "#7fd3f2", "#c7ccd6"]

        property real grabX: 0
        property real grabY: 0

        // Window dragging. Offsets are kept inside the screen so the panel
        // never ends up somewhere it cannot be grabbed again.
        function grab(p) { grabX = p.x - dx; grabY = p.y - dy; }
        function drag(p) {
            const mx = (width - sheet.width) / 2, my = (height - sheet.height) / 2;
            dx = Math.max(-mx, Math.min(mx, p.x - grabX));
            dy = Math.max(-my, Math.min(my, p.y - grabY));
        }

        onPageChanged: { Ui.settingsPage = page; swap.restart(); }

        Panel {
            id: sheet

            width: Math.min(root.width - 60, 980)
            height: Math.min(root.height - 80, 720)
            x: Math.max(0, Math.min(root.width - width, (root.width - width) / 2 + root.dx))
            y: Math.max(0, Math.min(root.height - height, (root.height - height) / 2 + root.dy + (1 - ov.progress) * 40))
            opacity: ov.progress
            scale: 0.95 + 0.05 * ov.progress

            // ---- sidebar ----
            Rectangle {
                id: nav
                x: 1
                y: 1
                width: 218
                height: parent.height - 2
                topLeftRadius: sheet.radius
                bottomLeftRadius: sheet.radius
                color: Theme.alpha(Theme.surfaceHi, 0.35)

                MouseArea {
                    width: parent.width
                    height: 70
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    preventStealing: true
                    onPressed: e => root.grab(mapToItem(root, e.x, e.y))
                    onPositionChanged: e => { if (pressed) root.drag(mapToItem(root, e.x, e.y)); }
                }

                Row {
                    x: 18
                    y: 20
                    spacing: 10

                    Logo { size: 30 }
                    Txt { anchors.verticalCenter: parent.verticalCenter; text: "Settings"; size: 18; font.weight: Font.Bold }
                }

                Rectangle {
                    x: 10
                    y: 76 + root.pageIndex * 44
                    width: parent.width - 20
                    height: 40
                    radius: Math.min(Theme.radius.full, 20)
                    color: Theme.accent

                    Behavior on y { Anim { ms: 380; curve: Theme.curve.springSoft } }
                }

                Column {
                    x: 10
                    y: 76
                    width: parent.width - 20
                    spacing: 4

                    Repeater {
                        model: root.pages

                        Item {
                            id: entry
                            required property var modelData
                            required property int index
                            readonly property bool current: root.pageIndex === index

                            width: parent.width
                            height: 40

                            Row {
                                x: 14
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: entry.modelData.icon
                                    fill: entry.current
                                    size: 18
                                    color: entry.current ? Theme.accentInk : Theme.textDim
                                    Behavior on color { CAnim {} }
                                }

                                Txt {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: entry.modelData.label
                                    font.weight: entry.current ? Font.DemiBold : Font.Medium
                                    color: entry.current ? Theme.accentInk : Theme.text
                                    Behavior on color { CAnim {} }
                                }
                            }

                            StateLayer {
                                radius: Math.min(Theme.radius.full, 20)
                                showHover: !entry.current
                                onClicked: root.page = entry.modelData.key
                            }
                        }
                    }
                }

                Txt {
                    x: 20
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 16
                    text: "ZeeShell 0.1  ·  Esc to close"
                    size: 11
                    color: Theme.textMute
                }
            }

            // The strip above the page moves the window too.
            MouseArea {
                x: nav.width
                width: parent.width - nav.width - 64
                height: 62
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                preventStealing: true
                onPressed: e => root.grab(mapToItem(root, e.x, e.y))
                onPositionChanged: e => { if (pressed) root.drag(mapToItem(root, e.x, e.y)); }
            }

            // ---- page ----
            Txt {
                x: nav.width + 28
                y: 24
                text: root.pages[root.pageIndex].label
                size: 20
                font.weight: Font.Bold
            }

            IconBtn {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                icon: "x"
                flat: false
                onClicked: ov.dismiss()
            }

            Scroll {
                id: scroll

                x: nav.width + 12
                y: 66
                width: parent.width - nav.width - 24
                height: parent.height - 78
                contentHeight: loader.item ? loader.item.implicitHeight + 20 : 0

                Loader {
                    id: loader
                    x: 12
                    width: scroll.width - 24
                    sourceComponent: ({ appearance: appearance, bar: bar, modules: modules, weather: weather, notifications: notifications, wallpaper: wallpaper, widgets: widgets, lock: lock, shortcuts: shortcuts })[root.page]
                    onLoaded: scroll.contentY = 0
                }
            }

            ParallelAnimation {
                id: swap
                Anim { target: loader; property: "opacity"; from: 0; to: 1; ms: 300 }
                Anim { target: loader; property: "y"; from: 18; to: 0; ms: 380; curve: Theme.curve.enter }
            }
        }

        // =============================== pages ===============================
        Component {
            id: appearance

            Column {
                spacing: 12

                Group {
                    title: "Colour"

                    ToggleOpt {
                        label: "Dark mode"
                        checked: Config.appearance.dark
                        onToggled: v => Config.appearance.dark = v
                    }

                    ToggleOpt {
                        label: "Colours from wallpaper"
                        hint: "Pick the accent from the current wallpaper"
                        checked: Config.appearance.dynamicColors
                        onToggled: v => Config.appearance.dynamicColors = v
                    }

                    Opt {
                        label: "Accent"
                        hint: Config.appearance.dynamicColors ? "Choosing one turns off wallpaper colours" : ""

                        Repeater {
                            model: root.swatches

                            Rectangle {
                                id: dot
                                required property string modelData
                                readonly property bool chosen: !Config.appearance.dynamicColors && Config.appearance.accent === modelData

                                anchors.verticalCenter: parent.verticalCenter
                                width: 26
                                height: 26
                                radius: 13
                                color: modelData
                                border.width: chosen ? 3 : 0
                                border.color: Theme.text
                                scale: pick.pressed ? 0.85 : pick.containsMouse ? 1.15 : 1

                                Behavior on scale { Anim { ms: 280; curve: Theme.curve.spring } }

                                MouseArea {
                                    id: pick
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { Config.appearance.accent = dot.modelData; Config.appearance.dynamicColors = false; }
                                }
                            }
                        }
                    }
                }

                Group {
                    title: "Surfaces"

                    SliderOpt {
                        label: "Corner rounding"
                        from: 0; to: 1.6; step: 0.05
                        value: Config.appearance.rounding
                        onMoved: v => Config.appearance.rounding = v
                    }

                    SliderOpt {
                        label: "Panel opacity"
                        from: 0.3; to: 1; step: 0.02
                        value: Config.appearance.opacity
                        onMoved: v => Config.appearance.opacity = v
                    }

                    ToggleOpt {
                        label: "Background blur"
                        hint: "Frosted glass behind panels"
                        checked: Config.appearance.blur
                        onToggled: v => Config.appearance.blur = v
                    }

                    ToggleOpt {
                        label: "Borders"
                        checked: Config.appearance.borders
                        onToggled: v => Config.appearance.borders = v
                    }

                    ToggleOpt {
                        label: "Shadows"
                        checked: Config.appearance.shadows
                        onToggled: v => Config.appearance.shadows = v
                    }

                    ToggleOpt {
                        label: "Rounded screen corners"
                        hint: "Softens the corners of every monitor; steps aside for fullscreen windows"
                        checked: Config.appearance.screenCorners
                        onToggled: v => Config.appearance.screenCorners = v
                    }

                    SliderOpt {
                        visible: Config.appearance.screenCorners
                        label: "Screen corner size"
                        from: 4; to: 48; step: 1; decimals: 0; suffix: " px"
                        value: Config.appearance.screenRadius
                        onMoved: v => Config.appearance.screenRadius = v
                    }
                }

                Group {
                    title: "Other apps"

                    ToggleOpt {
                        label: "Colour KDE apps to match"
                        hint: "Dolphin, Kate and other KDE apps follow the shell's colours, including wallpaper colours. Off puts your previous colour scheme back."
                        checked: Config.apps.kde
                        onToggled: v => Config.apps.kde = v
                    }

                    ToggleOpt {
                        label: "Colour kitty and foot to match"
                        hint: "Rewrites the terminal themes the installer hooked up; kitty updates at once, foot in new windows"
                        checked: Config.apps.terminal
                        onToggled: v => Config.apps.terminal = v
                    }

                    ToggleOpt {
                        label: "Keep a matching Vesktop theme"
                        hint: "Writes “ZeeShell” into Vesktop's themes; turn it on once in Vesktop → Settings → Themes"
                        checked: Config.apps.vesktop
                        onToggled: v => Config.apps.vesktop = v
                    }
                }

                Group {
                    title: "Windows"

                    ToggleOpt {
                        label: "Style app windows to match"
                        hint: "Sets Hyprland's rounding, gaps, border and shadow from this theme"
                        checked: Config.windows.enabled
                        onToggled: v => Config.windows.enabled = v
                    }

                    SliderOpt {
                        label: "Window rounding"
                        hint: "Also follows Corner rounding above"
                        from: 0; to: 28; step: 1; decimals: 0; suffix: " px"
                        value: Config.windows.rounding
                        onMoved: v => Config.windows.rounding = v
                    }

                    SliderOpt {
                        label: "Border"
                        from: 0; to: 6; step: 1; decimals: 0; suffix: " px"
                        value: Config.windows.borderSize
                        onMoved: v => Config.windows.borderSize = v
                    }

                    ToggleOpt {
                        label: "Accent-coloured border on the focused window"
                        checked: Config.windows.accentBorder
                        onToggled: v => Config.windows.accentBorder = v
                    }

                    SliderOpt {
                        label: "Gap between windows"
                        from: 0; to: 16; step: 1; decimals: 0; suffix: " px"
                        value: Config.windows.gapsIn * 2
                        onMoved: v => Config.windows.gapsIn = Math.round(v / 2)
                    }

                    SliderOpt {
                        label: "Gap to screen edge"
                        from: 0; to: 32; step: 1; decimals: 0; suffix: " px"
                        value: Config.windows.gapsOut
                        onMoved: v => Config.windows.gapsOut = v
                    }

                    ToggleOpt {
                        label: "Window shadows"
                        checked: Config.windows.shadows
                        onToggled: v => Config.windows.shadows = v
                    }
                }

                Group {
                    title: "Motion & type"

                    ChoiceOpt {
                        label: "Animation speed"
                        options: [[0.6, "Relaxed"], [1, "Normal"], [1.6, "Snappy"], [20, "Off"]]
                        current: Config.appearance.animSpeed
                        onPicked: k => Config.appearance.animSpeed = k
                    }

                    SliderOpt {
                        label: "Text size"
                        from: 0.85; to: 1.3; step: 0.05
                        value: Config.appearance.fontScale
                        onMoved: v => Config.appearance.fontScale = v
                    }

                    TextOpt {
                        label: "Font"
                        hint: "Any installed family"
                        value: Config.appearance.font
                        onEdited: v => { if (v.trim() !== "") Config.appearance.font = v.trim(); }
                    }
                }
            }
        }

        Component {
            id: bar

            Column {
                spacing: 12

                Group {
                    title: "Placement"

                    ChoiceOpt {
                        label: "Position"
                        options: [["top", "Top"], ["bottom", "Bottom"]]
                        current: Config.bar.position
                        onPicked: k => Config.bar.position = k
                    }

                    ChoiceOpt {
                        label: "Show on"
                        hint: "Which monitor gets the bar"
                        options: [["", "All monitors"]].concat(Quickshell.screens.map(s => [s.name, s.name]))
                        current: Quickshell.screens.some(s => s.name === Config.bar.monitor) ? Config.bar.monitor : ""
                        onPicked: k => Config.bar.monitor = k
                    }

                    ChoiceOpt {
                        label: "Style"
                        hint: "Islands group modules; pills separate each one; solid is one strip"
                        options: [["islands", "Islands"], ["pills", "Pills"], ["solid", "Solid"]]
                        current: Config.bar.style
                        onPicked: k => Config.bar.style = k
                    }

                    ToggleOpt {
                        label: "Floating"
                        hint: "Leave a gap between the bar and the screen edge"
                        checked: Config.bar.floating
                        onToggled: v => Config.bar.floating = v
                    }

                    SliderOpt {
                        label: "Height"
                        from: 32; to: 60; step: 1; decimals: 0; suffix: " px"
                        value: Config.bar.height
                        onMoved: v => Config.bar.height = v
                    }

                    SliderOpt {
                        visible: Config.bar.floating
                        label: "Edge gap"
                        from: 0; to: 24; step: 1; decimals: 0; suffix: " px"
                        value: Config.bar.margin
                        onMoved: v => Config.bar.margin = v
                    }
                }

                Group {
                    title: "Modules"
                    BarLayout { topPadding: 4; bottomPadding: 8 }
                }
            }
        }

        Component {
            id: modules

            Column {
                spacing: 12

                Group {
                    title: "Workspaces"

                    SliderOpt {
                        label: "Shown workspaces"
                        hint: "Occupied workspaces beyond this still appear"
                        from: 1; to: 10; step: 1; decimals: 0
                        value: Config.workspaces.count
                        onMoved: v => Config.workspaces.count = v
                    }

                    ChoiceOpt {
                        label: "Style"
                        options: [["dots", "Dots"], ["numbers", "Numbers"], ["apps", "App icons"]]
                        current: Config.workspaces.style
                        onPicked: k => Config.workspaces.style = k
                    }

                    ToggleOpt {
                        label: "Per-monitor highlight"
                        hint: "Each bar highlights the workspace on its own monitor"
                        checked: Config.workspaces.perMonitor
                        onToggled: v => Config.workspaces.perMonitor = v
                    }
                }

                Group {
                    title: "Clock"

                    ToggleOpt { label: "24-hour time"; checked: Config.clock.use24h; onToggled: v => Config.clock.use24h = v }
                    ToggleOpt { label: "Show seconds"; checked: Config.clock.showSeconds; onToggled: v => Config.clock.showSeconds = v }
                    ToggleOpt { label: "Show date in bar"; checked: Config.clock.showDate; onToggled: v => Config.clock.showDate = v }
                    ToggleOpt { label: "Show weather in the clock"; hint: "One pill for time and weather; clicking it opens the calendar"; checked: Config.clock.showWeather; onToggled: v => Config.clock.showWeather = v }
                }

                Group {
                    title: "Files"

                    ToggleOpt {
                        label: "Open folders with ZeeShell Files"
                        hint: "Makes the built-in explorer your default file manager. Off hands folders back to the one you had."
                        checked: Config.files.handleFolders
                        onToggled: v => { Config.files.handleFolders = v; Files.useAsDefault(v); }
                    }

                    ToggleOpt {
                        label: "Show hidden files"
                        checked: Config.files.showHidden
                        onToggled: v => Config.files.showHidden = v
                    }

                    Opt {
                        label: "Explorer"
                        hint: "Also on the start rail, in the app drawer, and as: zeeshell files"
                        Btn { text: "Open Files"; icon: "folder"; onClicked: Quickshell.execDetached([Quickshell.shellPath("zeeshell"), "files"]) }
                    }
                }

                Group {
                    title: "App tray"

                    ToggleOpt {
                        label: "Collapse behind an arrow"
                        hint: "Keeps tray icons out of the bar; click the arrow to see them"
                        checked: Config.tray.collapsed
                        onToggled: v => Config.tray.collapsed = v
                    }
                }

                Group {
                    title: "Steam workspace"

                    ToggleOpt {
                        label: "Keep Steam in its own workspace"
                        hint: "Steam's windows stay in a hidden workspace that Super + G drops over the desktop. Off returns Steam to normal windows."
                        checked: Config.steam.enabled
                        onToggled: v => Config.steam.enabled = v
                    }

                    ToggleOpt {
                        visible: Config.steam.enabled
                        label: "Start Steam at login"
                        checked: Config.steam.autostart
                        onToggled: v => Config.steam.autostart = v
                    }

                    SliderOpt {
                        visible: Config.steam.enabled
                        label: "Width on wide monitors"
                        from: 50; to: 100; step: 2; decimals: 0; suffix: "%"
                        value: Config.steam.fill * 100
                        onMoved: v => Config.steam.fill = v / 100
                    }

                    SliderOpt {
                        visible: Config.steam.enabled
                        label: "Friends List column"
                        from: 15; to: 50; step: 1; decimals: 0; suffix: "%"
                        value: Config.steam.friends * 100
                        onMoved: v => Config.steam.friends = v / 100
                    }
                }

                Group {
                    title: "App drawer"

                    ChoiceOpt {
                        label: "Position"
                        hint: "Centre of the screen, a panel down the left side, or a start menu at the bottom with an A–Z list and pinned apps"
                        options: [["center", "Centre"], ["side", "Side panel"], ["bottom-left", "Bottom left"], ["bottom-center", "Bottom centre"]]
                        current: Config.launcher.position
                        onPicked: k => Config.launcher.position = k
                    }

                    SliderOpt {
                        label: "Columns"
                        from: 4; to: 9; step: 1; decimals: 0
                        value: Config.launcher.columns
                        onMoved: v => Config.launcher.columns = v
                    }

                    ToggleOpt { label: "Category chips"; checked: Config.launcher.showCategories; onToggled: v => Config.launcher.showCategories = v }
                }

                Group {
                    title: "Quick settings"

                    ChoiceOpt {
                        label: "Side"
                        options: [["left", "Left"], ["right", "Right"]]
                        current: Config.sidebar.side
                        onPicked: k => Config.sidebar.side = k
                    }

                    SliderOpt {
                        label: "Width"
                        from: 360; to: 520; step: 10; decimals: 0; suffix: " px"
                        value: Config.sidebar.width
                        onMoved: v => Config.sidebar.width = v
                    }

                    SliderOpt {
                        label: "Night light warmth"
                        from: 2500; to: 6000; step: 100; decimals: 0; suffix: " K"
                        value: Config.sidebar.nightTemp
                        onMoved: v => Config.sidebar.nightTemp = v
                    }
                }
            }
        }

        Component {
            id: weather

            Column {
                id: page
                property var found: []
                spacing: 12

                Group {
                    title: "Now"
                    WeatherCard { width: parent.width; color: "transparent"; border.width: 0 }
                }

                Group {
                    title: "Location"

                    ToggleOpt {
                        label: "Detect automatically"
                        hint: "Looks up an approximate location from your public IP address (geojs.io)"
                        checked: Config.weather.autoLocate
                        onToggled: v => Config.weather.autoLocate = v
                    }

                    Opt {
                        label: "City"
                        hint: Config.weather.city !== "" && !Config.weather.autoLocate ? "Using " + Config.weather.city : "Search to pin a place"

                        Field {
                            id: city
                            width: 280
                            implicitHeight: 36
                            icon: "map-pin"
                            placeholder: "Search a city"
                            onAccepted: Weather.search(text, r => page.found = r)
                        }
                    }

                    Repeater {
                        model: page.found

                        Item {
                            id: hit
                            required property var modelData
                            width: parent.width
                            height: 42

                            Row {
                                x: 4
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                Icon { anchors.verticalCenter: parent.verticalCenter; name: "map-pin"; size: 16; color: Theme.accent }
                                Txt { anchors.verticalCenter: parent.verticalCenter; text: hit.modelData.name; font.weight: Font.DemiBold }
                                Txt { anchors.verticalCenter: parent.verticalCenter; text: hit.modelData.detail; color: Theme.textMute }
                            }

                            StateLayer {
                                radius: Theme.radius.sm
                                onClicked: { Weather.setCity(hit.modelData); page.found = []; city.text = ""; }
                            }
                        }
                    }
                }

                Group {
                    title: "Display"

                    ChoiceOpt {
                        label: "Units"
                        options: [[false, "Celsius"], [true, "Fahrenheit"]]
                        current: Config.weather.fahrenheit
                        onPicked: k => Config.weather.fahrenheit = k
                    }

                    SliderOpt {
                        label: "Refresh every"
                        from: 10; to: 120; step: 10; decimals: 0; suffix: " min"
                        value: Config.weather.refreshMinutes
                        onMoved: v => Config.weather.refreshMinutes = v
                    }
                }
            }
        }

        Component {
            id: notifications

            Column {
                spacing: 12

                Group {
                    title: "Popups"

                    ChoiceOpt {
                        label: "Show on"
                        hint: "A fixed monitor, or whichever one you are working on"
                        options: [["", "Focused monitor"]].concat(Quickshell.screens.map(s => [s.name, s.name]))
                        current: Quickshell.screens.some(s => s.name === Config.notifications.monitor) ? Config.notifications.monitor : ""
                        onPicked: k => Config.notifications.monitor = k
                    }

                    ChoiceOpt {
                        label: "Position"
                        options: [["top-left", "Top left"], ["top-center", "Top"], ["top-right", "Top right"], ["bottom-left", "Bottom left"], ["bottom-right", "Bottom right"]]
                        current: Config.notifications.position
                        onPicked: k => Config.notifications.position = k
                    }

                    SliderOpt {
                        label: "Stay on screen"
                        from: 2; to: 20; step: 1; decimals: 0; suffix: " s"
                        value: Config.notifications.timeout / 1000
                        onMoved: v => Config.notifications.timeout = v * 1000
                    }

                    SliderOpt {
                        label: "Maximum at once"
                        from: 1; to: 8; step: 1; decimals: 0
                        value: Config.notifications.maxPopups
                        onMoved: v => Config.notifications.maxPopups = v
                    }

                    ToggleOpt {
                        label: "Do not disturb"
                        hint: "Critical notifications still appear"
                        checked: Config.notifications.dnd
                        onToggled: v => Config.notifications.dnd = v
                    }

                    Opt {
                        label: "Preview"
                        Btn { text: "Send a test"; icon: "paper-plane-tilt"; onClicked: Notifs.test() }
                    }
                }

                Group {
                    title: "Volume & brightness indicator"

                    ToggleOpt { label: "Show indicator"; checked: Config.osd.enabled; onToggled: v => Config.osd.enabled = v }

                    ChoiceOpt {
                        label: "Position"
                        options: [["top", "Top"], ["bottom", "Bottom"]]
                        current: Config.osd.position
                        onPicked: k => Config.osd.position = k
                    }
                }
            }
        }

        Component {
            id: wallpaper

            Column {
                spacing: 12

                Group {
                    title: "Library"

                    TextOpt {
                        label: "Folder"
                        hint: "Leave empty for ~/Pictures/Wallpapers. Downloads land here too."
                        placeholder: Wallpapers.dir
                        value: Config.wallpaper.directory
                        onEdited: v => Config.wallpaper.directory = v.trim().replace(/^~/, Config.home).replace(/\/+$/, "")
                    }

                    Opt {
                        label: "Browse"
                        hint: Wallpapers.local.length + " images found"
                        Btn { text: "Random"; icon: "shuffle"; kind: "ghost"; onClicked: Wallpapers.random() }
                        Btn { text: "Open picker"; icon: "image"; onClicked: Ui.show("wallpaper") }
                    }
                }

                Group {
                    title: "Transition"

                    ChoiceOpt {
                        label: "Effect"
                        options: [["circle", "Iris"], ["wipe", "Wipe"], ["fade", "Fade"]]
                        current: Config.wallpaper.transition
                        onPicked: k => Config.wallpaper.transition = k
                    }

                    SliderOpt {
                        label: "Duration"
                        from: 200; to: 2500; step: 100; decimals: 0; suffix: " ms"
                        value: Config.wallpaper.transitionMs
                        onMoved: v => Config.wallpaper.transitionMs = v
                    }
                }

                Group {
                    title: "wallhaven.cc"

                    ToggleOpt {
                        label: "Only wallpapers that fit my largest screen"
                        checked: Config.wallpaper.havenMatchScreen
                        onToggled: v => Config.wallpaper.havenMatchScreen = v
                    }

                    ToggleOpt {
                        label: "Include “sketchy” results"
                        hint: "Off keeps results safe-for-work only"
                        checked: Config.wallpaper.havenSketchy
                        onToggled: v => Config.wallpaper.havenSketchy = v
                    }

                    TextOpt {
                        label: "API key"
                        hint: "Optional. Stored in plain text in config.json; sent only to wallhaven.cc"
                        secret: true
                        placeholder: "Not set"
                        value: Config.wallpaper.havenKey
                        onEdited: v => Config.wallpaper.havenKey = v.trim()
                    }
                }
            }
        }

        Component {
            id: widgets

            Column {
                spacing: 12

                Group {
                    title: "Desktop widgets"

                    ToggleOpt {
                        label: "Show widgets"
                        checked: Config.widgets.enabled
                        onToggled: v => Config.widgets.enabled = v
                    }

                    Opt {
                        label: "Arrange"
                        hint: "Opens the full-screen editor; Settings comes back when you are done"
                        Btn {
                            text: "Edit layout"
                            icon: "arrows-out-cardinal"
                            kind: "filled"
                            onClicked: Ui.startWidgetEdit(Ui.screen, true)
                        }
                    }
                }

                Group {
                    title: "Placed"

                    Txt {
                        visible: Config.widgets.items.length === 0
                        height: 40
                        verticalAlignment: Text.AlignVCenter
                        text: "No widgets yet. Use Edit layout to add some."
                        color: Theme.textMute
                    }

                    Repeater {
                        model: Config.widgets.items

                        Opt {
                            id: placed
                            required property var modelData
                            required property int index

                            label: modelData.type.charAt(0).toUpperCase() + modelData.type.slice(1)
                            hint: (modelData.screen || "All screens") + "  ·  " + Math.round(modelData.x * 100) + "% × " + Math.round(modelData.y * 100) + "%"

                            Choice {
                                options: [["", "All"]].concat(Quickshell.screens.map(s => [s.name, s.name]))
                                current: placed.modelData.screen || ""
                                onPicked: k => {
                                    const items = Config.widgets.items.map(w => Object.assign({}, w));
                                    if (k === "") delete items[placed.index].screen;
                                    else items[placed.index].screen = k;
                                    Config.widgets.items = items;
                                }
                            }

                            IconBtn {
                                icon: "trash"
                                flat: false
                                tint: Theme.danger
                                onClicked: Config.widgets.items = Config.widgets.items.filter((w, i) => i !== placed.index)
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: lock

            Column {
                spacing: 12

                Group {
                    title: "Lock screen"

                    ToggleOpt { label: "Blur the wallpaper"; checked: Config.lock.blurWallpaper; onToggled: v => Config.lock.blurWallpaper = v }
                    ToggleOpt { label: "Show weather"; checked: Config.lock.showWeather; onToggled: v => Config.lock.showWeather = v }
                    ToggleOpt { label: "Show media controls"; checked: Config.lock.showMedia; onToggled: v => Config.lock.showMedia = v }

                    Opt {
                        label: "Try it"
                        hint: "Preview shows the screen without locking the session"
                        Btn { text: "Preview"; icon: "eye"; kind: "ghost"; onClicked: Ui.show("lockpreview") }
                        Btn { text: "Lock now"; icon: "lock"; onClicked: { Ui.settingsOpen = false; Ui.locked = true; } }
                    }
                }

                Group {
                    title: "Startup"

                    ToggleOpt {
                        label: "Startup animation"
                        hint: "Plays when the shell launches"
                        checked: Config.startup.animation
                        onToggled: v => Config.startup.animation = v
                    }
                }
            }
        }

        Component {
            id: shortcuts

            KeybindsPage {}
        }
    }
}
