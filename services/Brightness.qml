pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Backlight via brightnessctl, falling back to DDC/CI for desktop monitors.
Singleton {
    id: root

    property string mode: "" // "" | backlight | ddc
    property real value: 0.5
    property var buses: []
    readonly property bool available: mode !== ""

    signal changed()

    function set(v) {
        value = Math.min(1, Math.max(0.01, v));
        changed();
        apply.restart();
    }

    Timer {
        id: apply
        interval: root.mode === "ddc" ? 220 : 30
        onTriggered: {
            const pct = Math.round(root.value * 100);
            if (root.mode === "backlight") Quickshell.execDetached(["brightnessctl", "-q", "set", pct + "%"]);
            else for (const b of root.buses) Quickshell.execDetached(["ddcutil", "--bus", b, "--noverify", "setvcp", "10", String(pct)]);
        }
    }

    Process {
        command: ["sh", "-c", "brightnessctl -c backlight -m 2>/dev/null | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                if (f.length >= 5) {
                    root.mode = "backlight";
                    root.value = parseInt(f[3]) / 100;
                } else {
                    ddcDetect.running = true;
                }
            }
        }
    }

    Process {
        id: ddcDetect
        command: ["sh", "-c", "command -v ddcutil >/dev/null && ddcutil detect --brief 2>/dev/null | grep -o 'i2c-[0-9]*' | cut -d- -f2"]
        stdout: StdioCollector {
            onStreamFinished: {
                const b = text.trim().split("\n").filter(s => s !== "");
                if (!b.length) return;
                root.buses = b;
                ddcRead.command = ["ddcutil", "--bus", b[0], "--brief", "getvcp", "10"];
                ddcRead.running = true;
            }
        }
    }

    Process {
        id: ddcRead
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(/\s+/); // VCP 10 C <cur> <max>
                if (f.length >= 5 && f[0] === "VCP") {
                    root.value = parseInt(f[3]) / Math.max(1, parseInt(f[4]));
                    root.mode = "ddc";
                }
            }
        }
    }
}
