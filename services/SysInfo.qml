pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int cpu: 0
    property int cpuTemp: 0
    property int gpu: -1
    property int gpuTemp: 0
    property real memUsed: 0 // kB
    property real memTotal: 1
    property real vramUsed: 0
    property real vramTotal: 0
    property real diskUsed: 0
    property real diskTotal: 1
    property real rx: 0 // bytes/s
    property real tx: 0
    property int uptime: 0
    property string iface: ""

    readonly property real mem: memUsed / memTotal
    readonly property real disk: diskUsed / diskTotal
    readonly property bool hasGpu: gpu >= 0
    readonly property string user: Quickshell.env("USER") || "user"

    function bytes(b) {
        const u = ["B", "K", "M", "G", "T"];
        let i = 0;
        while (b >= 1024 && i < u.length - 1) { b /= 1024; i++; }
        return (b >= 100 || i === 0 ? Math.round(b) : b.toFixed(1)) + u[i];
    }
    function gib(kb) { return (kb / 1048576).toFixed(1); }
    function uptimeText() {
        const d = Math.floor(uptime / 86400), h = Math.floor(uptime % 86400 / 3600), m = Math.floor(uptime % 3600 / 60);
        return d > 0 ? d + "d " + h + "h" : h > 0 ? h + "h " + m + "m" : m + "m";
    }

    Process {
        command: [Quickshell.shellPath("scripts/sysinfo.sh"), "2"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                let d;
                try { d = JSON.parse(line); } catch (e) { return; }
                root.cpu = d.cpu; root.cpuTemp = d.cpuTemp; root.gpu = d.gpu; root.gpuTemp = d.gpuTemp;
                root.memUsed = d.memUsed; root.memTotal = Math.max(1, d.memTotal);
                root.vramUsed = d.vramUsed; root.vramTotal = d.vramTotal;
                root.diskUsed = d.diskUsed; root.diskTotal = Math.max(1, d.diskTotal);
                root.rx = d.rx; root.tx = d.tx; root.uptime = d.uptime; root.iface = d.iface;
            }
        }
    }
}
