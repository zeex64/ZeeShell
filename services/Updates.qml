pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Looks for package updates. It only ever lists them: installing happens in a
// terminal, where the package manager can ask its questions and sudo can ask
// for the password.
Singleton {
    id: root

    property bool supported: true // a package manager this service understands was found
    property bool checking: false
    property bool checked: false
    property var items: [] // { name, from, to, source }
    property string checkedAt: ""
    property string helper: "" // paru | yay | ""
    readonly property int count: items.length

    function check() {
        if (checking) return;
        checking = true;
        probe.running = true;
    }

    // What "Update now" runs, shown to the user before they press it.
    readonly property string command: {
        const parts = [helper !== "" ? helper + " -Syu" : "sudo pacman -Syu"];
        if (items.some(i => i.source === "Flatpak")) parts.push("flatpak update");
        return parts.join(" && ");
    }

    function install() { Device.runInTerminal(command); }

    Process {
        id: probe
        command: ["sh", "-c", "command -v checkupdates >/dev/null 2>&1 || { echo '!unsupported'; exit 0; }\n"
            + "h=''; command -v paru >/dev/null 2>&1 && h=paru; [ -z \"$h\" ] && command -v yay >/dev/null 2>&1 && h=yay; echo \"!helper $h\"\n"
            + "checkupdates 2>/dev/null | sed 's/^/Packages /'\n"
            + "[ -n \"$h\" ] && \"$h\" -Qua 2>/dev/null | sed 's/^/AUR /'\n"
            + "command -v flatpak >/dev/null 2>&1 && flatpak remote-ls --updates --columns=name,version 2>/dev/null | sed 's/^/Flatpak\\t/'\n"
            + "true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                let supported = true, helper = "";
                for (const line of text.split("\n")) {
                    if (line === "!unsupported") { supported = false; continue; }
                    if (line.startsWith("!helper")) { helper = line.slice(8).trim(); continue; }
                    if (line.startsWith("Flatpak\t")) {
                        const f = line.split("\t");
                        if (f[1]) out.push({ name: f[1], from: "", to: f[2] || "", source: "Flatpak" });
                        continue;
                    }
                    // "Packages name 1.0-1 -> 1.1-1"
                    const m = /^(Packages|AUR) (\S+) (\S+) -> (\S+)/.exec(line);
                    if (m) out.push({ name: m[2], from: m[3], to: m[4], source: m[1] });
                }
                root.supported = supported;
                root.helper = helper;
                root.items = out;
                root.checking = false;
                root.checked = true;
                root.checkedAt = Qt.formatDateTime(new Date(), "h:mm AP");
            }
        }
    }
}
