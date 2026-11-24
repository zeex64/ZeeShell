pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import qs.config

// Power mode, battery, and turning the screens off. The idle timers that use
// this live in shell.qml.
Singleton {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery !== null && battery.isLaptopBattery
    readonly property real percent: hasBattery ? battery.percentage : 0 // 0..1
    readonly property bool charging: hasBattery && (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged || battery.state === UPowerDeviceState.PendingCharge)
    readonly property bool onBattery: UPower.onBattery
    property bool profiles: false // power-profiles-daemon (or a stand-in) is running
    readonly property int profile: PowerProfiles.profile
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile
    readonly property string profileName: profile === PowerProfile.PowerSaver ? "Power saver" : profile === PowerProfile.Performance ? "Performance" : "Balanced"
    property bool screensOff: false

    function setProfile(p) { PowerProfiles.profile = p; }

    function duration(seconds) {
        if (!(seconds > 0)) return "";
        const h = Math.floor(seconds / 3600), m = Math.round(seconds % 3600 / 60);
        return h > 0 ? h + " h " + m + " min" : m + " min";
    }
    readonly property string batteryText: !hasBattery ? "" : Math.round(percent * 100) + "%"
        + (charging ? (battery.timeToFull > 0 ? "  ·  full in " + duration(battery.timeToFull) : "  ·  plugged in")
            : (battery.timeToEmpty > 0 ? "  ·  " + duration(battery.timeToEmpty) + " left" : ""))

    function screens(on) {
        if (Quickshell.env("ZEE_DRY")) return;
        screensOff = !on;
        Quickshell.execDetached(Hypr.lua
            ? ["hyprctl", "eval", "hl.dispatch(hl.dsp.dpms({ action = \"" + (on ? "on" : "off") + "\" }))"]
            : ["hyprctl", "dispatch", "dpms", on ? "on" : "off"]);
    }

    function suspend() { if (!Quickshell.env("ZEE_DRY")) Quickshell.execDetached(["systemctl", "suspend"]); }

    Process {
        command: ["sh", "-c", "command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl get >/dev/null 2>&1"]
        running: true
        onExited: code => root.profiles = code === 0
    }
}
