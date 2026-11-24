.pragma library

// The map of Settings: the areas in the sidebar, the pages inside each, and
// the words search looks through.

var categories = [
    { key: "home", label: "Home", icon: "house", pages: ["home"] },
    { key: "system", label: "System", icon: "desktop", pages: ["display", "sound", "notifications", "power", "storage", "about"] },
    { key: "connections", label: "Network & devices", icon: "wifi-high", pages: ["network", "bluetooth"] },
    { key: "personal", label: "Personalisation", icon: "palette", pages: ["appearance", "wallpaper", "lock"] },
    { key: "desktop", label: "Bar & desktop", icon: "layout", pages: ["bar", "modules", "widgets"] },
    { key: "input", label: "Input", icon: "keyboard", pages: ["keyboard", "mouse", "shortcuts"] },
    { key: "apps", label: "Apps", icon: "squares-four", pages: ["defaults", "startup", "builtin"] },
    { key: "time", label: "Time & weather", icon: "clock", pages: ["datetime", "weather"] },
    { key: "account", label: "Account", icon: "user-circle", pages: ["account"] },
    { key: "updates", label: "Updates", icon: "arrows-clockwise", pages: ["updates"] }
];

var pages = {
    home: { label: "Home", icon: "house", file: "HomePage" },
    display: { label: "Display", icon: "monitor", file: "DisplayPage" },
    sound: { label: "Sound", icon: "speaker-high", file: "SoundPage" },
    notifications: { label: "Notifications", icon: "bell", file: "NotificationsPage" },
    power: { label: "Power", icon: "lightning", file: "PowerPage" },
    storage: { label: "Storage", icon: "hard-drives", file: "StoragePage" },
    about: { label: "About", icon: "info", file: "AboutPage" },
    network: { label: "Network", icon: "wifi-high", file: "NetworkPage" },
    bluetooth: { label: "Bluetooth", icon: "bluetooth", file: "BtPage" },
    appearance: { label: "Appearance", icon: "palette", file: "AppearancePage" },
    wallpaper: { label: "Wallpaper", icon: "image", file: "WallpaperPage" },
    lock: { label: "Lock & startup", icon: "lock", file: "LockPage" },
    bar: { label: "Bar", icon: "layout", file: "BarPage" },
    modules: { label: "Modules", icon: "squares-four", file: "ModulesPage" },
    widgets: { label: "Widgets", icon: "cards", file: "WidgetsPage" },
    keyboard: { label: "Keyboard", icon: "keyboard", file: "KeyboardPage" },
    mouse: { label: "Mouse & touchpad", icon: "mouse", file: "MousePage" },
    shortcuts: { label: "Keybinds", icon: "command", file: "KeybindsPage" },
    defaults: { label: "Default apps", icon: "squares-four", file: "DefaultAppsPage" },
    startup: { label: "Startup apps", icon: "rocket-launch", file: "StartupPage" },
    builtin: { label: "Files & Steam", icon: "folder", file: "BuiltinAppsPage" },
    datetime: { label: "Date & time", icon: "clock", file: "DateTimePage" },
    weather: { label: "Weather", icon: "cloud-sun", file: "WeatherPage" },
    account: { label: "Account", icon: "user-circle", file: "AccountPage" },
    updates: { label: "Updates", icon: "arrows-clockwise", file: "UpdatesPage" }
};

