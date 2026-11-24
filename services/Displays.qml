pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.config

// The monitors Hyprland knows about, and trying out a new layout safely: a
// change is applied first and only saved once the user confirms they can
// still see the screen.
Singleton {
    id: root

    property var monitors: [] // as hyprctl reports them, disabled ones included
    property var pending: null // { rules, before } while waiting for "keep"
    property int secondsLeft: 0
    readonly property bool managed: Object.keys(Config.display.monitors).length > 0

    function refresh() { proc.running = true; }

    // "5120x2160@165.06Hz" -> { key: "5120x2160@165.06", w, h, rate }
    function parseMode(text) {
        const m = /^(\d+)x(\d+)@([\d.]+)/.exec(text);
        return m ? { key: m[1] + "x" + m[2] + "@" + m[3], w: parseInt(m[1]), h: parseInt(m[2]), rate: parseFloat(m[3]) } : null;
    }
    function modes(mon) {
        const seen = {}, out = [];
        for (const t of mon.availableModes || []) {
            const m = parseMode(t);
            if (!m || seen[m.key]) continue;
            seen[m.key] = true;
            out.push(m);
        }
        return out.sort((a, b) => (b.w * b.h - a.w * a.h) || (b.rate - a.rate));
    }
    function currentMode(mon) {
        let best = null;
        for (const m of modes(mon)) {
            if (m.w !== mon.width || m.h !== mon.height) continue;
            if (!best || Math.abs(m.rate - mon.refreshRate) < Math.abs(best.rate - mon.refreshRate)) best = m;
        }
        return best ? best.key : mon.width + "x" + mon.height + "@" + mon.refreshRate.toFixed(2);
    }

    // The scales Hyprland accepts cleanly: both sides must stay whole pixels.
    function scales(w, h) {
        const out = [];
        for (const s of [1, 1.2, 1.25, 1.333333, 1.5, 1.6, 1.666667, 1.75, 2, 2.4, 2.5, 3]) {
            const a = w / s, b = h / s;
            if (Math.abs(a - Math.round(a)) < 0.01 && Math.abs(b - Math.round(b)) < 0.01 && a >= 640) out.push(s);
        }
        return out;
    }

    // What a monitor is doing right now, in the shape Settings saves.
    function ruleOf(mon) {
        return { mode: currentMode(mon), x: mon.x, y: mon.y, scale: Math.round(mon.scale * 1000000) / 1000000,
            transform: mon.transform, vrr: mon.vrr ? 1 : 0, disabled: !!mon.disabled };
    }

    // Size on the desktop, after scaling and rotation.
    function logicalSize(rule) {
        const m = parseMode(rule.mode) || { w: 1920, h: 1080 };
        const w = m.w / rule.scale, h = m.h / rule.scale;
        return rule.transform % 2 === 1 ? { w: h, h: w } : { w: w, h: h };
    }

    function attempt(rules) {
        const before = {};
        for (const mon of monitors) if (rules[mon.name]) before[mon.name] = ruleOf(mon);
        HyprSystem.tryMonitors(rules);
        pending = { rules: rules, before: before };
        secondsLeft = 15;
        countdown.restart();
        settle.restart();
    }

    function keep() {
        if (!pending) return;
        const all = Object.assign({}, Config.display.monitors);
        for (const name in pending.rules) all[name] = pending.rules[name];
        // Hyprland already shows this layout; saving must not apply it twice.
        pending = null;
        countdown.stop();
        Config.display.monitors = all;
        settle.restart();
    }

    function revert() {
        if (!pending) return;
        HyprSystem.tryMonitors(pending.before);
        pending = null;
        countdown.stop();
        settle.restart();
    }

    // Give every monitor back to the Hyprland config.
    function forgetAll() {
        if (!managed) return;
        Config.display.monitors = ({});
        HyprSystem.reload();
        settle.restart();
    }

    Timer {
        id: countdown
        interval: 1000
        repeat: true
        onTriggered: { root.secondsLeft--; if (root.secondsLeft <= 0) root.revert(); }
    }

    Timer { id: settle; interval: 1200; onTriggered: root.refresh() }

    Process {
        id: proc
        command: ["hyprctl", "monitors", "all", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.monitors = JSON.parse(text).sort((a, b) => (a.x - b.x) || (a.y - b.y)); } catch (e) {}
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded" || event.name.startsWith("monitor")) settle.restart();
        }
    }
}
