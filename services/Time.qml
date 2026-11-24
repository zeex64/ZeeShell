pragma Singleton

import Quickshell
import QtQuick
import qs.config

Singleton {
    readonly property date now: clock.date
    // Qt's "h" only gives 12-hour time when the format also contains AP, so
    // the 12-hour clock is worked out by hand.
    readonly property int hour12: (now.getHours() + 11) % 12 + 1
    readonly property string time: (Config.clock.use24h ? Qt.formatDateTime(now, "HH") : String(hour12)) + Qt.formatDateTime(now, Config.clock.showSeconds ? ":mm:ss" : ":mm")
    readonly property string ampm: Config.clock.use24h ? "" : now.getHours() < 12 ? "AM" : "PM"
    readonly property string hours: Config.clock.use24h ? Qt.formatDateTime(now, "HH") : String(hour12)
    readonly property int week: {
        const d = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()));
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
        return Math.ceil(((d - new Date(Date.UTC(d.getUTCFullYear(), 0, 1))) / 86400000 + 1) / 7);
    }
    readonly property string minutes: Qt.formatDateTime(now, "mm")
    readonly property string date: Qt.formatDateTime(now, "ddd d MMM")
    readonly property string longDate: Qt.formatDateTime(now, "dddd, d MMMM")

    function format(f) { return Qt.formatDateTime(now, f); }

    // Label for a whole hour (0-23), e.g. "20:00" or "8 PM".
    function hourLabel(h) {
        h = parseInt(h);
        if (Config.clock.use24h) return (h < 10 ? "0" : "") + h + ":00";
        return ((h + 11) % 12 + 1) + (h < 12 ? " AM" : " PM");
    }

    SystemClock {
        id: clock
        precision: Config.clock.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }
}
