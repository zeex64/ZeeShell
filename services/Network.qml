pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// NetworkManager state through nmcli.
Singleton {
    id: root

    property bool wifiEnabled: false
    property bool wired: false
    property string ssid: ""
    property int strength: 0
    property var networks: [] // { ssid, strength, secure, active }
    property bool scanning: false
    property string connecting: ""
    property string error: ""

    readonly property bool connected: wired || ssid !== ""
    readonly property string label: wired && ssid === "" ? "Wired" : ssid !== "" ? ssid : wifiEnabled ? "Not connected" : "Wi-Fi off"
    readonly property string icon: wired && ssid === "" ? "plugs-connected"
        : !wifiEnabled ? "wifi-slash"
        : ssid === "" ? "wifi-x"
        : strength > 66 ? "wifi-high" : strength > 33 ? "wifi-medium" : "wifi-low"

    // nmcli -t separates fields with ":" and escapes literal colons as "\:".
    function split(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length) cur += line[++i];
            else if (c === ":") { out.push(cur); cur = ""; }
            else cur += c;
        }
        out.push(cur);
        return out;
    }

    function refresh() { status.running = true; }
    function scan() { scanning = true; list.running = true; }
    function setWifi(on) { Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]); wifiEnabled = on; }
    function connect(name, password) {
        error = "";
        connecting = name;
        join.command = password ? ["nmcli", "dev", "wifi", "connect", name, "password", password] : ["nmcli", "dev", "wifi", "connect", name];
        join.running = true;
    }
    function disconnect() { Quickshell.execDetached(["sh", "-c", "nmcli -t -f DEVICE,TYPE dev | awk -F: '$2==\"wifi\"{print $1}' | xargs -r -n1 nmcli dev disconnect"]); }

    Process {
        id: status
        command: ["sh", "-c", "nmcli radio wifi; nmcli -t -f TYPE,STATE dev; echo ---; nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi list --rescan no"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("---\n");
                const head = (parts[0] || "").trim().split("\n");
                root.wifiEnabled = head[0] === "enabled";
                root.wired = head.slice(1).some(l => l.startsWith("ethernet:connected"));
                let ssid = "", strength = 0;
                for (const l of (parts[1] || "").trim().split("\n")) {
                    const f = root.split(l);
                    if (f[0] === "yes") { ssid = f.slice(2).join(":"); strength = parseInt(f[1]) || 0; }
                }
                root.ssid = ssid;
                root.strength = strength;
            }
        }
    }

    Process {
        id: list
        command: ["nmcli", "-t", "-f", "ACTIVE,SIGNAL,SECURITY,SSID", "dev", "wifi", "list", "--rescan", "auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {}, out = [];
                for (const l of text.trim().split("\n")) {
                    const f = root.split(l);
                    if (f.length < 4) continue;
                    const name = f.slice(3).join(":");
                    if (name === "" || seen[name]) continue;
                    seen[name] = true;
                    out.push({ ssid: name, strength: parseInt(f[1]) || 0, secure: f[2] !== "" && f[2] !== "--", active: f[0] === "yes" });
                }
                out.sort((a, b) => (b.active - a.active) || (b.strength - a.strength));
                root.networks = out;
                root.scanning = false;
            }
        }
    }

    Process {
        id: join
        stderr: StdioCollector { id: joinErr }
        onExited: code => {
            root.error = code === 0 ? "" : (joinErr.text.trim().split("\n").pop() || "Could not connect");
            root.connecting = "";
            root.refresh();
            root.scan();
        }
    }

    Process {
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser { onRead: debounce.restart() }
    }

    Timer { id: debounce; interval: 400; onTriggered: root.refresh() }
}
