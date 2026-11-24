pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.config

// Which surfaces are showing, and on which screen.
Singleton {
    id: root

    property string active: "" // launcher | sidebar | power | wallpaper | keybinds | traymenu
    property bool settingsOpen: false
    property string settingsPage: "home"
    property string settingsQuery: "" // text for the search field in Settings; cleared once used
    property string wallpaperTab: "local" // local | haven
    property string launcherSeed: "" // text the app drawer starts with, e.g. "/" for commands
    property bool locked: false
    property bool editWidgets: false
    property bool editReturn: false // reopen Settings when the widget editor closes
    property bool booted: false
    property var screen: Quickshell.screens[0]

    // Context for the tray menu overlay.
    property var menuHandle: null
    property real menuX: 0
    property real menuY: 0

    // The bar can be limited to one monitor (Config.bar.monitor). If that
    // monitor is unplugged the bar falls back to every screen.
    readonly property var barScreens: {
        const want = Config.bar.monitor, all = Quickshell.screens;
        if (want === "") return all;
        const hit = [];
        for (const s of all) if (s.name === want) hit.push(s);
        return hit.length ? hit : all;
    }

    function barOn(onScreen) {
        if (!onScreen) return true;
        for (const s of barScreens) if (s.name === onScreen.name) return true;
        return false;
    }

    function focusedScreen() {
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        for (const s of Quickshell.screens) if (s.name === name) return s;
        return Quickshell.screens[0];
    }

    // Full-screen widget layout editor. It replaces whatever else is open.
    function startWidgetEdit(onScreen, fromSettings) {
        editReturn = !!fromSettings && settingsOpen;
        active = "";
        settingsOpen = false;
        screen = onScreen || focusedScreen();
        editWidgets = true;
    }

    function stopWidgetEdit() {
        editWidgets = false;
        if (!editReturn) return;
        editReturn = false;
        settingsPage = "widgets";
        settingsOpen = true;
    }

    function show(name, onScreen) {
        if (editWidgets) { editReturn = false; editWidgets = false; }
        screen = onScreen || focusedScreen();
        active = name;
    }
    function hide() { active = ""; }
    function toggle(name, onScreen) { active === name ? hide() : show(name, onScreen); }

    // Open Settings with its search already filled in.
    function findSetting(text) {
        settings();
        settingsQuery = text;
    }

    function settings(page) {
        if (page) settingsPage = page;
        if (active !== "") active = "";
        screen = focusedScreen();
        settingsOpen = true;
    }

    // A small popup anchored under a bar button (calendar, collapsed tray).
    function popup(name, x, onScreen) {
        if (active === name) { hide(); return; }
        menuX = x;
        show(name, onScreen);
    }

    function trayMenu(handle, x, y, onScreen) {
        menuHandle = handle;
        menuX = x;
        menuY = y;
        show("traymenu", onScreen);
    }
}
