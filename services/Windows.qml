pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.config

// Open windows, read from `hyprctl clients -j` when the overview or the
// window switcher opens, plus the Alt-Tab state.
Singleton {
    id: root

    property var clients: [] // mapped windows on normal workspaces
    property var monitors: [] // { id, name, x, y, width, height } in layout pixels
    property bool loaded: false
    property var waiting: [] // callbacks for the refresh in flight
    property bool fetching: false

    function norm(addr) { return String(addr || "").replace(/^0x/, ""); }

    function refresh(done) {
        if (done) waiting = waiting.concat([done]);
        if (fetching) return;
        fetching = true;
        proc.running = true;
    }

    // The Wayland handle a ScreencopyView can capture.
    function toplevel(addr) {
        const a = norm(addr);
        for (const t of Hyprland.toplevels.values) if (norm(t.address) === a) return t.wayland;
        return null;
    }

    function monitor(id) {
        for (const m of monitors) if (m.id === id) return m;
        return monitors.length ? monitors[0] : null;
    }

    function focus(c) {
        if (!c) return;
        Hyprland.dispatch(Hypr.lua ? "hl.dsp.focus({ window = \"address:" + c.address + "\" })" : "focuswindow address:" + c.address);
    }

    // Ask that one window to close, through its own toplevel handle.
    function close(c) {
        const t = c ? toplevel(c.address) : null;
        if (t) t.close();
    }

    // Move a window to another workspace without following it there.
    function moveTo(c, ws) {
        if (!c || c.workspace === ws) return;
        Quickshell.execDetached(Hypr.lua
            ? ["hyprctl", "eval", "hl.dispatch(hl.dsp.window.move({ workspace = " + ws + ", follow = false, window = \"address:" + c.address + "\" }))"]
            : ["hyprctl", "dispatch", "movetoworkspacesilent", ws + ",address:" + c.address]);
    }

    Process {
        id: proc
        command: ["sh", "-c", "hyprctl clients -j; echo '---split---'; hyprctl monitors -j"]
        onExited: if (root.fetching) { root.fetching = false; const w = root.waiting; root.waiting = []; for (const f of w) f(); }
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("---split---");
                try {
                    root.monitors = JSON.parse(parts[1]).map(m => {
                        const turned = m.transform % 2 === 1, s = m.scale || 1;
                        return { id: m.id, name: m.name, x: m.x, y: m.y, width: (turned ? m.height : m.width) / s, height: (turned ? m.width : m.height) / s };
                    });
                    root.clients = JSON.parse(parts[0])
                        .filter(c => c.mapped && !c.hidden && c.workspace && c.workspace.id > 0)
                        .map(c => ({
                            address: c.address, cls: c.class || c.initialClass || "", title: c.title || c.class || "",
                            workspace: c.workspace.id, monitor: c.monitor, x: c.at[0], y: c.at[1], w: c.size[0], h: c.size[1],
                            floating: c.floating, fullscreen: c.fullscreen > 0, history: c.focusHistoryID
                        }))
                        .sort((a, b) => a.history - b.history);
                    root.loaded = true;
                } catch (e) {
                    console.warn("zeeshell: could not read the window list:", e);
                }
                const w = root.waiting;
                root.waiting = [];
                root.fetching = false;
                for (const f of w) f();
            }
        }
    }

    // ---- Alt-Tab -----------------------------------------------------------
    // ALT + Tab opens the switcher on the previous window; more presses move
    // along, letting go of Alt switches. A quick tap never shows the panel.
    property bool switching: false
    property bool switcherShown: false
    property int index: 0
    property bool commitWhenLoaded: false

    function step(dir) {
        if (!switching) {
            switching = true;
            switcherShown = false;
            commitWhenLoaded = false;
            index = dir > 0 ? 1 : -1;
            refresh(() => {
                const n = clients.length;
                if (n === 0) { cancel(); return; }
                index = ((index % n) + n) % n;
                if (commitWhenLoaded) commit();
            });
            showDelay.restart();
            return;
        }
        const n = Math.max(1, clients.length);
        index = (((index + dir) % n) + n) % n;
        switcherShown = true;
    }

    function commit() {
        if (!switching) return;
        if (fetching) { commitWhenLoaded = true; return; }
        const c = clients[index];
        switching = false;
        showDelay.stop();
        // Hyprland ignores a focus change while the panel still holds the
        // keyboard, so a shown panel closes first and the focus follows.
        if (switcherShown) {
            afterClose = c;
            switcherShown = false;
        } else {
            focus(c);
        }
    }

    property var afterClose: null
    // Called when the panel's window is destroyed; the compositor needs a
    // moment more before it hands focus back.
    function panelGone() { if (afterClose) focusSoon.restart(); }

    Timer {
        id: focusSoon
        interval: 60
        onTriggered: {
            const c = root.afterClose;
            root.afterClose = null;
            if (c) root.focus(c);
        }
    }

    function cancel() {
        switching = false;
        switcherShown = false;
        showDelay.stop();
    }

    Timer {
        id: showDelay
        interval: 140
        onTriggered: if (root.switching) root.switcherShown = true
    }
}
