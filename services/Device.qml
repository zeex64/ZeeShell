pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Facts about this computer and its user that do not change while the shell
// runs, plus the few system-level actions Settings offers. Anything that needs
// a password is left to polkit or to a terminal: the shell never sees one.
Singleton {
    id: root

    property string host: ""
    property string os: "Linux"
    property string kernel: ""
    property string model: ""
    property string cpu: ""
    property string gpu: ""
    property string hyprland: ""
    property string quickshell: ""
    property string fullName: ""
    property string avatar: "" // file path, "" when there is none
    property int avatarStamp: 0 // bumped to make images reload
    property string message: "" // result of the last action
    property bool failed: false

    readonly property string user: Quickshell.env("USER") || "user"
    readonly property string version: "0.1"
    readonly property string summary: [["Device", host], ["Model", model], ["System", os], ["Kernel", kernel], ["Processor", cpu], ["Graphics", gpu],
        ["Desktop", hyprland], ["Shell", "ZeeShell " + version + " on " + quickshell]].filter(r => r[1] !== "").map(r => r[0] + ": " + r[1]).join("\n")

    function refresh() { facts.running = true; }

    // Run a command in a terminal window and keep it open afterwards, for
    // things that ask questions or passwords (updates, passwd).
    function runInTerminal(script) {
        Quickshell.execDetached(["sh", "-c", "exec \"${TERMINAL:-$(command -v kitty konsole foot alacritty wezterm ghostty 2>/dev/null | head -1)}\" -e sh -c \"$1\"", "sh",
            script + "; printf '\\nDone. Press Enter to close. '; read _"]);
    }

    function copy(text) { Quickshell.execDetached(["wl-copy", "--", text]); }

    function act(command, done) {
        message = "";
        failed = false;
        action.label = done;
        action.command = command;
        action.running = true;
    }

    function rename(name) {
        const clean = name.trim();
        if (!/^[A-Za-z0-9][A-Za-z0-9-]{0,62}$/.test(clean)) { message = "Use letters, digits and hyphens only"; failed = true; return; }
        act(["hostnamectl", "hostname", clean], "Renamed to " + clean);
    }

    function setAvatar(path) {
        const p = path.trim().replace(/^~/, Config.home).replace(/^file:\/\//, "");
        if (p === "") return;
        act(["sh", "-c", "test -f \"$1\" && cp -f -- \"$1\" \"$HOME/.face\"", "sh", p], "Picture updated");
    }

    Process {
        id: action
        property string label: ""
        stderr: StdioCollector { id: actionErr }
        onExited: code => {
            root.failed = code !== 0;
            root.message = code === 0 ? label : (actionErr.text.trim().split("\n").pop() || "That did not work");
            root.refresh();
        }
    }

    Process {
        id: facts
        // The greeter already works out the exact CPU and GPU names; reuse its cache.
        command: ["bash", "-c", "\"$1\" --specs >/dev/null 2>&1; . \"${XDG_CACHE_HOME:-$HOME/.cache}/zeeshell/specs\" 2>/dev/null\n"
            + "p() { printf '%s\\t%s\\n' \"$1\" \"$2\"; }\n"
            + "p host \"$(hostnamectl hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || uname -n)\"\n"
            + "p os \"$os\"; p kernel \"$(uname -r)\"; p cpu \"$cpu\"; p gpu \"$gpu\"; p hyprland \"$wm\"\n"
            + "v=\"$(cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null)\"; n=\"$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null)\"\n"
            + "case \"$n\" in ''|'System Product Name'|'To Be Filled'*|'Default string') n=\"$(cat /sys/devices/virtual/dmi/id/board_name 2>/dev/null)\"; v=\"$(cat /sys/devices/virtual/dmi/id/board_vendor 2>/dev/null)\";; esac\n"
            + "p model \"$(printf '%s %s' \"$v\" \"$n\" | sed 's/^ *//; s/ *$//')\"\n"
            + "p quickshell \"$(qs --version 2>/dev/null | head -1)\"\n"
            + "p fullName \"$(getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1)\"\n"
            + "for f in \"$HOME/.face\" \"$HOME/.face.icon\" \"/var/lib/AccountsService/icons/$USER\"; do [ -r \"$f\" ] && { p avatar \"$f\"; break; }; done\n",
            "bash", Quickshell.shellPath("scripts/fetch.sh")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const d = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("\t");
                    if (i > 0) d[line.slice(0, i)] = line.slice(i + 1).trim();
                }
                root.host = d.host || "";
                root.os = d.os || "Linux";
                root.kernel = d.kernel || "";
                root.cpu = d.cpu || "";
                root.gpu = d.gpu || "";
                root.hyprland = d.hyprland || "Hyprland";
                root.model = d.model || "";
                root.quickshell = (d.quickshell || "Quickshell").replace(/\s*\(.*$/, "");
                root.fullName = d.fullName || "";
                root.avatar = d.avatar || "";
                root.avatarStamp++;
            }
        }
    }
}
