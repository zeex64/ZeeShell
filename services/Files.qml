pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Backend of the file explorer: file operations, the clipboard, icons, the
// sidebar's places and drives. One instance is shared by every explorer window.
Singleton {
    id: root

    readonly property string home: Config.home

    // ---- operations -------------------------------------------------------
    property int busy: 0
    property string message: ""
    property bool failed: false

    signal finished()

    // An error stays up long enough to read, then clears.
    onMessageChanged: if (failed && message !== "") fade.restart()

    Timer {
        id: fade
        interval: 7000
        onTriggered: if (root.failed && root.busy === 0) { root.failed = false; root.message = ""; }
    }

    function quiet() { if (failed && busy === 0) { failed = false; message = ""; } }

    function run(label, command, after) {
        busy++;
        failed = false;
        message = label + "…";
        job.createObject(root, { label: label, command: command, after: after || null });
    }

    Component {
        id: job

        Process {
            id: proc

            property string label: ""
            property var after: null

            running: true
            stderr: StdioCollector { id: errors }
            onExited: code => {
                root.busy--;
                if (code !== 0) {
                    root.failed = true;
                    root.message = errors.text.trim().split("\n").pop() || (proc.label + " failed");
                } else if (root.busy === 0) {
                    root.failed = false;
                    root.message = "";
                }
                if (proc.after) proc.after(code);
                root.finished();
                proc.destroy();
            }
        }
    }

    function dirOf(path) { return path.replace(/\/[^/]*$/, "") || "/"; }
    function nameOf(path) { return path === "/" ? "/" : path.split("/").pop(); }
    function join(dir, name) { return dir === "/" ? "/" + name : dir + "/" + name; }
    function validName(name) { return name !== "" && name !== "." && name !== ".." && name.indexOf("/") < 0; }

    function open(path) { Quickshell.execDetached(["xdg-open", path]); }
    function trash(paths) { if (paths.length) run("Moving to trash", ["gio", "trash", "--"].concat(paths)); }
    function remove(paths) { if (paths.length) run("Deleting", ["rm", "-rf", "--"].concat(paths)); }
    function emptyTrash() { run("Emptying the trash", ["gio", "trash", "--empty"]); }
    function transfer(paths, dest, move) {
        if (paths.length) run(move ? "Moving" : "Copying", [Quickshell.shellPath("scripts/files-transfer.sh"), dest, move ? "move" : "copy"].concat(paths));
    }
    function rename(path, name, after) {
        if (!validName(name)) { failed = true; message = "That name cannot be used"; return; }
        if (name === nameOf(path)) return;
        run("Renaming", ["sh", "-c", "[ -e \"$2\" ] && { echo 'That name is already taken' >&2; exit 1; }; mv -- \"$1\" \"$2\"", "sh", path, join(dirOf(path), name)], after);
    }
    function makeFolder(dir, name, after) {
        if (!validName(name)) { failed = true; message = "That name cannot be used"; return; }
        run("Creating the folder", ["mkdir", "--", join(dir, name)], after);
    }
    function makeFile(dir, name, after) {
        if (!validName(name)) { failed = true; message = "That name cannot be used"; return; }
        run("Creating the file", ["sh", "-c", "[ -e \"$1\" ] && { echo 'That name is already taken' >&2; exit 1; }; : > \"$1\"", "sh", join(dir, name)], after);
    }
    function terminal(dir) {
        Quickshell.execDetached(["sh", "-c", "cd \"$1\" && exec \"${TERMINAL:-$(command -v kitty konsole foot alacritty wezterm ghostty 2>/dev/null | head -1)}\"", "sh", dir]);
    }

    // ---- clipboard ---------------------------------------------------------
    // Kept here (so cut works between windows) and mirrored to the system
    // clipboard as a file list, so other apps can paste what you copy.
    property var clip: ({ mode: "", paths: [] })

    function uri(path) { return "file://" + path.split("/").map(encodeURIComponent).join("/"); }
    function fromUri(u) { return decodeURIComponent(String(u).replace(/^file:\/\//, "")); }

    function hold(paths, mode) {
        if (!paths.length) return;
        clip = { mode: mode, paths: paths.slice() };
        Quickshell.execDetached(["sh", "-c", "command -v wl-copy >/dev/null && printf '%s\\r\\n' \"$@\" | wl-copy -t text/uri-list", "sh"].concat(paths.map(uri)));
    }

    function paste(dest) {
        if (clip.paths.length) {
            const cut = clip.mode === "cut";
            transfer(clip.paths, dest, cut);
            if (cut) clip = { mode: "", paths: [] };
        } else {
            // Something copied in another file manager.
            fetch.dest = dest;
            fetch.running = true;
        }
    }

    Process {
        id: fetch
        property string dest: ""
        command: ["sh", "-c", "command -v wl-paste >/dev/null && wl-paste -n -t text/uri-list 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const paths = text.split(/\r?\n/).filter(l => l.indexOf("file://") === 0).map(root.fromUri);
                if (paths.length) root.transfer(paths, fetch.dest, false);
            }
        }
    }

    // ---- what a file is ----------------------------------------------------
    readonly property var kinds: ({
        image: ["png", "jpg", "jpeg", "webp", "gif", "bmp", "svg", "avif", "tiff", "ico", "heic"],
        video: ["mp4", "mkv", "webm", "mov", "avi", "m4v", "flv", "wmv"],
        audio: ["mp3", "flac", "ogg", "opus", "wav", "m4a", "aac", "wma"],
        archive: ["zip", "tar", "gz", "xz", "bz2", "zst", "7z", "rar", "tgz", "deb", "rpm", "pkg"],
        document: ["pdf", "doc", "docx", "odt", "rtf", "epub"],
        sheet: ["xls", "xlsx", "ods", "csv"],
        slides: ["ppt", "pptx", "odp"],
        code: ["py", "js", "ts", "qml", "lua", "sh", "bash", "fish", "c", "h", "cpp", "hpp", "rs", "go", "java", "kt", "rb", "php", "css", "scss", "json", "toml", "yaml", "yml", "xml", "sql"],
        web: ["html", "htm"],
        text: ["txt", "md", "log", "conf", "cfg", "ini", "desktop"],
        font: ["ttf", "otf", "woff", "woff2"],
        disk: ["iso", "img"],
        program: ["appimage", "exe", "bin", "run"]
    })

    function kindOf(suffix) {
        const s = String(suffix).toLowerCase();
        for (const k in kinds) if (kinds[k].indexOf(s) >= 0) return k;
        return "file";
    }

    function kindLabel(entry) {
        if (entry.dir) return "Folder";
        const names = {
            image: "Image", video: "Video", audio: "Audio", archive: "Archive", document: "Document", sheet: "Spreadsheet",
            slides: "Presentation", code: "Code", web: "Web page", text: "Text", font: "Font", disk: "Disk image", program: "Program"
        };
        const k = kindOf(entry.suffix);
        return names[k] || (entry.suffix ? entry.suffix.toUpperCase() + " file" : "File");
    }

    function isImage(suffix) { return kinds.image.indexOf(String(suffix).toLowerCase()) >= 0; }

    // Icon from the system icon theme.
    function icon(entry) {
        if (entry.dir) {
            const special = {};
            special[home] = "user-home";
            special[home + "/Desktop"] = "user-desktop";
            special[home + "/Documents"] = "folder-documents";
            special[home + "/Downloads"] = "folder-download";
            special[home + "/Pictures"] = "folder-pictures";
            special[home + "/Music"] = "folder-music";
            special[home + "/Videos"] = "folder-videos";
            return Quickshell.iconPath(special[entry.path] || "folder", "folder");
        }
        const names = {
            image: "image-x-generic", video: "video-x-generic", audio: "audio-x-generic", archive: "package-x-generic",
            document: "x-office-document", sheet: "x-office-spreadsheet", slides: "x-office-presentation", code: "text-x-script",
            web: "text-html", text: "text-x-generic", font: "font-x-generic", disk: "application-x-cd-image", program: "application-x-executable"
        };
        const s = String(entry.suffix).toLowerCase();
        return Quickshell.iconPath(s === "pdf" ? "application-pdf" : names[kindOf(s)] || "text-x-generic", "text-x-generic");
    }

    function size(bytes) {
        const u = ["B", "KB", "MB", "GB", "TB"];
        let i = 0, b = bytes;
        while (b >= 1024 && i < u.length - 1) { b /= 1024; i++; }
        return (i === 0 || b >= 100 ? Math.round(b) : b.toFixed(1)) + " " + u[i];
    }

    // ---- sidebar: places and drives ------------------------------------------
    property var present: ({}) // which of the usual folders exist
    property var drives: [] // { path, label, used, total }
    readonly property string trashPath: (Quickshell.env("XDG_DATA_HOME") || home + "/.local/share") + "/Trash/files"

    readonly property var places: [
        { label: "Home", icon: "house", path: home },
        { label: "Desktop", icon: "desktop", path: home + "/Desktop" },
        { label: "Documents", icon: "file-text", path: home + "/Documents" },
        { label: "Downloads", icon: "download-simple", path: home + "/Downloads" },
        { label: "Pictures", icon: "image", path: home + "/Pictures" },
        { label: "Music", icon: "music-notes", path: home + "/Music" },
        { label: "Videos", icon: "film-strip", path: home + "/Videos" }
    ].filter(p => p.path === home || present[p.path] === true)

    Process {
        command: ["sh", "-c", "for d in Desktop Documents Downloads Pictures Music Videos; do [ -d \"$HOME/$d\" ] && echo \"$HOME/$d\"; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = {};
                for (const line of text.trim().split("\n")) if (line !== "") p[line] = true;
                root.present = p;
            }
        }
    }

    // ---- drives ---------------------------------------------------------------
    // Every partition that holds files, connected or not. Connecting and
    // disconnecting go through udisks, which asks for your password when the
    // system requires it.
    property bool watching: false // an explorer window is open: keep the list fresh
    property var afterDrives: [] // callbacks waiting for the next refresh

    function refreshDrives(after) {
        if (after) afterDrives = afterDrives.concat([after]);
        drivesProc.running = true;
    }

    function driveName(d) {
        const generic = ["Basic data partition", "Microsoft basic data", "Linux filesystem", "primary", ""];
        if (d.mountpoint === "/") return "System";
        if (d.label) return d.label;
        if (d.partlabel && generic.indexOf(d.partlabel) < 0) return d.partlabel;
        return size(d.size) + " " + String(d.fstype).toUpperCase();
    }

    function connectDrive(dev, then) {
        run("Connecting", ["sh", "-c", "command -v udisksctl >/dev/null || { echo 'udisks2 is needed to connect drives' >&2; exit 1; }; udisksctl mount -b \"$1\" >/dev/null", "sh", dev], code => {
            refreshDrives(() => {
                if (code !== 0 || !then) return;
                const d = drives.find(x => x.dev === dev);
                if (d && d.mount !== "") then(d.mount);
            });
        });
    }

    function disconnectDrive(dev) {
        run("Disconnecting", ["udisksctl", "unmount", "-b", dev], () => refreshDrives());
    }

    Process {
        id: drivesProc
        command: ["lsblk", "-J", "-b", "-o", "PATH,TYPE,FSTYPE,LABEL,PARTLABEL,SIZE,MOUNTPOINT,RM,HOTPLUG,FSUSED,FSSIZE,PARTTYPENAME"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let tree;
                try { tree = JSON.parse(text).blockdevices || []; } catch (e) { return; }
                const flat = [], walk = list => { for (const d of list) { flat.push(d); if (d.children) walk(d.children); } };
                walk(tree);
                const hidden = /EFI System|recovery|Microsoft reserved|BIOS boot|swap/i, out = [];
                for (const d of flat) {
                    if (!d.fstype || d.fstype === "swap" || d.fstype === "crypto_LUKS" || d.fstype === "LVM2_member") continue;
                    if (d.type !== "part" && d.type !== "disk" && d.type !== "crypt" && d.type !== "lvm") continue;
                    if (hidden.test(d.parttypename || "") || /^\/(boot|efi)/.test(d.mountpoint || "")) continue;
                    const mount = d.mountpoint && d.mountpoint.charAt(0) === "/" ? d.mountpoint : "";
                    out.push({
                        dev: d.path, label: root.driveName(d), mount: mount, fs: d.fstype,
                        size: Number(d.size) || 0, used: Number(d.fsused) || 0, total: Number(d.fssize) || Number(d.size) || 0,
                        removable: d.rm === true || d.hotplug === true, system: mount === "/"
                    });
                }
                // The system drive first, then connected ones, then the rest.
                out.sort((x, y) => (y.system - x.system) || ((y.mount !== "") - (x.mount !== "")) || x.label.localeCompare(y.label));
                root.drives = out;
                const waiting = root.afterDrives;
                root.afterDrives = [];
                for (const f of waiting) f();
            }
        }
    }

    // Plugging a drive in or pulling it out refreshes the list by itself.
    Process {
        command: ["udisksctl", "monitor"]
        running: root.watching
        stdout: SplitParser { onRead: driveSettle.restart() }
    }

    Timer { id: driveSettle; interval: 700; onTriggered: { root.refreshDrives(); root.refreshNetwork(); } }

    // ---- network locations -----------------------------------------------------
    // Servers are connected with `gio mount` (smb://, sftp://, ftp://, dav://,
    // nfs://). Connected ones appear as ordinary folders. Passwords never pass
    // through the explorer: when a server asks for one, a terminal opens for it.
    property var network: [] // connected now: { label, uri, path }

    function refreshNetwork(after) {
        if (after) netAfter = netAfter.concat([after]);
        netProc.running = true;
    }
    property var netAfter: []

    function sameUri(a, b) { return String(a).replace(/\/+$/, "") === String(b).replace(/\/+$/, ""); }
    function connected(uri) { return network.find(n => sameUri(n.uri, uri)) || null; }

    function remember(uri) {
        if (Config.files.servers.some(s => sameUri(s.uri, uri))) return;
        const m = String(uri).match(/^([a-z0-9+]+):\/\/(?:[^@\/]*@)?([^\/:]+)(?::\d+)?\/?(.*)$/i);
        const label = m ? (m[3] ? m[3].replace(/\/+$/, "").split("/").pop() + " on " + m[2] : m[2]) : uri;
        Config.files.servers = Config.files.servers.concat([{ label: label, uri: uri }]);
    }

    function forget(uri) { Config.files.servers = Config.files.servers.filter(s => !sameUri(s.uri, uri)); }

    function connectServer(uri, then) {
        uri = String(uri).trim();
        if (!/^[a-z0-9+]+:\/\/.+/i.test(uri)) { failed = true; message = "That is not a server address (try smb://server/share)"; return; }
        const landed = () => refreshNetwork(() => {
            const n = connected(uri);
            if (!n) return;
            remember(uri);
            if (then && n.path !== "") then(n.path);
        });
        run("Connecting to " + uri, ["sh", "-c", "gio mount \"$1\" </dev/null", "sh", uri], code => {
            if (code === 0) { landed(); return; }
            if (!/password|authenti|login|credential|permission denied|anonymous/i.test(message)) return;
            // It wants a sign-in: let the user type it into a terminal.
            message = "Sign in in the terminal that just opened";
            failed = false;
            login.then = landed;
            login.command = ["sh", "-c", "exec \"${TERMINAL:-$(command -v kitty konsole foot alacritty wezterm ghostty 2>/dev/null | head -1)}\" -e sh -c 'gio mount \"$1\"; printf \"\\nDone. Press Enter to close. \"; read _' sh \"$1\"", "sh", uri];
            login.running = true;
        });
    }

    function disconnectServer(uri) {
        run("Disconnecting", ["gio", "mount", "-u", uri], () => refreshNetwork());
    }

    Process {
        id: login
        property var then: null
        onExited: { root.message = ""; if (login.then) login.then(); }
    }

    Process {
        id: netProc
        // "label <tab> uri <tab> local folder" for every network mount.
        command: ["sh", "-c", "gio mount -l 2>/dev/null | sed -n 's/^ *Mount([0-9]*): \\(.*\\) -> \\(.*\\)$/\\1\\t\\2/p' | while IFS=\"$(printf '\\t')\" read -r label uri; do case \"$uri\" in file://*) continue ;; esac; path=\"$(gio info \"$uri\" 2>/dev/null | sed -n 's/^local path: //p')\"; printf '%s\\t%s\\t%s\\n' \"$label\" \"$uri\" \"$path\"; done; findmnt -rno TARGET,SOURCE -t nfs,nfs4,cifs,smb3,fuse.sshfs 2>/dev/null | while read -r target source; do printf '%s\\t%s\\t%s\\n' \"$source\" \"\" \"$target\"; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const f = line.split("\t");
                    if (f.length < 3 || f[0] === "") continue;
                    out.push({ label: f[0], uri: f[1], path: f[2] });
                }
                root.network = out;
                const waiting = root.netAfter;
                root.netAfter = [];
                for (const fn of waiting) fn();
            }
        }
    }

    // How much room is left where a folder lives. cb(bytes)
    function free(path, cb) { freeJob.createObject(root, { path: path, cb: cb }); }

    Component {
        id: freeJob

        Process {
            id: fp
            property string path: ""
            property var cb: null
            command: ["sh", "-c", "df -B1 --output=avail \"$1\" 2>/dev/null | tail -1", "sh", path]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    const n = parseInt(text.trim());
                    if (!isNaN(n) && fp.cb) fp.cb(n);
                    fp.destroy();
                }
            }
        }
    }

    // Does this path exist as a folder? cb(bool)
    function isFolder(path, cb) { testJob.createObject(root, { path: path, cb: cb }); }

    Component {
        id: testJob

        Process {
            id: tp
            property string path: ""
            property var cb: null
            command: ["test", "-d", path]
            running: true
            onExited: code => {
                if (tp.cb) tp.cb(code === 0);
                tp.destroy();
            }
        }
    }

    // Details for the properties sheet. cb({ mode, owner, bytes })
    function inspect(path, cb) { statJob.createObject(root, { path: path, cb: cb }); }

    Component {
        id: statJob

        Process {
            id: sp
            property string path: ""
            property var cb: null
            command: ["sh", "-c", "stat -c '%A|%U:%G' -- \"$1\"; du -sb -- \"$1\" 2>/dev/null | cut -f1", "sh", path]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    const lines = text.trim().split("\n"), a = (lines[0] || "|").split("|");
                    if (sp.cb) sp.cb({ mode: a[0] || "", owner: a[1] || "", bytes: parseInt(lines[1]) || 0 });
                    sp.destroy();
                }
            }
        }
    }

    // ---- opening folders with this explorer ----------------------------------
    // Sets (or hands back) the system's default folder handler.
    function useAsDefault(on) {
        if (Quickshell.env("ZEE_DRY")) return;
        if (on) {
            Quickshell.execDetached(["sh", "-c", "cur=\"$(xdg-mime query default inode/directory)\"; [ \"$cur\" != zeeshell-files.desktop ] && printf '%s' \"$cur\" > \"$1\"; xdg-mime default zeeshell-files.desktop inode/directory", "sh", Config.cacheDir + "/previous-file-manager"]);
        } else {
            Quickshell.execDetached(["sh", "-c", "prev=\"$(cat \"$1\" 2>/dev/null)\"; [ -n \"$prev\" ] && xdg-mime default \"$prev\" inode/directory", "sh", Config.cacheDir + "/previous-file-manager"]);
        }
    }
}
