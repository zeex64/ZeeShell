pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Clipboard history, kept by cliphist. The shell starts the watcher that
// stores every copy unless another one is already running (say, from Hyprland's config).
Singleton {
    id: root

    readonly property bool dry: !!Quickshell.env("ZEE_DRY")
    readonly property string thumbDir: Config.cacheDir + "/clipboard"
    property var entries: [] // { id, line, text, image, kind, size }
    property bool available: false // cliphist and wl-clipboard are installed
    property bool loading: false
    property bool watcherFound: false
    property bool probed: false

    // "[[ binary data 12 KiB png 800x600 ]]"
    function parse(line) {
        const tab = line.indexOf("\t");
        if (tab < 0) return null;
        const id = line.slice(0, tab), text = line.slice(tab + 1);
        if (!/^\d+$/.test(id)) return null;
        const bin = /^\[\[ binary data (.+?) (\w+) (\d+x\d+) \]\]$/.exec(text);
        if (bin) return { id: id, line: line, text: "", image: true, kind: bin[2], size: bin[1], dims: bin[3] };
        if (/^\[\[ binary data/.test(text)) return { id: id, line: line, text: "", image: true, kind: "data", size: "", dims: "" };
        return { id: id, line: line, text: text.replace(/\u0000/g, ""), image: false };
    }

    property bool wanted: false // a refresh was asked for before the check finished

    function refresh() {
        if (!probed) { wanted = true; return; }
        if (!available || listProc.running) return;
        loading = true;
        listProc.running = true;
    }

    // Put an entry back on the clipboard.
    function copy(e) {
        if (!e) return;
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", e.id]);
    }

    function copyText(text) { Quickshell.execDetached(["wl-copy", "--", text]); }

    function remove(e) {
        if (!e) return;
        entries = entries.filter(x => x.id !== e.id);
        Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "sh", e.line]);
    }

    function wipe() {
        entries = [];
        Quickshell.execDetached(["cliphist", "wipe"]);
    }

    function isPinned(text) { return Config.clipboard.pinned.indexOf(text) >= 0; }
    function pin(text) {
        if (text === "" || isPinned(text)) return;
        Config.clipboard.pinned = [text].concat(Config.clipboard.pinned);
    }
    function unpin(text) { Config.clipboard.pinned = Config.clipboard.pinned.filter(t => t !== text); }

    // Full text of an entry (the list only holds a 100 character preview).
    function fullText(e, done) {
        const p = textProc.createObject(root, { command: ["cliphist", "decode", e.id] });
        p.got.connect(t => { done(t); p.destroy(); });
        p.running = true;
    }

    // Decode an image entry to a file the preview can show.
    function thumb(e, done) {
        const path = thumbDir + "/" + e.id + "." + (e.kind === "data" ? "bin" : e.kind);
        const p = textProc.createObject(root, { command: ["sh", "-c", "mkdir -p \"$1\" && [ -s \"$2\" ] || cliphist decode \"$3\" > \"$2\"", "sh", thumbDir, path, e.id] });
        p.got.connect(() => { done("file://" + path); p.destroy(); });
        p.running = true;
    }

    Process {
        command: ["sh", "-c", "command -v cliphist >/dev/null && command -v wl-paste >/dev/null || exit 2; pgrep -f '[w]l-paste.*cliphist store' >/dev/null"]
        running: true
        onExited: code => {
            root.available = code !== 2;
            root.watcherFound = code === 0;
            root.probed = true;
            if (root.wanted) { root.wanted = false; root.refresh(); }
        }
    }

    // Our own watcher, for setups that do not start one.
    Process {
        running: root.probed && root.available && !root.watcherFound && Config.clipboard.enabled && !root.dry
        // Named so the check above never mistakes it for an outside recorder.
        command: ["bash", "-c", "exec -a zeeshell-clipboard wl-paste --watch cliphist store"]
    }

    Process {
        id: listProc
        command: ["sh", "-c", "cliphist list | head -n 300"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").map(l => root.parse(l)).filter(e => e !== null);
                root.loading = false;
            }
        }
        onExited: root.loading = false
    }

    Component {
        id: textProc

        Process {
            id: tp
            signal got(string text)
            stdout: StdioCollector { onStreamFinished: tp.got(text) }
        }
    }
}