// [page, what the setting is called, extra words people might type]
var entries = [
    ["display", "Resolution", "screen size monitor mode"],
    ["display", "Refresh rate", "hz hertz monitor"],
    ["display", "Scale", "zoom dpi bigger text hidpi"],
    ["display", "Orientation", "rotate rotation portrait landscape"],
    ["display", "Arrange screens", "monitors position layout multiple second"],
    ["display", "Variable refresh rate", "vrr freesync gsync adaptive sync"],
    ["display", "Brightness", "backlight dim"],
    ["display", "Night light", "blue light warm gammastep redshift"],
    ["sound", "Output device", "speakers headphones audio volume"],
    ["sound", "Input device", "microphone mic audio"],
    ["sound", "App volume", "mixer per app stream"],
    ["sound", "Volume indicator", "osd popup"],
    ["notifications", "Notification position", "popups corner"],
    ["notifications", "Do not disturb", "dnd silence quiet"],
    ["notifications", "Notification monitor", "screen popups"],
    ["notifications", "Notification timeout", "stay on screen duration"],
    ["power", "Power mode", "performance balanced power saver profile battery"],
    ["power", "Turn screens off", "idle dpms timeout blank"],
    ["power", "Lock after", "idle automatic lock timeout"],
    ["power", "Sleep after", "suspend idle"],
    ["power", "Stay awake", "caffeine inhibit idle"],
    ["power", "Battery", "charge health"],
    ["storage", "Drives", "disk space free partitions"],
    ["storage", "Home folder size", "what takes space usage du"],
    ["storage", "Empty trash", "bin delete clean"],
    ["about", "Device name", "hostname rename computer"],
    ["about", "System details", "specs cpu gpu memory kernel version"],
    ["network", "Wi-Fi", "wireless wifi internet connect"],
    ["network", "IP address", "connection details router dns gateway ethernet wired"],
    ["network", "VPN", "wireguard tunnel"],
    ["bluetooth", "Bluetooth", "pair devices headphones controller"],
    ["appearance", "Dark mode", "light theme"],
    ["appearance", "Accent colour", "color theme wallpaper colours"],
    ["appearance", "Corner rounding", "radius round"],
    ["appearance", "Panel opacity", "transparency blur glass"],
    ["appearance", "Rounded screen corners", "monitor corners"],
    ["appearance", "Window style", "borders gaps rounding shadows hyprland"],
    ["appearance", "Animation speed", "motion animations off"],
    ["appearance", "Text size", "font scale bigger"],
    ["appearance", "Font", "typeface"],
    ["appearance", "Other apps", "kde dolphin kitty foot vesktop theme"],
    ["wallpaper", "Wallpaper folder", "background pictures library"],
    ["wallpaper", "Wallpaper transition", "effect fade wipe"],
    ["wallpaper", "wallhaven", "download online api key"],
    ["lock", "Lock screen", "blur weather media preview"],
    ["lock", "Startup animation", "boot splash"],
    ["bar", "Bar position", "top bottom panel taskbar"],
    ["bar", "Bar monitor", "screen which"],
    ["bar", "Bar style", "islands pills solid floating"],
    ["bar", "Bar modules", "reorder layout items"],
    ["modules", "Workspaces", "dots numbers app icons count"],
    ["modules", "App tray", "system tray collapse arrow"],
    ["modules", "App drawer", "launcher start menu position columns"],
    ["modules", "Quick settings", "sidebar side width"],
    ["widgets", "Desktop widgets", "clock weather system media calendar arrange layout"],
    ["keyboard", "Keyboard layout", "language keys us de variant"],
    ["keyboard", "Repeat speed", "key repeat rate delay"],
    ["keyboard", "Num Lock", "numlock"],
    ["keyboard", "Keyboard options", "caps lock escape xkb switch layout"],
    ["mouse", "Pointer speed", "mouse sensitivity cursor"],
    ["mouse", "Acceleration", "accel flat adaptive"],
    ["mouse", "Natural scrolling", "reverse scroll direction"],
    ["mouse", "Left-handed", "swap buttons"],
    ["mouse", "Touchpad", "tap to click trackpad"],
    ["mouse", "Scroll speed", "wheel"],
    ["mouse", "Focus follows mouse", "pointer window focus"],
    ["shortcuts", "Keybinds", "shortcuts hotkeys keys rebind editor"],
    ["defaults", "Default browser", "web links"],
    ["defaults", "Default file manager", "folders explorer"],
    ["defaults", "Default apps", "open with image viewer video music pdf text editor email"],
    ["startup", "Startup apps", "autostart login launch"],
    ["builtin", "File explorer", "files hidden default folders"],
    ["builtin", "Steam workspace", "games special"],
    ["datetime", "Time zone", "timezone region"],
    ["datetime", "Set time automatically", "ntp sync clock"],
    ["datetime", "24-hour time", "clock format am pm seconds date"],
    ["datetime", "Language", "locale region formats"],
    ["weather", "Weather location", "city forecast"],
    ["weather", "Temperature units", "celsius fahrenheit"],
    ["account", "Account picture", "avatar photo face"],
    ["account", "Password", "change passwd sign in"],
    ["updates", "Updates", "upgrade packages pacman aur flatpak"]
];

function categoryOf(page) {
    for (var i = 0; i < categories.length; i++)
        if (categories[i].pages.indexOf(page) >= 0) return categories[i];
    return categories[0];
}

// Every word typed must be found; settings whose name starts with it come first.
function search(text) {
    var words = text.toLowerCase().split(/\s+/).filter(function (w) { return w !== ""; });
    if (!words.length) return [];
    var out = [], key;
    function add(page, title, extra, base) {
        var info = pages[page], cat = categoryOf(page);
        var hay = (title + " " + extra + " " + info.label + " " + cat.label).toLowerCase(), name = title.toLowerCase(), score = base;
        for (var i = 0; i < words.length; i++) {
            if (hay.indexOf(words[i]) < 0) return;
            if (name.indexOf(words[i]) === 0) score += 6;
            else if (name.indexOf(words[i]) > 0) score += 3;
        }
        out.push({ page: page, title: title, where: cat.label === info.label ? cat.label : cat.label + "  ›  " + info.label, icon: info.icon, score: score });
    }
    for (key in pages) if (key !== "home") add(key, pages[key].label, "", 2);
    for (var j = 0; j < entries.length; j++) {
        if (entries[j][1] === pages[entries[j][0]].label) continue;
        add(entries[j][0], entries[j][1], entries[j][2], 0);
    }
    out.sort(function (a, b) { return b.score - a.score; });
    return out.slice(0, 14);
}
