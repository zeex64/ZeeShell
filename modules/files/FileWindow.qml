import Quickshell
import QtQuick
import Qt.labs.folderlistmodel
import qs.config
import qs.components
import qs.services

// One explorer window: sidebar, toolbar, the folder's contents, a status bar.
// All the window's state lives here; the pieces around it only draw it.
FloatingWindow {
    id: win

    required property int modelData
    property string startPath: Config.home

    property string path: Config.home
    property var back: []
    property var forward: []
    property var entries: [] // { name, path, dir, size, modified, suffix }
    property var selected: ({}) // path -> true
    property string pivot: "" // where a shift-click range starts
    property int cursor: -1 // keyboard position in `entries`
    property string filter: ""
    property var menu: null // { x, y, items }
    property var prompt: null // see FilePrompt
    property real space: -1 // bytes free where this folder lives
    readonly property var chosen: Object.keys(selected)
    readonly property bool grid: Config.files.view === "grid"
    readonly property alias stage: scene
    readonly property string promptText: asker.typed

    // Tabs. The current tab's state is the window's own properties above; the
    // others wait here as snapshots and are swapped in when you switch.
    property var tabs: [{ id: 1, path: Config.home, back: [], forward: [], selected: ({}), pivot: "", cursor: -1, filter: "" }]
    property int current: 0
    property int nextTab: 2

    signal newWindow(string path)
    signal closeRequested()

    function stash() {
        const t = tabs.slice();
        t[current] = { id: tabs[current].id, path: path, back: back, forward: forward, selected: selected, pivot: pivot, cursor: cursor, filter: filter };
        tabs = t;
    }

    function restore(t) {
        menu = null;
        back = t.back;
        forward = t.forward;
        path = t.path;
        selected = t.selected;
        pivot = t.pivot;
        cursor = t.cursor;
        filter = t.filter;
        Files.quiet();
    }

    function switchTab(i) {
        if (i === current || i < 0 || i >= tabs.length) return;
        stash();
        current = i;
        restore(tabs[i]);
    }

    // p: folder to open ("" = the same folder). behind: keep looking at this tab.
    function newTab(p, behind) {
        stash();
        const t = tabs.slice();
        t.splice(current + 1, 0, { id: nextTab++, path: tidy(p && p !== "" ? p : path), back: [], forward: [], selected: ({}), pivot: "", cursor: -1, filter: "" });
        tabs = t;
        if (!behind) {
            current = current + 1;
            restore(tabs[current]);
        }
    }

    function closeTab(i) {
        if (i < 0 || i >= tabs.length) return;
        if (tabs.length === 1) { closeRequested(); return; }
        stash();
        const t = tabs.slice();
        t.splice(i, 1);
        if (i === current) {
            current = Math.min(i, t.length - 1);
            tabs = t;
            restore(t[current]);
        } else {
            if (i < current) current = current - 1;
            tabs = t;
        }
    }

    title: "Files — " + Files.nameOf(path)
    color: "transparent"
    implicitWidth: 1180
    implicitHeight: 740
    minimumSize: Qt.size(680, 440)

    Component.onCompleted: {
        go(startPath, true);
        Files.watching = true;
        Files.refreshDrives();
        Files.refreshNetwork();
    }
    onPathChanged: Files.free(path, n => win.space = n)

    // ---- moving around -------------------------------------------------------
    function tidy(p) {
        p = String(p).trim();
        if (p === "~" || p.indexOf("~/") === 0) p = Config.home + p.slice(1);
        if (p.indexOf("file://") === 0) p = Files.fromUri(p);
        if (p.length > 1) p = p.replace(/\/+$/, "");
        return p === "" ? "/" : p;
    }

    function go(p, silent) {
        p = tidy(p);
        if (p === path) return;
        if (!silent) {
            back = back.concat([path]);
            forward = [];
        }
        path = p;
        selected = ({});
        pivot = "";
        cursor = -1;
        filter = "";
        menu = null;
        Files.quiet();
    }

    function goBack() {
        if (!back.length) return;
        const stack = back.slice(), p = stack.pop();
        forward = forward.concat([path]);
        back = stack;
        go(p, true);
    }

    function goForward() {
        if (!forward.length) return;
        const stack = forward.slice(), p = stack.pop();
        back = back.concat([path]);
        forward = stack;
        go(p, true);
    }

    function goUp() { if (path !== "/") go(Files.dirOf(path)); }

    // Typed into the path bar: only go if it is really a folder.
    function tryGo(p) {
        p = tidy(p);
        Files.isFolder(p, ok => {
            if (ok) win.go(p);
            else { Files.failed = true; Files.message = "No such folder: " + p; }
        });
    }

    function open(entry) {
        if (entry.dir) go(entry.path);
        else Files.open(entry.path);
    }

    // ---- the listing ---------------------------------------------------------
    FolderListModel {
        id: folder
        folder: Files.uri(win.path)
        showHidden: Config.files.showHidden
        showDotAndDotDot: false
        showOnlyReadable: false
        sortField: FolderListModel.Unsorted
        onCountChanged: rebuild.restart()
        onStatusChanged: rebuild.restart()
    }

    Timer { id: rebuild; interval: 25; onTriggered: win.list() }

    Connections {
        target: Config.files
        function onSortByChanged() { win.list(); }
        function onSortReversedChanged() { win.list(); }
    }

    onFilterChanged: list()

    function list() {
        const out = [], q = filter.trim().toLowerCase();
        for (let i = 0; i < folder.count; i++) {
            const name = folder.get(i, "fileName");
            if (q !== "" && name.toLowerCase().indexOf(q) < 0) continue;
            out.push({
                name: name, path: folder.get(i, "filePath"), dir: folder.get(i, "fileIsDir"),
                size: folder.get(i, "fileSize"), modified: folder.get(i, "fileModified"), suffix: folder.get(i, "fileSuffix")
            });
        }
        const by = Config.files.sortBy, flip = Config.files.sortReversed ? -1 : 1;
        // "file2" before "file10": compare runs of digits as numbers.
        const chunks = t => t.toLowerCase().match(/\d+|\D+/g) || [];
        const byName = (a, b) => {
            const x = chunks(a.name), y = chunks(b.name);
            for (let i = 0; i < Math.min(x.length, y.length); i++) {
                if (x[i] === y[i]) continue;
                const n = parseInt(x[i]), m = parseInt(y[i]);
                if (!isNaN(n) && !isNaN(m)) return n - m;
                return x[i] < y[i] ? -1 : 1;
            }
            return x.length - y.length || (a.name < b.name ? -1 : a.name > b.name ? 1 : 0);
        };
        out.sort((a, b) => {
            if (a.dir !== b.dir) return a.dir ? -1 : 1; // folders first, always
            let r = 0;
            if (by === "size") r = a.size - b.size;
            else if (by === "modified") r = a.modified - b.modified;
            else if (by === "type") r = String(a.suffix).localeCompare(String(b.suffix));
            return (r !== 0 ? r : byName(a, b)) * flip;
        });
        entries = out;

        // Forget selections that are no longer here (once the folder has loaded:
        // a tab that was just switched to brings its selection with it).
        if (folder.status !== FolderListModel.Ready) return;
        const keep = {}, here = {};
        for (const e of out) here[e.path] = true;
        for (const p of chosen) if (here[p]) keep[p] = true;
        if (Object.keys(keep).length !== chosen.length) selected = keep;
        if (cursor >= out.length) cursor = out.length - 1;
    }

    // ---- selection -----------------------------------------------------------
    function indexOf(p) {
        for (let i = 0; i < entries.length; i++) if (entries[i].path === p) return i;
        return -1;
    }

    function selectOnly(p) {
        const s = {};
        s[p] = true;
        selected = s;
        pivot = p;
        cursor = indexOf(p);
    }

    function toggle(p) {
        const s = Object.assign({}, selected);
        if (s[p]) delete s[p];
        else s[p] = true;
        selected = s;
        pivot = p;
        cursor = indexOf(p);
    }

    function selectTo(p) {
        const a = indexOf(pivot), b = indexOf(p);
        if (a < 0 || b < 0) { selectOnly(p); return; }
        const s = {};
        for (let i = Math.min(a, b); i <= Math.max(a, b); i++) s[entries[i].path] = true;
        selected = s;
        cursor = b;
    }

    function selectAll() {
        const s = {};
        for (const e of entries) s[e.path] = true;
        selected = s;
    }

    function clearSelection() {
        if (chosen.length) selected = ({});
        pivot = "";
    }

    function selectedEntries() { return entries.filter(e => selected[e.path] === true); }

    function step(delta, extend) {
        if (!entries.length) return;
        const i = Math.max(0, Math.min(entries.length - 1, (cursor < 0 ? (delta > 0 ? -1 : entries.length) : cursor) + delta));
        if (extend && pivot !== "") selectTo(entries[i].path);
        else selectOnly(entries[i].path);
        view.reveal(i);
    }

    // ---- actions -------------------------------------------------------------
    function ask(request) { menu = null; prompt = request; }

    function rename() {
        const e = selectedEntries()[0];
        if (!e) return;
        ask({ kind: "rename", title: "Rename", value: e.name, stem: e.dir ? e.name.length : (e.name.lastIndexOf(".") > 0 ? e.name.lastIndexOf(".") : e.name.length), accept: "Rename", done: v => Files.rename(e.path, v.trim()) });
    }

    function newFolder() { ask({ kind: "name", title: "New folder", value: "New folder", stem: 10, accept: "Create", done: v => Files.makeFolder(win.path, v.trim()) }); }
    function newFile() { ask({ kind: "name", title: "New file", value: "Untitled.txt", stem: 8, accept: "Create", done: v => Files.makeFile(win.path, v.trim()) }); }
    function trash() { Files.trash(chosen); }
    function copy() { Files.hold(chosen, "copy"); }
    function cut() { Files.hold(chosen, "cut"); }
    function paste() { Files.paste(path); }

    function erase() {
        const paths = chosen.slice();
        if (!paths.length) return;
        ask({
            kind: "confirm", title: paths.length === 1 ? "Delete “" + Files.nameOf(paths[0]) + "” for good?" : "Delete " + paths.length + " items for good?",
            text: "This skips the trash and cannot be undone.", accept: "Delete", danger: true, done: () => Files.remove(paths)
        });
    }

    function properties() {
        const picked = selectedEntries();
        const e = picked.length === 1 ? picked[0] : null;
        const target = e ? e.path : path;
        const rows = [];
        if (picked.length > 1) {
            rows.push(["Selected", picked.length + " items"]);
            rows.push(["Files", Files.size(picked.reduce((n, x) => n + (x.dir ? 0 : x.size), 0))]);
            rows.push(["In", path]);
            ask({ kind: "info", title: "Properties", rows: rows });
            return;
        }
        rows.push(["Name", Files.nameOf(target)]);
        rows.push(["In", Files.dirOf(target)]);
        rows.push(["Kind", e ? Files.kindLabel(e) : "Folder"]);
        if (e) rows.push(["Changed", Qt.formatDateTime(e.modified, "d MMM yyyy, " + (Config.clock.use24h ? "HH:mm" : "h:mm AP"))]);
        rows.push(["Size", "Working it out…"]);
        ask({ kind: "info", title: "Properties", rows: rows, target: target });
        Files.inspect(target, d => {
            if (!win.prompt || win.prompt.target !== target) return;
            const next = win.prompt.rows.slice(0, -1);
            next.push(["Size", Files.size(d.bytes)]);
            next.push(["Access", d.mode + "   " + d.owner]);
            win.prompt = Object.assign({}, win.prompt, { rows: next });
        });
    }

    function pin(p) {
        if (Config.files.bookmarks.indexOf(p) < 0) Config.files.bookmarks = Config.files.bookmarks.concat([p]);
    }

    function setSort(by) {
        if (Config.files.sortBy === by) Config.files.sortReversed = !Config.files.sortReversed;
        else { Config.files.sortBy = by; Config.files.sortReversed = false; }
    }

    // Right-click menu, for the selection or for the folder itself.
    function showMenu(x, y, entry) {
        const items = [], n = chosen.length, one = n === 1 ? selectedEntries()[0] : null;
        if (entry) {
            items.push({ label: one && one.dir ? "Open" : "Open", icon: "arrow-square-out", run: () => selectedEntries().forEach(e => win.open(e)) });
            if (one && one.dir) items.push({ label: "Open in a new tab", icon: "tabs", hint: "Middle click", run: () => win.newTab(one.path, false) });
            if (one && one.dir) items.push({ label: "Open in a new window", icon: "app-window", run: () => win.newWindow(one.path) });
            items.push({ separator: true });
            items.push({ label: "Cut", icon: "scissors", hint: "Ctrl X", run: cut });
            items.push({ label: "Copy", icon: "copy", hint: "Ctrl C", run: copy });
            if (one) items.push({ label: "Rename", icon: "pencil-simple", hint: "F2", run: rename });
            items.push({ label: "Copy the path", icon: "link", run: () => { Quickshell.clipboardText = chosen.join("\n"); } });
            if (one && one.dir) items.push({ label: "Add to favourites", icon: "star", run: () => win.pin(one.path) });
            items.push({ separator: true });
            items.push({ label: "Move to the trash", icon: "trash", hint: "Del", run: trash });
            items.push({ label: "Delete for good", icon: "x-circle", hint: "Shift Del", danger: true, run: erase });
            items.push({ separator: true });
            items.push({ label: "Properties", icon: "info", run: properties });
        } else {
            items.push({ label: "New folder", icon: "folder-plus", hint: "Ctrl Shift N", run: newFolder });
            items.push({ label: "New file", icon: "file-plus", run: newFile });
            items.push({ separator: true });
            items.push({ label: "Paste", icon: "clipboard-text", hint: "Ctrl V", run: paste });
            items.push({ label: "Select everything", icon: "selection-all", hint: "Ctrl A", run: selectAll });
            items.push({ separator: true });
            items.push({ label: Config.files.showHidden ? "Hide hidden files" : "Show hidden files", icon: "eye", hint: "Ctrl H", run: () => { Config.files.showHidden = !Config.files.showHidden; } });
            items.push({ label: "Open a terminal here", icon: "terminal-window", run: () => Files.terminal(win.path) });
            items.push({ label: "New tab", icon: "tabs", hint: "Ctrl T", run: () => win.newTab("", false) });
            items.push({ label: "Open in a new window", icon: "app-window", hint: "Ctrl N", run: () => win.newWindow(win.path) });
            items.push({ separator: true });
            items.push({ label: "Properties", icon: "info", run: properties });
        }
        menu = { x: x, y: y, items: items };
    }

    function sortMenu(x, y) {
        const mark = by => Config.files.sortBy === by ? (Config.files.sortReversed ? "arrow-up" : "arrow-down") : "";
        menu = {
            x: x, y: y, items: [
                { label: "Name", icon: "text-aa", mark: mark("name"), run: () => win.setSort("name") },
                { label: "Size", icon: "ruler", mark: mark("size"), run: () => win.setSort("size") },
                { label: "Date changed", icon: "clock", mark: mark("modified"), run: () => win.setSort("modified") },
                { label: "Type", icon: "shapes", mark: mark("type"), run: () => win.setSort("type") }
            ]
        };
    }

    // Files dropped onto a folder (or onto this window).
    function receive(urls, dest, move) {
        const paths = [];
        for (const u of urls) {
            const p = Files.fromUri(u.toString());
            if (Files.dirOf(p) !== dest && p !== dest) paths.push(p);
        }
        Files.transfer(paths, dest, move);
    }

    // Driven by `ipc call files act`, for scripted checks.
    function script(what, argument) {
        const find = name => entries.find(e => e.name === name);
        if (what === "go") tryGo(argument);
        else if (what === "back") goBack();
        else if (what === "forward") goForward();
        else if (what === "up") goUp();
        else if (what === "select") { const e = find(argument); if (e) selectOnly(e.path); }
        else if (what === "add") { const e = find(argument); if (e) toggle(e.path); }
        else if (what === "all") selectAll();
        else if (what === "none") clearSelection();
        else if (what === "open") { const e = find(argument); if (e) open(e); }
        else if (what === "view") Config.files.view = argument;
        else if (what === "sort") setSort(argument);
        else if (what === "filter") filter = argument;
        else if (what === "hidden") Config.files.showHidden = argument === "on";
        else if (what === "copy") copy();
        else if (what === "cut") cut();
        else if (what === "paste") paste();
        else if (what === "trash") trash();
        else if (what === "newFolder") Files.makeFolder(path, argument);
        else if (what === "newFile") Files.makeFile(path, argument);
        else if (what === "rename") { const e = selectedEntries()[0]; if (e) Files.rename(e.path, argument); }
        else if (what === "menu") showMenu(Number(argument.split(",")[0]) || 400, Number(argument.split(",")[1]) || 300, chosen.length ? selectedEntries()[0] : null);
        else if (what === "prompt") { if (argument === "rename") rename(); else if (argument === "delete") erase(); else if (argument === "properties") properties(); else if (argument === "newFolder") newFolder(); else prompt = null; }
        else if (what === "accept") { if (prompt && prompt.done) { const d = prompt.done; prompt = null; d(argument); } }
        else if (what === "dismiss") { menu = null; prompt = null; }
        else if (what === "newTab") newTab(argument, false);
        else if (what === "tabBehind") newTab(argument, true);
        else if (what === "tab") switchTab(Number(argument));
        else if (what === "closeTab") closeTab(argument === "" ? current : Number(argument));
        else if (what === "pin") pin(argument === "" ? path : argument);
    }

    // ---- the window ------------------------------------------------------------
    FocusScope {
        id: scene

        anchors.fill: parent
        focus: true

        Keys.onPressed: e => {
            const ctrl = e.modifiers & Qt.ControlModifier, shift = e.modifiers & Qt.ShiftModifier, alt = e.modifiers & Qt.AltModifier;
            e.accepted = true;
            if (e.key === Qt.Key_Escape) {
                if (win.menu) win.menu = null;
                else if (win.prompt) win.prompt = null;
                else if (win.filter !== "") win.filter = "";
                else win.clearSelection();
                scene.forceActiveFocus();
            } else if (win.prompt) {
                e.accepted = false;
            } else if (e.key === Qt.Key_Backspace || (alt && e.key === Qt.Key_Up)) win.goUp();
            else if (alt && e.key === Qt.Key_Left) win.goBack();
            else if (alt && e.key === Qt.Key_Right) win.goForward();
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) win.selectedEntries().forEach(x => win.open(x));
            else if (e.key === Qt.Key_Delete) shift ? win.erase() : win.trash();
            else if (e.key === Qt.Key_F2) win.rename();
            else if (e.key === Qt.Key_F5) win.list();
            else if (ctrl && shift && e.key === Qt.Key_N) win.newFolder();
            else if (ctrl && e.key === Qt.Key_N) win.newWindow(win.path);
            else if (ctrl && e.key === Qt.Key_T) win.newTab("", false);
            else if (ctrl && e.key === Qt.Key_W) win.closeTab(win.current);
            else if (ctrl && e.key === Qt.Key_Backtab) win.switchTab((win.current + win.tabs.length - 1) % win.tabs.length);
            else if (ctrl && e.key === Qt.Key_Tab) win.switchTab((win.current + 1) % win.tabs.length);
            else if (alt && e.key >= Qt.Key_1 && e.key <= Qt.Key_9) win.switchTab(e.key - Qt.Key_1);
            else if (ctrl && e.key === Qt.Key_C) win.copy();
            else if (ctrl && e.key === Qt.Key_X) win.cut();
            else if (ctrl && e.key === Qt.Key_V) win.paste();
            else if (ctrl && e.key === Qt.Key_A) win.selectAll();
            else if (ctrl && e.key === Qt.Key_H) Config.files.showHidden = !Config.files.showHidden;
            else if (ctrl && e.key === Qt.Key_L) tools.editPath();
            else if (ctrl && e.key === Qt.Key_F) tools.focusSearch("");
            else if (e.key === Qt.Key_Right) win.step(1, shift);
            else if (e.key === Qt.Key_Left) win.step(-1, shift);
            else if (e.key === Qt.Key_Down) win.step(view.columns, shift);
            else if (e.key === Qt.Key_Up) win.step(-view.columns, shift);
            else if (e.key === Qt.Key_Home) win.step(-win.entries.length, shift);
            else if (e.key === Qt.Key_End) win.step(win.entries.length, shift);
            else if (!ctrl && !alt && e.text.length === 1 && e.text >= " ") tools.focusSearch(e.text); // just start typing to filter
            else e.accepted = false;
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.panel
        }

        PlacesBar {
            id: places
            win: win
            width: 212
            height: parent.height
        }

        FileTabs {
            id: strip
            win: win
            anchors.left: places.right
            anchors.right: parent.right
            height: 42
        }

        FileToolbar {
            id: tools
            win: win
            anchors.left: places.right
            anchors.right: parent.right
            anchors.top: strip.bottom
            height: 56
        }

        FileView {
            id: view
            win: win
            anchors.left: places.right
            anchors.right: parent.right
            anchors.top: tools.bottom
            anchors.bottom: bar.top
        }

        // status bar
        Item {
            id: bar
            anchors.left: places.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 38

            Rectangle { width: parent.width; height: 1; color: Theme.outline }

            Row {
                x: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Spinner { anchors.verticalCenter: parent.verticalCenter; size: 15; visible: Files.busy > 0 }

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 12
                    color: Files.failed ? Theme.danger : Theme.textDim
                    text: {
                        if (Files.message !== "") return Files.message;
                        const n = win.chosen.length, total = win.entries.length;
                        let t = total + (total === 1 ? " item" : " items");
                        if (win.filter !== "") t += " matching “" + win.filter + "”";
                        if (n > 0) {
                            const picked = win.selectedEntries(), bytes = picked.reduce((s, x) => s + (x.dir ? 0 : x.size), 0);
                            t = n + " selected" + (picked.some(x => !x.dir) ? "  ·  " + Files.size(bytes) : "") + "  ·  " + t;
                        }
                        return t + (win.space >= 0 ? "  ·  " + Files.size(win.space) + " free" : "");
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                visible: win.grid

                Icon { anchors.verticalCenter: parent.verticalCenter; name: "image-square"; size: 13; color: Theme.textMute }

                Slide {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 130
                    height: 18
                    implicitHeight: 18
                    step: 0.08
                    value: (Config.files.iconSize - 40) / 120
                    onMoved: v => Config.files.iconSize = Math.round(40 + v * 120)
                }

                Icon { anchors.verticalCenter: parent.verticalCenter; name: "image-square"; size: 19; color: Theme.textMute }
            }
        }

        FileMenu { win: win; anchors.fill: parent }
        FilePrompt { id: asker; win: win; anchors.fill: parent }
    }
}
