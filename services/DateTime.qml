pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Time zone and clock synchronisation, through systemd's timedatectl. Changing
// either asks polkit for permission; the shell never handles a password.
Singleton {
    id: root

    property string zone: ""
    property bool ntp: false
    property bool synced: false
    property string locale: ""
    property var zones: []
    property string error: ""

    function refresh() { status.running = true; }
    function loadZones() { if (!zones.length) list.running = true; }

    function setZone(z) {
        error = "";
        change.command = ["timedatectl", "set-timezone", z];
        change.running = true;
    }
    function setNtp(on) {
        error = "";
        ntp = on;
        change.command = ["timedatectl", "set-ntp", on ? "true" : "false"];
        change.running = true;
    }

    Process {
        id: change
        stderr: StdioCollector { id: changeErr }
        onExited: code => {
            root.error = code === 0 ? "" : (changeErr.text.trim().split("\n").pop() || "The change was not allowed");
            root.refresh();
        }
    }

    Process {
        id: status
        command: ["sh", "-c", "timedatectl show 2>/dev/null; printf 'Locale='; (localectl status 2>/dev/null | sed -n 's/.*LANG=//p' | head -1)"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const d = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0) d[line.slice(0, i)] = line.slice(i + 1).trim();
                }
                root.zone = d.Timezone || "";
                root.ntp = d.NTP === "yes";
                root.synced = d.NTPSynchronized === "yes";
                root.locale = d.Locale || "";
            }
        }
    }

    Process {
        id: list
        command: ["timedatectl", "list-timezones"]
        stdout: StdioCollector {
            onStreamFinished: root.zones = text.trim().split("\n").filter(z => z !== "")
        }
    }
}
