pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Persistent user configuration. Lives in ~/.config/zeeshell/config.json and
// is live-reloaded when edited by hand.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/zeeshell"
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || home + "/.cache") + "/zeeshell"
    property bool ready: false

    // Every bar module the layout editor can offer.
    readonly property var barModules: ({
        launcher: { label: "Launcher", icon: "squares-four" },
        workspaces: { label: "Workspaces", icon: "circles-three" },
        steam: { label: "Steam workspace", icon: "steam-logo" },
        window: { label: "Window title", icon: "app-window" },
        clock: { label: "Clock", icon: "clock" },
        weather: { label: "Weather", icon: "cloud-sun" },
        media: { label: "Media", icon: "music-notes" },
        sysinfo: { label: "System info", icon: "cpu" },
        tray: { label: "App tray", icon: "tray" },
        status: { label: "Status icons", icon: "wifi-high" },
        keybinds: { label: "Keybindings", icon: "keyboard" },
        wallpaper: { label: "Wallpaper", icon: "image" },
        settings: { label: "Settings", icon: "gear" },
        power: { label: "Power", icon: "power" }
    })

    readonly property var sections: ["appearance", "bar", "workspaces", "clock", "weather", "launcher", "notifications", "sidebar", "wallpaper", "widgets", "lock", "startup", "osd", "windows", "keybinds", "tray", "steam", "apps", "files", "display", "input", "power", "clipboard", "calendar"]
    property bool loading: false

    function keys(o) {
        const out = [];
        for (const k in o) {
            if (k === "objectName" || k.endsWith("Changed") || typeof o[k] === "function") continue;
            out.push(k);
        }
        return out;
    }

    function serialize() {
        const d = {};
        for (const s of sections) {
            d[s] = {};
            for (const k of keys(root[s])) d[s][k] = root[s][k];
        }
        return JSON.stringify(d, null, 2);
    }

    // Copy values from disk onto the live objects, ignoring anything unknown
    // or of the wrong type so a hand-edited file can never break the shell.
    function apply(raw) {
        let d;
        try { d = JSON.parse(raw); } catch (e) { console.warn("zeeshell: config.json is not valid JSON, keeping current settings"); return; }
        loading = true;
        for (const s of sections) {
            if (!d[s] || typeof d[s] !== "object") continue;
            for (const k of keys(root[s])) {
                const v = d[s][k], cur = root[s][k];
                if (v === undefined || v === null || typeof v !== typeof cur || Array.isArray(v) !== Array.isArray(cur)) continue;
                if (typeof v === "object" ? JSON.stringify(v) !== JSON.stringify(cur) : v !== cur) root[s][k] = v;
            }
        }
        loading = false;
    }

    // ZEE_DRY=1 is for throwaway test instances: they must never write the real config.
    function save() { if (!loading && ready && !Quickshell.env("ZEE_DRY")) saveTimer.restart(); }

    Component.onCompleted: {
        for (const s of sections)
            for (const k of keys(root[s])) root[s][k + "Changed"].connect(root.save);
    }

    Process {
        command: ["mkdir", "-p", root.dir, root.cacheDir, root.cacheDir + "/wallhaven"]
        running: true
        onExited: file.path = root.dir + "/config.json"
    }

    Timer {
        id: saveTimer
        interval: 350
        onTriggered: file.setText(root.serialize())
    }

    FileView {
        id: file

        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            root.apply(text());
            root.ready = true;
        }
        onLoadFailed: err => {
            root.ready = true;
            if (err === FileViewError.FileNotFound) setText(root.serialize());
        }
    }

    readonly property QtObject appearance: QtObject {
        property bool dark: true
        property bool dynamicColors: true
        property string accent: "#8fb8ff"
        property real rounding: 1.0
        property real opacity: 0.72
        property bool blur: true
        property bool borders: true
        property bool shadows: true
        property bool screenCorners: false // round off each monitor's corners
        property int screenRadius: 18
        property real animSpeed: 1.0
        property string font: "Adwaita Sans"
        property string monoFont: "JetBrainsMono Nerd Font"
        property real fontScale: 1.0
    }

    readonly property QtObject bar: QtObject {
        property string position: "top" // top | bottom
        property string monitor: "" // monitor name, or "" for every monitor
        property string style: "islands" // islands | pills | solid
        property bool floating: true
        property int height: 42
        property int margin: 8
        property var left: ["launcher", "workspaces", "window"]
        property var center: ["clock"]
        property var right: ["media", "sysinfo", "tray", "status", "power"]
    }

    readonly property QtObject workspaces: QtObject {
        property int count: 6
        property string style: "dots" // dots | numbers | apps
        property bool perMonitor: false
    }

    readonly property QtObject clock: QtObject {
        property bool use24h: true
        property bool showSeconds: false
        property bool showDate: true
        property bool showWeather: true // weather inside the clock pill
    }

    readonly property QtObject weather: QtObject {
        property bool autoLocate: true
        property string city: ""
        property real latitude: 0
        property real longitude: 0
        property bool fahrenheit: false
        property int refreshMinutes: 20
    }

    readonly property QtObject launcher: QtObject {
        property int columns: 6
        property bool showCategories: true
        property string position: "center" // center | side | bottom-left | bottom-center
        property var pinned: [] // desktop entry ids shown as tiles in the start layout
    }

    readonly property QtObject notifications: QtObject {
        property string position: "top-right" // top-right | top-left | bottom-right | bottom-left | top-center
        property string monitor: "" // monitor name, or "" for the focused monitor
        property int timeout: 6000
        property bool dnd: false
        property int maxPopups: 4
        property bool group: true // stack the history by app in quick settings
        property var rules: ({}) // app name -> "mute" (never shown) | "quiet" (history only) | "keep" (stays until dismissed)
        property var apps: [] // every app that has sent a notification, for the rules list in Settings
    }

    readonly property QtObject sidebar: QtObject {
        property string side: "right" // right | left
        property int width: 420
        property int nightTemp: 4200
    }

    readonly property QtObject wallpaper: QtObject {
        property string path: ""
        property string directory: ""
        property string transition: "circle" // circle | fade | wipe
        property int transitionMs: 900
        property string havenKey: ""
        property string havenSorting: "toplist"
        property string havenRange: "1M"
        property string havenCategories: "111"
        property bool havenSketchy: false
        property bool havenMatchScreen: true
    }

    readonly property QtObject widgets: QtObject {
        property bool enabled: true
        property bool snap: true
        property bool showGrid: true
        property int grid: 40
        // x / y are fractions of the screen, measured to the widget centre.
        property var items: [
            { id: "w1", type: "clock", x: 0.5, y: 0.2 },
            { id: "w2", type: "weather", x: 0.12, y: 0.22 },
            { id: "w3", type: "system", x: 0.12, y: 0.52 }
        ]
    }

    readonly property QtObject lock: QtObject {
        property bool blurWallpaper: true
        property bool showMedia: true
        property bool showWeather: true
    }

    readonly property QtObject startup: QtObject {
        property bool animation: true
    }

    readonly property QtObject osd: QtObject {
        property bool enabled: true
        property string position: "bottom" // bottom | top
    }

    // The file explorer (files.qml). Shared by all of its windows.
    readonly property QtObject files: QtObject {
        property string view: "grid" // grid | list
        property int iconSize: 72
        property bool showHidden: false
        property string sortBy: "name" // name | size | modified | type
        property bool sortReversed: false
        property var bookmarks: [] // favourites pinned to the sidebar
        property var servers: [] // network locations: { label, uri }
        property bool handleFolders: false // be the system's default file manager
    }

    // Other apps themed to match. See services/AppThemes.qml.
    readonly property QtObject apps: QtObject {
        property bool kde: true // KDE colour scheme (Dolphin, Kate, ...)
        property string kdePrevious: "" // the scheme to go back to when that is turned off
        property bool vesktop: true // write a theme file into Vesktop's themes folder
        property bool vesktopGlass: true // a see-through window, when Vesktop's own transparency is on
        property bool terminal: true // keep kitty and foot themes in step
        property bool steam: true // keep a Steam theme (for Millennium) in step
        property var startup: [] // apps the shell starts with the session: { id, name, cmd, enabled }
    }

    // Monitor layout chosen in Settings -> System -> Display. Only monitors changed there
    // are listed; the rest keep what the Hyprland config says.
    // name -> { mode, x, y, scale, transform, vrr, disabled }
    readonly property QtObject display: QtObject {
        property var monitors: ({})
    }

    // Keyboard, mouse and touchpad options changed in Settings -> Input, by
    // Hyprland's own option name ("kb_layout", "touchpad:natural_scroll").
    readonly property QtObject input: QtObject {
        property var overrides: ({})
    }

    // What happens when the computer is left alone. 0 means never.
    readonly property QtObject power: QtObject {
        property int screenOffMin: 0
        property int lockMin: 0
        property int suspendMin: 0
    }

    // Clipboard history (cliphist). Pinned entries are kept as text in here.
    readonly property QtObject clipboard: QtObject {
        property bool enabled: true
        property var pinned: []
    }

    // Calendars shown under the clock: public or secret .ics links.
    readonly property QtObject calendar: QtObject {
        property var feeds: [] // { url, name, enabled }
        property int refreshMinutes: 30
    }

    readonly property QtObject tray: QtObject {
        property bool collapsed: false // hide the icons behind one arrow
    }

    // The Steam special workspace. Read by Hyprland's lua/steam.lua through a
    // small generated flags file (see services/Hypr.qml).
    readonly property QtObject steam: QtObject {
        property bool enabled: false
        property bool autostart: true
        property real fill: 0.88 // share of a wide monitor's width
        property real friends: 0.25 // share the Friends List column gets
    }

    // Binds made or changed in Settings -> Input -> Keybinds. See services/Keybinds.qml.
    readonly property QtObject keybinds: QtObject {
        property var items: []
    }

    // Hyprland window decoration, pushed to the compositor by services/Hypr.qml.
    readonly property QtObject windows: QtObject {
        property bool enabled: true
        property int rounding: 14 // scaled by appearance.rounding
        property int borderSize: 2
        property bool accentBorder: true
        property int gapsIn: 4
        property int gapsOut: 8
        property bool shadows: true
    }
}
