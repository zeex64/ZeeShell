pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Disk space: the mounted volumes, what fills the home folder, and the trash.
Singleton {
    id: root

    property var volumes: [] // { device, type, size, used, free, mount }
    property var folders: [] // { name, path, size } largest first; filled by analyse()
    property real homeSize: 0
    property real trashSize: 0
    property real cacheSize: 0
    property bool analysing: false
    property bool analysed: false

    function human(b) {
        const u = ["B", "KB", "MB", "GB", "TB", "PB"];
        let i = 0;
        while (b >= 1024 && i < u.length - 1) { b /= 1024; i++; }
        return (b >= 100 || i === 0 ? Math.round(b) : b.toFixed(1)) + " " + u[i];
    }

    function refresh() { df.running = true; small.running = true; }
    function analyse() { if (analysing) return; analysing = true; du.running = true; }
    function emptyTrash() { empty.running = true; }

    Process {
        id: df
        command: ["sh", "-c", "df -B1 -x tmpfs -x devtmpfs -x efivarfs -x overlay -x squashfs -x fuse.portal --output=source,fstype,size,used,avail,target 2>/dev/null | tail -n +2; echo ---labels; lsblk -rno PATH,LABEL 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const byDevice = {}, labels = {}, parts = text.split("---labels\n");
                for (const line of (parts[1] || "").split("\n")) {
                    const i = line.indexOf(" ");
                    if (i > 0 && line.length > i + 1) labels[line.slice(0, i)] = line.slice(i + 1).replace(/\\x([0-9a-fA-F]{2})/g, (m, h) => String.fromCharCode(parseInt(h, 16)));
                }
                for (const line of (parts[0] || "").trim().split("\n")) {
                    const f = line.trim().split(/\s+/);
                    if (f.length < 6) continue;
                    const v = { device: f[0], type: f[1], size: parseFloat(f[2]), used: parseFloat(f[3]), free: parseFloat(f[4]), mount: f.slice(5).join(" "), label: labels[f[0]] || "" };
                    if (!(v.size > 0) || v.mount.startsWith("/boot") || v.mount.startsWith("/efi")) continue;
                    // btrfs subvolumes share one device: show it once, by its shortest mount point.
                    const seen = byDevice[v.device];
                    if (!seen || v.mount.length < seen.mount.length) byDevice[v.device] = v;
                }
                root.volumes = Object.values(byDevice).sort((a, b) => a.mount === "/" ? -1 : b.mount === "/" ? 1 : a.mount.localeCompare(b.mount));
            }
        }
    }

    Process {
        id: small
        command: ["sh", "-c", "du -sB1 \"${XDG_DATA_HOME:-$HOME/.local/share}/Trash\" 2>/dev/null | cut -f1; echo; du -sxB1 \"${XDG_CACHE_HOME:-$HOME/.cache}\" 2>/dev/null | cut -f1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.split("\n");
                root.trashSize = parseFloat(f[0]) || 0;
                root.cacheSize = parseFloat(f[f.length > 2 ? 2 : 1]) || 0;
            }
        }
    }

    Process {
        id: du
        command: ["sh", "-c", "du -xB1 -d1 \"$HOME\" 2>/dev/null | sort -rn | head -13"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                let total = 0;
                for (const line of text.trim().split("\n")) {
                    const i = line.indexOf("\t");
                    if (i < 0) continue;
                    const size = parseFloat(line.slice(0, i)), path = line.slice(i + 1);
                    if (path === Config.home) { total = size; continue; }
                    out.push({ name: path.slice(path.lastIndexOf("/") + 1), path: path, size: size });
                }
                root.folders = out;
                root.homeSize = total;
                root.analysing = false;
                root.analysed = true;
            }
        }
    }

    Process {
        id: empty
        command: ["gio", "trash", "--empty"]
        onExited: small.running = true
    }
}
