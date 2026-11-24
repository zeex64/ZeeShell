pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    property var usage: ({})

    readonly property var categories: [
        { key: "all", label: "All", icon: "squares-four" },
        { key: "internet", label: "Internet", icon: "globe" },
        { key: "dev", label: "Develop", icon: "code" },
        { key: "media", label: "Media", icon: "play-circle" },
        { key: "graphics", label: "Graphics", icon: "palette" },
        { key: "games", label: "Games", icon: "game-controller" },
        { key: "office", label: "Office", icon: "file-text" },
        { key: "system", label: "System", icon: "wrench" }
    ]

    function cats(entry) {
        const c = entry.categories;
        return (typeof c === "string" ? c.split(";") : Array.from(c || [])).map(s => String(s));
    }

    function inCategory(entry, key) {
        if (key === "all") return true;
        const c = cats(entry);
        const any = list => list.some(x => c.indexOf(x) >= 0);
        switch (key) {
        case "internet": return any(["Network", "WebBrowser", "Email", "Chat", "InstantMessaging"]);
        case "dev": return any(["Development", "IDE", "TextEditor"]);
        case "media": return any(["AudioVideo", "Audio", "Video", "Player", "Music"]);
        case "graphics": return any(["Graphics", "Photography", "2DGraphics", "3DGraphics"]);
        case "games": return any(["Game"]);
        case "office": return any(["Office", "Education", "Science"]);
        case "system": return any(["System", "Settings", "Utility", "TerminalEmulator", "FileManager"]);
        }
        return false;
    }

    function score(entry, q) {
        const name = entry.name.toLowerCase();
        if (name === q) return 120;
        if (name.startsWith(q)) return 100;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 82;
        if (name.indexOf(q) >= 0) return 64;
        let i = 0;
        for (const ch of name) if (ch === q[i]) i++;
        if (i === q.length) return 34;
        const extra = ((entry.genericName || "") + " " + (entry.comment || "") + " " + String(entry.keywords || "")).toLowerCase();
        if (extra.indexOf(q) >= 0) return 22;
        return 0;
    }

    function search(query, category) {
        const q = query.trim().toLowerCase();
        const pool = all.filter(a => inCategory(a, category || "all"));
        if (q === "") {
            const used = pool.filter(a => usage[a.id] > 0).sort((a, b) => usage[b.id] - usage[a.id]).slice(0, Config.launcher.columns);
            return used.concat(pool.filter(a => used.indexOf(a) < 0));
        }
        return pool.map(a => ({ a: a, s: score(a, q) }))
            .filter(x => x.s > 0)
            .map(x => ({ a: x.a, s: x.s + Math.min(12, usage[x.a.id] || 0) }))
            .sort((x, y) => y.s - x.s || x.a.name.localeCompare(y.a.name))
            .map(x => x.a);
    }

    function launch(entry) {
        const u = Object.assign({}, usage);
        u[entry.id] = (u[entry.id] || 0) + 1;
        usage = u;
        store.setText(JSON.stringify(u));
        entry.execute();
    }

    function icon(entry) { return Quickshell.iconPath(entry.icon, "application-x-executable"); }

    FileView {
        id: store
        path: Config.ready ? Config.cacheDir + "/usage.json" : ""
        printErrors: false
        onLoaded: { try { root.usage = JSON.parse(text()); } catch (e) {} }
    }
}
