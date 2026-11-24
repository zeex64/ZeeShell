pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config
import qs.services

// Keybind editor backend.
//
// Hyprland's own config stays untouched. The binds made or changed in
// Settings are stored in ZeeShell's config and written out as one generated
// Lua file that Hyprland loads last: it releases the combos that were moved or
// disabled and adds the new binds. What the rest of the config binds is
// reported by hypr/probe.lua. install.sh wires both into hyprland.lua.
Singleton {
    id: root

    readonly property bool dry: !!Quickshell.env("ZEE_DRY")
    readonly property string hyprDir: (Quickshell.env("XDG_CONFIG_HOME") || Config.home + "/.config") + "/hypr"
    readonly property string luaPath: hyprDir + "/zeeshell/generated.lua"
    readonly property var managed: Config.keybinds.items

    property var recorded: []
    property bool recorderOk: false
    property string diskText: ""
    property bool diskKnown: false

    readonly property var shellActions: [
        { key: "launcher", label: "App drawer", icon: "squares-four" },
        { key: "sidebar", label: "Quick settings", icon: "sliders-horizontal" },
        { key: "power", label: "Power menu", icon: "power" },
        { key: "wallpaper", label: "Wallpaper picker", icon: "image" },
        { key: "keybinds", label: "Keybinding cheat sheet", icon: "keyboard" },
        { key: "settings", label: "Settings", icon: "gear" },
        { key: "files", label: "File explorer", icon: "folder" },
        { key: "lock", label: "Lock the session", icon: "lock" },
        { key: "editWidgets", label: "Edit widgets", icon: "cards" },
        { key: "steam", label: "Steam workspace", icon: "steam-logo" },
        { key: "randomWallpaper", label: "Random wallpaper", icon: "shuffle" },
        { key: "brightnessUp", label: "Brightness up", icon: "sun" },
        { key: "brightnessDown", label: "Brightness down", icon: "sun-dim" }
    ]

    readonly property var windowActions: {
        const a = [
            { group: "Window", label: "Close window", lua: "hl.dsp.window.close()" },
            { group: "Window", label: "Toggle fullscreen", lua: "hl.dsp.window.fullscreen({ action = \"toggle\" })" },
            { group: "Window", label: "Toggle floating", lua: "hl.dsp.window.float({ action = \"toggle\" })" },
            { group: "Window", label: "Pin window", lua: "hl.dsp.window.pin()" },
            { group: "Window", label: "Toggle split", lua: "hl.dsp.layout(\"togglesplit\")" },
            { group: "Focus", label: "Focus left", lua: "hl.dsp.focus({ direction = \"left\" })" },
            { group: "Focus", label: "Focus right", lua: "hl.dsp.focus({ direction = \"right\" })" },
            { group: "Focus", label: "Focus up", lua: "hl.dsp.focus({ direction = \"up\" })" },
            { group: "Focus", label: "Focus down", lua: "hl.dsp.focus({ direction = \"down\" })" },
            { group: "Focus", label: "Previous workspace", lua: "hl.dsp.focus({ workspace = \"previous\" })" },
            { group: "Focus", label: "Toggle special workspace", lua: "hl.dsp.workspace.toggle_special()" }
        ];
        for (let i = 1; i <= 10; i++) a.push({ group: "Go to workspace", label: String(i), full: "Go to workspace " + i, lua: "hl.dsp.focus({ workspace = " + i + " })" });
        for (let i = 1; i <= 10; i++) a.push({ group: "Move window to workspace", label: String(i), full: "Move window to workspace " + i, lua: "hl.dsp.window.move({ follow = false, workspace = " + i + " })" });
        return a;
    }

    // ---- combos ----------------------------------------------------------
    function parts(combo) {
        const p = String(combo || "").split("+").map(s => s.trim()).filter(s => s !== "");
        if (!p.length) return { mods: [], key: "" };
        const alias = { CONTROL: "CTRL", MOD4: "SUPER", WIN: "SUPER", MOD1: "ALT" };
        return { mods: p.slice(0, -1).map(m => alias[m.toUpperCase()] || m.toUpperCase()), key: p[p.length - 1] };
    }

    function norm(combo) {
        const p = parts(combo);
        return p.mods.slice().sort().join("+") + "|" + p.key.toLowerCase();
    }

    function format(mods, key) {
        const order = ["SUPER", "CTRL", "ALT", "SHIFT"];
        const m = order.filter(x => mods.indexOf(x) >= 0).concat(mods.filter(x => order.indexOf(x) < 0));
        return m.concat([key]).join(" + ");
    }

    function tidy(combo) {
        const p = parts(combo);
        return p.key === "" ? "" : format(p.mods, p.key);
    }

    // Keycap labels for display.
    function caps(combo) {
        const p = parts(combo), names = { SUPER: "Super", CTRL: "Ctrl", ALT: "Alt", SHIFT: "Shift" };
        if (p.key === "") return [];
        return p.mods.map(m => names[m] || m).concat([Hypr.keyLabel(p.key)]);
    }

    // Hyprland key name for a Qt key event; "" for a bare modifier.
    function keyName(e) {
        const k = e.key;
        if (k === Qt.Key_Shift || k === Qt.Key_Control || k === Qt.Key_Alt || k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R || k === Qt.Key_AltGr || k === Qt.Key_CapsLock) return "";
        if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k);
        if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k);
        if (k >= Qt.Key_F1 && k <= Qt.Key_F35) return "F" + (k - Qt.Key_F1 + 1);
        const named = {};
        named[Qt.Key_Space] = "space"; named[Qt.Key_Return] = "Return"; named[Qt.Key_Enter] = "Return"; named[Qt.Key_Escape] = "Escape";
        named[Qt.Key_Tab] = "Tab"; named[Qt.Key_Backtab] = "Tab"; named[Qt.Key_Backspace] = "BackSpace"; named[Qt.Key_Delete] = "Delete";
        named[Qt.Key_Insert] = "Insert"; named[Qt.Key_Home] = "Home"; named[Qt.Key_End] = "End"; named[Qt.Key_PageUp] = "Prior"; named[Qt.Key_PageDown] = "Next";
        named[Qt.Key_Left] = "left"; named[Qt.Key_Right] = "right"; named[Qt.Key_Up] = "up"; named[Qt.Key_Down] = "down"; named[Qt.Key_Print] = "Print";
        named[Qt.Key_VolumeUp] = "XF86AudioRaiseVolume"; named[Qt.Key_VolumeDown] = "XF86AudioLowerVolume"; named[Qt.Key_VolumeMute] = "XF86AudioMute";
        named[Qt.Key_MediaPlay] = "XF86AudioPlay"; named[Qt.Key_MediaTogglePlayPause] = "XF86AudioPlay"; named[Qt.Key_MediaNext] = "XF86AudioNext";
        named[Qt.Key_MediaPrevious] = "XF86AudioPrev"; named[Qt.Key_MediaStop] = "XF86AudioStop";
        if (named[k] !== undefined) return named[k];
        // Punctuation, including what Shift turns it into on a US layout.
        const sym = {
            ",": "comma", "<": "comma", ".": "period", ">": "period", "/": "slash", "?": "slash", "-": "minus", "_": "minus",
            "=": "equal", "+": "equal", ";": "semicolon", ":": "semicolon", "'": "apostrophe", "\"": "apostrophe",
            "[": "bracketleft", "{": "bracketleft", "]": "bracketright", "}": "bracketright", "\\": "backslash", "|": "backslash",
            "`": "grave", "~": "grave", "!": "1", "@": "2", "#": "3", "$": "4", "%": "5", "^": "6", "&": "7", "*": "8", "(": "9", ")": "0"
        };
        if (k < 0x100 && sym[String.fromCharCode(k)] !== undefined) return sym[String.fromCharCode(k)];
        return "";
    }

    function modsOf(m) {
        const out = [];
        if (m & Qt.MetaModifier) out.push("SUPER");
        if (m & Qt.ControlModifier) out.push("CTRL");
        if (m & Qt.AltModifier) out.push("ALT");
        if (m & Qt.ShiftModifier) out.push("SHIFT");
        return out;
    }

    // ---- actions ---------------------------------------------------------
    function luaFor(item) {
        const a = item.action || {};
        if (a.type === "shell") return "hl.dsp.global(" + JSON.stringify("zeeshell:" + a.value) + ")";
        if (a.type === "app" || a.type === "command") return a.value ? "hl.dsp.exec_cmd(" + JSON.stringify(a.value) + ")" : "";
        if (a.type === "window" || a.type === "lua") return a.value || "";
        return "";
    }

    function describe(a) {
        if (!a) return "";
        if (a.type === "shell") { const s = shellActions.find(x => x.key === a.value); return s ? s.label : a.value; }
        if (a.type === "app") return "Open " + (a.name || a.value);
        if (a.type === "command") return "Run: " + a.value;
        if (a.type === "window") { const w = windowActions.find(x => x.lua === a.value); return w ? (w.full || w.label) : a.value; }
        if (a.type === "lua") return a.value;
        return "";
    }

    function actionFromRecord(r) {
        if (r.fn === "hl.dsp.global" && r.arg && r.arg.indexOf("zeeshell:") === 0) return { type: "shell", value: r.arg.slice(9) };
        if (r.fn === "hl.dsp.exec_cmd" && r.arg) return { type: "command", value: r.arg };
        if (r.lua && windowActions.some(x => x.lua === r.lua)) return { type: "window", value: r.lua };
        if (r.lua) return { type: "lua", value: r.lua };
        return { type: "none", value: "" };
    }

    function category(type, description, fn, arg) {
        if (type === "shell") return "Shell";
        if (type === "app") return "Apps";
        return Hypr.category({ description: description, dispatcher: fn || (type === "command" ? "exec" : ""), arg: arg || "" });
    }

    // ---- the merged list the settings page shows --------------------------
    readonly property var rows: {
        const out = [], replaced = {}, taken = {};
        for (const it of managed) {
            if (it.replaces) replaced[norm(it.replaces)] = it;
            if (it.combo) taken[norm(it.combo)] = it;
        }
        for (const it of managed) {
            const a = it.action || {};
            out.push({
                kind: "managed", id: it.id, combo: it.combo, item: it,
                description: it.description || describe(a) || "Keybind",
                detail: it.combo === "" ? "Disabled here" : it.replaces ? "Changed here" : "Added here",
                disabled: it.combo === "", restorable: !!it.replaces, movable: a.type !== "none",
                category: category(a.type, it.description || "", a.type === "command" || a.type === "app" ? "exec" : a.value, a.value)
            });
        }
        for (const r of recorded) {
            if (r.src.indexOf("zeeshell/generated.lua") === 0) continue;
            const k = norm(r.combo);
            if (replaced[k]) continue; // shown through the entry that changed it
            if (!r.active && !taken[k]) continue; // released by the config itself
            const a = actionFromRecord(r);
            out.push({
                kind: "config", id: "c:" + r.src + ":" + k, combo: r.combo, rec: r,
                description: r.desc || describe(a) || "Lua function",
                detail: taken[k] ? "Replaced by your bind on the same keys" : r.src.replace(/:\d+$/, ""),
                disabled: !!taken[k], shadowed: !!taken[k], restorable: false,
                movable: a.type !== "none", mouse: /mouse/.test(r.combo) || /mouse = true/.test(r.flags),
                category: category(a.type, r.desc, r.fn, r.arg)
            });
        }
        return out;
    }

    function uid() { return "k" + Date.now().toString(36) + Math.floor(Math.random() * 1296).toString(36); }

    function draftNew() {
        return { id: uid(), replaces: "", combo: "", action: { type: "shell", value: "launcher" }, description: "", flags: "", fresh: true };
    }

    function draftFor(row) {
        if (row.kind === "managed") return JSON.parse(JSON.stringify(row.item));
        const r = row.rec;
        return { id: uid(), replaces: r.combo, combo: tidy(r.combo), action: actionFromRecord(r), description: r.desc || "", flags: r.flags || "", origin: r.src };
    }

    function upsert(item) {
        const clean = { id: item.id, replaces: item.replaces || "", combo: item.combo || "", action: item.action, description: item.description || "", flags: item.flags || "", origin: item.origin || "" };
        Config.keybinds.items = managed.filter(i => i.id !== clean.id).concat([clean]);
    }

    function remove(id) { Config.keybinds.items = managed.filter(i => i.id !== id); }

    function disable(row) {
        const d = draftFor(row);
        d.combo = "";
        upsert(d);
    }

    // What else is on these keys right now ("" if nothing).
    function conflict(draft, combo) {
        if (!combo) return "";
        const k = norm(combo);
        if (draft.replaces && norm(draft.replaces) === k) return "";
        for (const row of rows) {
            if (row.disabled || row.id === draft.id || norm(row.combo) !== k) continue;
            return row.description;
        }
        return "";
    }

    // ---- generated Lua ---------------------------------------------------
    readonly property string generated: {
        const lines = [
            "-- Generated by ZeeShell (Settings -> Input -> Keybinds). Do not edit: it is rewritten",
            "-- whenever a keybind changes there. Loaded last by the block install.sh adds to hyprland.lua.",
            "",
            "local function free(combo)",
            "\tfor _ = 1, 4 do",
            "\t\thl.unbind(combo)",
            "\tend",
            "end",
            ""
        ];
        const frees = {};
        for (const it of managed) {
            if (it.replaces) frees[tidy(it.replaces)] = true;
            if (it.combo) frees[tidy(it.combo)] = true;
        }
        for (const c in frees) lines.push("free(" + JSON.stringify(c) + ")");
        if (Object.keys(frees).length) lines.push("");
        for (const it of managed) {
            const lua = luaFor(it);
            if (!it.combo || lua === "") continue;
            const opts = ["description = " + JSON.stringify(it.description || describe(it.action))];
            if (it.flags) opts.push(it.flags);
            lines.push("hl.bind(" + JSON.stringify(tidy(it.combo)) + ", " + lua + ", { " + opts.join(", ") + " })");
        }
        return lines.join("\n") + "\n";
    }

    function apply() {
        if (dry || !Config.ready || !diskKnown || !Hypr.probed || !Hypr.lua || !Hypr.hooked) return;
        if (generated === diskText) return;
        diskText = generated;
        out.setText(generated);
        reloadHypr.restart();
    }

    onGeneratedChanged: write.restart()

    Timer { id: write; interval: 450; onTriggered: root.apply() }
    Timer { id: reloadHypr; interval: 300; onTriggered: Quickshell.execDetached(["hyprctl", "reload"]) }

    Connections {
        target: Hypr
        function onProbedChanged() { write.restart(); }
        function onHookedChanged() { write.restart(); }
    }

    FileView {
        id: out
        path: Config.ready ? root.luaPath : ""
        printErrors: false
        onLoaded: { root.diskText = text(); root.diskKnown = true; write.restart(); }
        onLoadFailed: { root.diskText = ""; root.diskKnown = true; write.restart(); }
    }

    // Report from the recorder inside Hyprland.
    FileView {
        id: report
        path: Config.ready ? Config.cacheDir + "/hypr-binds.json" : ""
        watchChanges: true
        printErrors: false
        onFileChanged: report.reload()
        onLoaded: {
            try {
                root.recorded = JSON.parse(text());
                root.recorderOk = true;
            } catch (e) {
                retry.restart(); // caught Hyprland mid-write
            }
        }
    }

    Timer { id: retry; interval: 300; onTriggered: report.reload() }
}
