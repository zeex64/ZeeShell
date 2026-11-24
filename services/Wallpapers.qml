pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config
import "Http.js" as Http

// Local wallpaper library plus the wallhaven.cc browser.
Singleton {
    id: root

    readonly property string dir: Config.wallpaper.directory !== "" ? Config.wallpaper.directory : Config.home + "/Pictures/Wallpapers"
    readonly property string current: Config.wallpaper.path
    property var local: []

    // wallhaven
    property var results: []
    property bool loading: false
    property string error: ""
    property string query: ""
    property int page: 0
    property int lastPage: 1
    property var busy: ({}) // id -> true while downloading
    property int stamp: 0 // bumps so a stale response never lands

    function scan() { finder.running = true; }

    function apply(path) { Config.wallpaper.path = path; }

    function random() {
        if (!local.length) return;
        let pick = local[Math.floor(Math.random() * local.length)];
        if (local.length > 1) while (pick === current) pick = local[Math.floor(Math.random() * local.length)];
        apply(pick);
    }

    function search(q) {
        query = q;
        page = 0;
        lastPage = 1;
        results = [];
        more();
    }

    function more() {
        if (loading || page >= lastPage) return;
        loading = true;
        error = "";
        const w = Config.wallpaper;
        const my = ++stamp;
        let url = "https://wallhaven.cc/api/v1/search?page=" + (page + 1)
            + "&q=" + encodeURIComponent(query)
            + "&categories=" + w.havenCategories
            + "&purity=" + (w.havenSketchy ? "110" : "100")
            + "&sorting=" + (query !== "" && w.havenSorting === "toplist" ? "relevance" : w.havenSorting)
            + "&topRange=" + w.havenRange;
        if (w.havenMatchScreen) {
            let mw = 1920, mh = 1080;
            for (const s of Quickshell.screens) if (s.width * s.height > mw * mh) { mw = s.width; mh = s.height; }
            url += "&atleast=" + mw + "x" + mh;
        }
        Http.get(url, d => {
            if (my !== stamp) return;
            const add = (d.data || []).map(i => ({ id: i.id, thumb: i.thumbs.small, preview: i.thumbs.large, full: i.path, resolution: i.resolution, size: i.file_size, ext: i.path.split(".").pop() }));
            results = results.concat(add);
            page = d.meta ? d.meta.current_page : page + 1;
            lastPage = d.meta ? d.meta.last_page : page;
            loading = false;
        }, e => {
            if (my !== stamp) return;
            error = "wallhaven: " + e;
            loading = false;
        }, w.havenKey !== "" ? { "X-API-Key": w.havenKey } : null);
    }

    function fileFor(item) { return dir + "/wallhaven-" + item.id + "." + item.ext; }
    function has(item) { return local.indexOf(fileFor(item)) >= 0; }

    // Download into the wallpaper folder, then set it.
    function grab(item) {
        const dest = fileFor(item);
        if (has(item)) { apply(dest); return; }
        if (busy[item.id]) return;
        const b = Object.assign({}, busy);
        b[item.id] = true;
        busy = b;
        fetcher.createObject(root, { item: item, dest: dest });
    }

    Component {
        id: fetcher

        Process {
            id: job
            property var item
            property string dest

            command: ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && curl -fsSL --max-time 180 -o \"$1.part\" \"$2\" && mv \"$1.part\" \"$1\"", "sh", dest, item.full]
            running: true
            onExited: code => {
                const b = Object.assign({}, root.busy);
                delete b[job.item.id];
                root.busy = b;
                if (code === 0) {
                    root.local = [job.dest].concat(root.local);
                    root.apply(job.dest);
                } else {
                    root.error = "Download failed";
                }
                job.destroy();
            }
        }
    }

    Process {
        id: finder
        command: ["sh", "-c", "find -L \"$1\" -maxdepth 3 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.avif' \\) -printf '%T@\\t%p\\n' 2>/dev/null | sort -rn | cut -f2-", "sh", root.dir]
        running: Config.ready
        stdout: StdioCollector {
            onStreamFinished: {
                root.local = text.trim() === "" ? [] : text.trim().split("\n");
                if (Config.wallpaper.path === "" && root.local.length) root.apply(root.local[0]);
            }
        }
    }

    onDirChanged: if (Config.ready) scan()
}
