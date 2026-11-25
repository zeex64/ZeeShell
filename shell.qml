//@ pragma Env QS_NO_RELOAD_POPUP=1

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import QtQuick
import qs.config
import qs.services
import qs.modules.background
import qs.modules.bar
import qs.modules.launcher
import qs.modules.power
import qs.modules.keybinds
import qs.modules.notifications
import qs.modules.osd
import qs.modules.sidebar
import qs.modules.wallpaper
import qs.modules.lock
import qs.modules.startup
import qs.modules.settings
import qs.modules.widgets
import qs.modules.clipboard
import qs.modules.overview
import qs.modules.polkit

ShellRoot {
    id: shell

    Variants {
        model: Quickshell.screens
        Background {}
    }

    Variants {
        model: Ui.barScreens
        Bar {}
    }

    ScreenCorners {}

    TrayMenu {}
    TrayPopup {}
    CalendarPopup {}
    MediaPopup {}
    Launcher {}
    ClipboardPanel {}
    Overview {}
    Switcher {}
    PolkitDialog { id: polkit }
    PowerMenu {}
    Keybinds {}
    Sidebar {}
    WallpaperPicker {}
    Settings {}
    WidgetEditor {}
    Popups {}
    Lock { id: lock }
    Splash {}
    Osd {}

    Component.onCompleted: {
        Apps.all.length; // warm the app list so the first launcher open is instant
        Keybinds.managed; // start the keybind service so edited binds are applied
        AppThemes.dry; // start the service that themes other apps
        HyprSystem.dry; // start the service that hands display and input settings to Hyprland
        Clipboard.dry; // start recording the clipboard (unless Hyprland already does)
        Calendar.active; // fetch calendar events
    }

    // ---- when the computer is left alone (Settings -> System -> Power) ----
    // Stay-awake and apps that inhibit idling (video players) hold these back.
    readonly property bool live: Config.ready && !Quickshell.env("ZEE_DRY")

    IdleMonitor {
        enabled: shell.live && Config.power.screenOffMin > 0
        timeout: Math.max(1, Config.power.screenOffMin) * 60
        respectInhibitors: true
        onIsIdleChanged: Power.screens(!isIdle)
    }

    IdleMonitor {
        enabled: shell.live && Config.power.lockMin > 0
        timeout: Math.max(1, Config.power.lockMin) * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle && !Ui.locked) { Ui.hide(); Ui.locked = true; }
    }

    IdleMonitor {
        enabled: shell.live && Config.power.suspendMin > 0
        timeout: Math.max(1, Config.power.suspendMin) * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) { Ui.hide(); Ui.locked = true; sleepSoon.restart(); }
    }

    // Give the lock screen a moment to cover everything before sleeping.
    Timer { id: sleepSoon; interval: 1500; onTriggered: Power.suspend() }

    // ---- apps started with the session (Settings -> Apps -> Startup apps) ----
    // Once per login, not once per shell start: the marker lasts as long as
    // the Hyprland session does.
    Process {
        id: startupGate
        command: ["sh", "-c", "m=\"${XDG_RUNTIME_DIR:-/tmp}/zeeshell-started-${HYPRLAND_INSTANCE_SIGNATURE:-session}\"; [ -e \"$m\" ] && exit 1; : > \"$m\""]
        onExited: code => { if (code === 0) startupDelay.restart(); }
    }

    Timer {
        id: startupDelay
        interval: 1200
        onTriggered: {
            for (const s of Config.apps.startup) {
                if (s.enabled === false) continue;
                if (s.id) {
                    const e = DesktopEntries.applications.values.find(a => a.id === s.id);
                    if (e) e.execute();
                } else if (s.cmd) {
                    Quickshell.execDetached(["sh", "-c", s.cmd]);
                }
            }
        }
    }

    onLiveChanged: if (live) startupGate.running = true

    // Hyprland: bind = SUPER, Space, global, zeeshell:launcher
    component Key: GlobalShortcut {
        appid: "zeeshell"
    }

    Key { name: "launcher"; description: "Toggle the app drawer"; onPressed: Ui.toggle("launcher") }
    Key { name: "commands"; description: "Open the app drawer on its / commands"; onPressed: { Ui.launcherSeed = "/"; Ui.show("launcher"); } }
    Key { name: "sidebar"; description: "Toggle quick settings"; onPressed: Ui.toggle("sidebar") }
    Key { name: "power"; description: "Toggle the power menu"; onPressed: Ui.toggle("power") }
    Key { name: "wallpaper"; description: "Toggle the wallpaper picker"; onPressed: Ui.toggle("wallpaper") }
    Key { name: "keybinds"; description: "Toggle the keybinding cheat sheet"; onPressed: Ui.toggle("keybinds") }
    Key { name: "settings"; description: "Toggle settings"; onPressed: Ui.settingsOpen ? Ui.settingsOpen = false : Ui.settings() }
    Key { name: "editWidgets"; description: "Arrange desktop widgets"; onPressed: Ui.editWidgets ? Ui.stopWidgetEdit() : Ui.startWidgetEdit() }
    Key { name: "steam"; description: "Show or hide the Steam workspace"; onPressed: Hypr.toggleSteam() }
    Key { name: "files"; description: "Open the file explorer"; onPressed: Quickshell.execDetached([Quickshell.shellPath("zeeshell"), "files"]) }
    Key { name: "clipboard"; description: "Toggle the clipboard history"; onPressed: Ui.toggle("clipboard") }
    Key { name: "overview"; description: "Toggle the window overview"; onPressed: Ui.toggle("overview") }
    Key { name: "switcher"; description: "Switch windows (hold Alt, press Tab)"; onPressed: { if (Ui.active !== "") Ui.hide(); Windows.step(1); } }
    Key { name: "switcherBack"; description: "Switch windows backwards"; onPressed: { if (Ui.active !== "") Ui.hide(); Windows.step(-1); } }
    // Bound to letting go of Alt. A release bind reaches us as "released".
    Key { name: "switcherCommit"; description: "Finish switching windows (bound to releasing Alt)"; onPressed: Windows.commit(); onReleased: Windows.commit() }
    Key { name: "lock"; description: "Lock the session"; onPressed: { Ui.hide(); Ui.locked = true; } }
    Key { name: "randomWallpaper"; description: "Switch to a random wallpaper"; onPressed: Wallpapers.random() }
    Key { name: "brightnessUp"; description: "Raise brightness"; onPressed: Brightness.set(Brightness.value + 0.05) }
    Key { name: "brightnessDown"; description: "Lower brightness"; onPressed: Brightness.set(Brightness.value - 0.05) }

    // qs -p <dir> ipc call zee <function> [args]
    IpcHandler {
        target: "zee"

        function toggle(name: string): void { Ui.toggle(name); }
        function show(name: string): void { Ui.show(name); }
        function hide(): void { Ui.hide(); }
        function commands(): void { Ui.launcherSeed = "/"; Ui.show("launcher"); }
        function showOn(name: string, output: string): void {
            for (const s of Quickshell.screens) if (s.name === output) { Ui.show(name, s); return; }
            Ui.show(name);
        }
        function settings(): void { Ui.settingsOpen ? Ui.settingsOpen = false : Ui.settings(); }
        function settingsPage(page: string, output: string): void {
            Ui.settings(page);
            for (const s of Quickshell.screens) if (s.name === output) Ui.screen = s;
        }
        function find(text: string): void { Ui.findSetting(text); }
        function lock(): void { Ui.hide(); Ui.locked = true; }
        function lockPreview(): void { Ui.toggle("lockpreview"); }
        function notifyTest(): void { Notifs.test(); }
        function editWidgets(): void { Ui.editWidgets ? Ui.stopWidgetEdit() : Ui.startWidgetEdit(); }
        function editWidgetsOn(output: string): void {
            for (const s of Quickshell.screens) if (s.name === output) { Ui.startWidgetEdit(s); return; }
            Ui.startWidgetEdit();
        }
        function wallpaper(path: string): void { Wallpapers.apply(path); }
        function randomWallpaper(): void { Wallpapers.random(); }
        function dark(): void { Config.appearance.dark = !Config.appearance.dark; }
        function steam(): void { Hypr.toggleSteam(); }
        function dnd(): void { Config.notifications.dnd = !Config.notifications.dnd; }
    }

    // Development helpers: qs -p <dir> ipc call zeedev <function>
    IpcHandler {
        target: "zeedev"

        function debug(): string {
            return JSON.stringify({ steam: [Hypr.steamShown, Hypr.steamRunning], cfg: Config.ready, w: [Weather.ready, Weather.loading, Weather.error, Weather.city !== ""], net: [Network.wifiEnabled, Network.wired, Network.ssid !== "", Network.strength], vol: Audio.volume, br: [Brightness.mode, Brightness.value], wall: Config.wallpaper.path, popups: Notifs.popups.length, all: Notifs.count, lua: Hypr.lua, apps: Apps.all.length, local: Wallpapers.local.length });
        }
        function polkit(): string { return JSON.stringify({ registered: polkit.registered, active: polkit.flow !== null }); }
        function windows(): string { Windows.refresh(); return JSON.stringify({ n: Windows.clients.length, switching: Windows.switching, shown: Windows.switcherShown, index: Windows.index, fetching: Windows.fetching, mons: Windows.monitors, first: Windows.clients[0] || null }); }
        function clipboard(): string { Clipboard.refresh(); return JSON.stringify({ ok: Clipboard.available, watcher: Clipboard.watcherFound, n: Clipboard.entries.length, first: Clipboard.entries.slice(0, 3) }); }
        function notifs(): string {
            return JSON.stringify(Notifs.all.map(e => ({ s: e.summary, popup: e.popup, timeout: e.timeout, hovered: e.hovered, critical: e.critical, raw: e.notification ? e.notification.expireTimeout : null })));
        }
        function osd(): void { Audio.changed(); }
        function pam(): void { lock.submit("zeeshell-pam-self-test"); }
        function pamState(): string { return (lock.busy ? "busy" : "idle") + " | " + lock.message; }
        function havenTab(): void { Ui.wallpaperTab = "haven"; }
        function tray(output: string): void {
            for (const s of Quickshell.screens) {
                if (s.name !== output) continue;
                const item = SystemTray.items.values.find(i => i.hasMenu);
                if (item) Ui.trayMenu(item.menu, s.width - 300, 0, s);
            }
        }
    }
}
