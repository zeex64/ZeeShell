pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Which app opens what. Read with `gio mime`, set with `xdg-mime default`, so
// the choice is the same one every other desktop tool sees.
Singleton {
    id: root

    readonly property var kinds: [
        { key: "browser", label: "Web browser", icon: "globe", mimes: ["x-scheme-handler/https", "x-scheme-handler/http", "text/html"] },
        { key: "files", label: "File manager", icon: "folder", mimes: ["inode/directory"] },
        { key: "mail", label: "Email", icon: "envelope", mimes: ["x-scheme-handler/mailto"] },
        { key: "text", label: "Text editor", icon: "file-text", mimes: ["text/plain"] },
        { key: "images", label: "Image viewer", icon: "image", mimes: ["image/png", "image/jpeg", "image/webp", "image/gif"] },
        { key: "video", label: "Video player", icon: "film-strip", mimes: ["video/mp4", "video/x-matroska", "video/webm"] },
        { key: "music", label: "Music player", icon: "music-notes", mimes: ["audio/mpeg", "audio/flac", "audio/ogg"] },
        { key: "pdf", label: "PDF documents", icon: "file-pdf", mimes: ["application/pdf"] }
    ]
    property var current: ({}) // kind -> desktop id (without .desktop)
    property var choices: ({}) // kind -> [desktop id, ...]
    property bool loaded: false
    readonly property string ownFiles: "zeeshell-files" // the shell's file explorer

    function entry(id) {
        // The list first (so names appear when it finishes loading), then by
        // id, which also finds entries hidden from app menus.
        return DesktopEntries.applications.values.find(a => a.id === id) || DesktopEntries.byId(id) || null;
    }
    function name(id) {
        const e = entry(id);
        return e ? e.name : id;
    }
    function icon(id) {
        const e = entry(id);
        return Quickshell.iconPath(e && e.icon ? e.icon : "application-x-executable", "application-x-executable");
    }

    function refresh() { query.running = true; }

    function choose(kind, id) {
        const k = kinds.find(x => x.key === kind);
        if (!k) return;
        const c = Object.assign({}, current);
        c[kind] = id;
        current = c;
        // Keep the switch under Apps -> Files & Steam telling the same story.
        if (kind === "files") Config.files.handleFolders = id === ownFiles;
        setter.command = ["xdg-mime", "default", id + ".desktop"].concat(k.mimes);
        setter.running = true;
    }

    Process { id: setter; onExited: root.refresh() }

    Process {
        id: query
        command: ["sh", "-c", root.kinds.map(k => "echo '##" + k.key + "'; LC_ALL=C gio mime '" + k.mimes[0] + "' 2>/dev/null").join("; ")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const current = {}, choices = {};
                let kind = "";
                for (const line of text.split("\n")) {
                    if (line.startsWith("##")) { kind = line.slice(2); choices[kind] = []; continue; }
                    if (kind === "") continue;
                    const m = /^Default application for .*: (\S+)\.desktop\s*$/.exec(line);
                    if (m) { current[kind] = m[1]; continue; }
                    const a = /^\s+(\S+)\.desktop\s*$/.exec(line);
                    if (a && choices[kind].indexOf(a[1]) < 0) choices[kind].push(a[1]);
                }
                root.current = current;
                root.choices = choices;
                root.loaded = true;
                // The default can be changed outside the shell too.
                if (current.files !== undefined && !Quickshell.env("ZEE_DRY")) Config.files.handleFolders = current.files === root.ownFiles;
            }
        }
    }
}
