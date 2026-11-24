import Quickshell
import Quickshell.Io
import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.sidebar as Side

// Wi-Fi, wired connections and VPNs, through NetworkManager.
Column {
    id: page

    property var links: [] // connected devices: { device, type, name, address, gateway, dns }
    property var vpns: [] // { name, type, active }

    function typeName(t) { return t === "wifi" ? "Wi-Fi" : t === "ethernet" ? "Wired" : t === "wireguard" ? "WireGuard" : t; }
    function reload() { details.running = true; vpnList.running = true; }

    spacing: 12
    Component.onCompleted: reload()

    Group {
        title: "Wi-Fi"

        ToggleOpt {
            label: "Wi-Fi"
            hint: Network.wifiEnabled ? (Network.ssid !== "" ? "Connected to " + Network.ssid : "Not connected") : "Turned off"
            checked: Network.wifiEnabled
            onToggled: v => { Network.setWifi(v); if (v) rescan.restart(); }
        }

        Opt {
            visible: Network.wifiEnabled
            label: "Networks in range"
            hint: Network.scanning ? "Scanning…" : "Pick one to connect. Secured networks ask for their password."
            Btn { text: "Scan"; icon: "arrows-clockwise"; kind: "ghost"; onClicked: Network.scan() }
        }

        Side.WifiPage {
            visible: Network.wifiEnabled
            width: parent.width
            bottomPadding: 8
        }
    }

    Group {
        title: "Connections"

        Txt { visible: page.links.length === 0; height: 40; verticalAlignment: Text.AlignVCenter; text: "Not connected to any network"; color: Theme.textMute }

        Repeater {
            model: page.links

            Column {
                id: link
                required property var modelData
                width: parent.width

                Opt {
                    label: link.modelData.name
                    hint: page.typeName(link.modelData.type) + "  ·  " + link.modelData.device
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: link.modelData.type === "wifi" ? "wifi-high" : "plugs-connected"; size: 20; color: Theme.accent }
                }

                InfoOpt { visible: link.modelData.address !== ""; label: "Address"; value: link.modelData.address; mono: true }
                InfoOpt { visible: link.modelData.gateway !== ""; label: "Router"; value: link.modelData.gateway; mono: true }
                InfoOpt { visible: link.modelData.dns !== ""; label: "DNS"; value: link.modelData.dns; mono: true }
            }
        }
    }

    Group {
        visible: page.vpns.length > 0
        title: "VPN"

        Repeater {
            model: page.vpns

            ToggleOpt {
                required property var modelData
                label: modelData.name
                hint: page.typeName(modelData.type) + (modelData.active ? "  ·  connected" : "")
                checked: modelData.active
                onToggled: v => {
                    vpnSwitch.command = ["nmcli", "connection", v ? "up" : "down", "id", modelData.name];
                    vpnSwitch.running = true;
                }
            }
        }
    }

    Group {
        title: "More"

        Opt {
            label: "Advanced network settings"
            hint: "Static addresses, proxies and new VPNs, in NetworkManager's own editor"
            Btn { text: "Open editor"; icon: "arrow-square-out"; kind: "ghost"; onClicked: Quickshell.execDetached(["sh", "-c", "command -v nm-connection-editor >/dev/null && exec nm-connection-editor"]) }
        }
    }

    Timer { id: rescan; interval: 2500; onTriggered: Network.scan() }

    Connections {
        target: Network
        function onSsidChanged() { page.reload(); }
        function onWiredChanged() { page.reload(); }
    }

    Process { id: vpnSwitch; onExited: page.reload() }

    Process {
        id: details
        command: ["sh", "-c", "LC_ALL=C nmcli -t -f GENERAL.DEVICE,GENERAL.TYPE,GENERAL.STATE,GENERAL.CONNECTION,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const block of text.split("\n\n")) {
                    const d = { device: "", type: "", state: "", name: "", address: "", gateway: "", dns: [] };
                    for (const line of block.split("\n")) {
                        const i = line.indexOf(":");
                        if (i < 0) continue;
                        const k = line.slice(0, i), v = line.slice(i + 1).trim();
                        if (k === "GENERAL.DEVICE") d.device = v;
                        else if (k === "GENERAL.TYPE") d.type = v;
                        else if (k === "GENERAL.STATE") d.state = v;
                        else if (k === "GENERAL.CONNECTION") d.name = v;
                        else if (k.startsWith("IP4.ADDRESS") && d.address === "") d.address = v;
                        else if (k === "IP4.GATEWAY") d.gateway = v === "--" ? "" : v;
                        else if (k.startsWith("IP4.DNS")) d.dns.push(v);
                    }
                    if (!d.state.startsWith("100") || d.type === "loopback" || d.type === "bridge" || d.type === "tun") continue;
                    d.dns = d.dns.join(", ");
                    out.push(d);
                }
                page.links = out;
            }
        }
    }

    Process {
        id: vpnList
        command: ["sh", "-c", "LC_ALL=C nmcli -t -f NAME,TYPE,ACTIVE connection show 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.trim().split("\n")) {
                    const f = Network.split(line);
                    if (f.length >= 3 && (f[1] === "vpn" || f[1] === "wireguard")) out.push({ name: f[0], type: f[1], active: f[2] === "yes" });
                }
                page.vpns = out;
            }
        }
    }
}
