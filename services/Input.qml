pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Keyboard, mouse and touchpad options. Values are read from Hyprland, so the
// page shows what is really in effect; a change is kept as an override in
// config.json and handed to Hyprland by HyprSystem.
Singleton {
    id: root

    readonly property var options: ["kb_layout", "kb_variant", "kb_options", "repeat_rate", "repeat_delay", "numlock_by_default",
        "sensitivity", "accel_profile", "natural_scroll", "left_handed", "follow_mouse", "scroll_factor",
        "touchpad:natural_scroll", "touchpad:tap-to-click", "touchpad:disable_while_typing", "touchpad:scroll_factor"]
    property var live: ({}) // option -> value Hyprland reports
    property var layouts: [] // [code, name]
    property var variants: ({}) // layout code -> [[code, name], ...]
    readonly property bool managed: Object.keys(Config.input.overrides).length > 0

    function value(opt, fallback) {
        const o = Config.input.overrides;
        if (o[opt] !== undefined) return o[opt];
        return live[opt] !== undefined ? live[opt] : fallback;
    }

    function set(opt, v) {
        const o = Object.assign({}, Config.input.overrides);
        o[opt] = v;
        Config.input.overrides = o;
    }

    function forgetAll() {
        if (!managed) return;
        Config.input.overrides = ({});
        HyprSystem.reload();
        again.restart();
    }

    function refresh() { read.running = true; }

    Timer { id: again; interval: 1500; onTriggered: root.refresh() }

    Process {
        id: read
        command: ["sh", "-c", "for o in " + root.options.join(" ") + "; do hyprctl getoption \"input:$o\" -j 2>/dev/null | tr -d '\\n'; echo; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const line of text.split("\n")) {
                    let d;
                    try { d = JSON.parse(line); } catch (e) { continue; }
                    const k = String(d.option || "").replace(/^input:/, "");
                    if (d.str !== undefined) out[k] = d.str === "[[EMPTY]]" ? "" : d.str;
                    else if (d.float !== undefined) out[k] = d.float;
                    else if (d.int !== undefined) out[k] = d.int;
                    else if (d.bool !== undefined) out[k] = d.bool;
                }
                root.live = out;
            }
        }
    }

    // Layout names, from the list every XKB-based desktop uses.
    Process {
        command: ["sh", "-c", "cat /usr/share/X11/xkb/rules/evdev.lst 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const layouts = [], variants = {};
                let section = "";
                for (const line of text.split("\n")) {
                    if (line.startsWith("!")) { section = line.slice(1).trim(); continue; }
                    const m = /^\s+(\S+)\s+(.*)$/.exec(line);
                    if (!m) continue;
                    if (section === "layout") layouts.push([m[1], m[2]]);
                    else if (section === "variant") {
                        const v = /^(\S+):\s*(.*)$/.exec(m[2]);
                        if (v) (variants[v[1]] = variants[v[1]] || []).push([m[1], v[2]]);
                    }
                }
                root.layouts = layouts.sort((a, b) => a[1].localeCompare(b[1]));
                root.variants = variants;
            }
        }
    }
}
