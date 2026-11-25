pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Events from .ics calendar links (Settings -> Time & weather). Each feed is
// fetched with curl and the events of the next two months are worked out
// here, repeating ones included.
Singleton {
    id: root

    property var events: [] // { title, start, end, allDay, location, feed } with times in ms, sorted
    property var days: ({}) // "y-m-d" -> true when something happens that day
    property string error: ""
    property bool loading: false
    readonly property var feeds: Config.calendar.feeds.filter(f => f && f.url && f.enabled !== false)
    readonly property bool active: feeds.length > 0

    function key(d) { return d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate(); }
    function hasEvents(d) { return days[key(d)] === true; }

    // Events touching the given day.
    function eventsOn(d) {
        const a = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime(), b = a + 86400000;
        return events.filter(e => e.start < b && e.end > a);
    }

    function upcoming(n) {
        const now = Date.now();
        return events.filter(e => e.end > now).slice(0, n);
    }

    function timeText(e) {
        if (e.allDay) return "All day";
        const f = Config.clock.use24h ? "HH:mm" : "h:mm AP";
        return Qt.formatTime(new Date(e.start), f) + " – " + Qt.formatTime(new Date(e.end), f);
    }

    function refresh() {
        if (!active || loading) { if (!active) { events = []; days = {}; } return; }
        loading = true;
        error = "";
        pending = feeds.slice();
        collected = [];
        next();
    }

    property var pending: []
    property var collected: []

    function next() {
        if (pending.length === 0) {
            finish();
            return;
        }
        const f = pending[0];
        pending = pending.slice(1);
        fetch.feed = f;
        fetch.command = ["curl", "-sfL", "--max-time", "20", String(f.url).replace(/^webcal:/, "https:")];
        fetch.running = true;
    }

    function finish() {
        const all = collected.sort((a, b) => a.start - b.start);
        const d = {};
        for (const e of all) {
            const end = e.allDay ? e.end - 1 : e.end;
            for (let t = new Date(e.start); t.getTime() <= end; t = new Date(t.getFullYear(), t.getMonth(), t.getDate() + 1)) {
                d[key(t)] = true;
                if (Object.keys(d).length > 2000) break;
            }
        }
        events = all;
        days = d;
        loading = false;
    }

    // ---- .ics ------------------------------------------------------------
    function parseDate(value, params) {
        const v = String(value).trim();
        let m = /^(\d{4})(\d{2})(\d{2})$/.exec(v);
        if (m || /VALUE=DATE(;|$)/.test(params)) {
            m = m || /^(\d{4})(\d{2})(\d{2})/.exec(v);
            return { t: new Date(+m[1], +m[2] - 1, +m[3]).getTime(), allDay: true };
        }
        m = /^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})?(Z?)$/.exec(v);
        if (!m) return null;
        const parts = [+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +(m[6] || 0)];
        // A TZID is read as local time; that is right for calendars in your own zone.
        return { t: m[7] === "Z" ? Date.UTC(...parts) : new Date(...parts).getTime(), allDay: false };
    }

    function duration(v) {
        const m = /^([+-])?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$/.exec(String(v).trim());
        if (!m) return 0;
        const s = (+(m[2] || 0)) * 604800 + (+(m[3] || 0)) * 86400 + (+(m[4] || 0)) * 3600 + (+(m[5] || 0)) * 60 + (+(m[6] || 0));
        return (m[1] === "-" ? -1 : 1) * s * 1000;
    }

    function clean(s) { return String(s).replace(/\\n/gi, " ").replace(/\\([,;\\])/g, "$1").trim(); }

    function parse(text, feed) {
        const lines = text.replace(/\r\n/g, "\n").replace(/\n[ \t]/g, "").split("\n");
        const from = new Date(), to = new Date();
        from.setDate(from.getDate() - 1);
        from.setHours(0, 0, 0, 0);
        to.setDate(to.getDate() + 62);
        const out = [];
        let ev = null;
        for (const line of lines) {
            if (line === "BEGIN:VEVENT") { ev = { ex: [] }; continue; }
            if (line === "END:VEVENT") {
                if (ev && ev.start) expand(ev, feed, from.getTime(), to.getTime(), out);
                ev = null;
                continue;
            }
            if (!ev) continue;
            const c = line.indexOf(":");
            if (c < 0) continue;
            const head = line.slice(0, c), value = line.slice(c + 1);
            const semi = head.indexOf(";");
            const name = (semi < 0 ? head : head.slice(0, semi)).toUpperCase(), params = semi < 0 ? "" : head.slice(semi + 1);
            if (name === "DTSTART") ev.start = parseDate(value, params);
            else if (name === "DTEND") ev.end = parseDate(value, params);
            else if (name === "DURATION") ev.dur = duration(value);
            else if (name === "SUMMARY") ev.title = clean(value);
            else if (name === "LOCATION") ev.location = clean(value);
            else if (name === "RRULE") ev.rrule = value;
            else if (name === "STATUS" && value.trim() === "CANCELLED") ev.cancelled = true;
            else if (name === "EXDATE") for (const x of value.split(",")) { const p = parseDate(x, params); if (p) ev.ex.push(p.t); }
        }
        return out;
    }

    function expand(ev, feed, from, to, out) {
        if (ev.cancelled || !ev.start) return;
        const start = ev.start.t, allDay = ev.start.allDay;
        const len = ev.end ? Math.max(0, ev.end.t - start) : ev.dur ? ev.dur : allDay ? 86400000 : 3600000;
        const push = t => {
            if (t + len <= from || t >= to || ev.ex.indexOf(t) >= 0) return;
            out.push({ title: ev.title || "Untitled", start: t, end: t + Math.max(len, allDay ? 86400000 : 0), allDay: allDay, location: ev.location || "", feed: feed.name || "" });
        };
        if (!ev.rrule) { push(start); return; }

        const r = {};
        for (const kv of ev.rrule.split(";")) { const i = kv.indexOf("="); if (i > 0) r[kv.slice(0, i).toUpperCase()] = kv.slice(i + 1); }
        const step = Math.max(1, parseInt(r.INTERVAL || "1"));
        const count = r.COUNT ? parseInt(r.COUNT) : Infinity;
        const until = r.UNTIL ? (parseDate(r.UNTIL, "") || { t: Infinity }).t : Infinity;
        const dayNames = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"];
        const byDay = r.BYDAY && r.FREQ === "WEEKLY" ? r.BYDAY.split(",").map(s => dayNames.indexOf(s.replace(/^[+-]?\d+/, ""))).filter(i => i >= 0) : [];
        const s0 = new Date(start);
        let made = 0;
        for (let i = 0; i < 2000 && made < count; i++) {
            let base;
            if (r.FREQ === "DAILY") base = new Date(s0.getFullYear(), s0.getMonth(), s0.getDate() + i * step, s0.getHours(), s0.getMinutes(), s0.getSeconds());
            else if (r.FREQ === "WEEKLY") base = new Date(s0.getFullYear(), s0.getMonth(), s0.getDate() + i * 7 * step, s0.getHours(), s0.getMinutes(), s0.getSeconds());
            else if (r.FREQ === "MONTHLY") base = new Date(s0.getFullYear(), s0.getMonth() + i * step, s0.getDate(), s0.getHours(), s0.getMinutes(), s0.getSeconds());
            else if (r.FREQ === "YEARLY") base = new Date(s0.getFullYear() + i * step, s0.getMonth(), s0.getDate(), s0.getHours(), s0.getMinutes(), s0.getSeconds());
            else { push(start); return; }
            const times = [];
            if (byDay.length) {
                // Every listed weekday in the week that holds `base` (weeks start on Monday).
                const monday = new Date(base.getFullYear(), base.getMonth(), base.getDate() - (base.getDay() + 6) % 7, s0.getHours(), s0.getMinutes(), s0.getSeconds());
                for (const d of byDay.slice().sort((a, b) => ((a + 6) % 7) - ((b + 6) % 7)))
                    times.push(new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + (d + 6) % 7, s0.getHours(), s0.getMinutes(), s0.getSeconds()).getTime());
            } else {
                times.push(base.getTime());
            }
            for (const t of times) {
                if (t < start) continue;
                if (t > until || made >= count) return;
                made++;
                push(t);
            }
            if (base.getTime() > to) return;
        }
    }

    Process {
        id: fetch
        property var feed: null
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.indexOf("BEGIN:VCALENDAR") >= 0) root.collected = root.collected.concat(root.parse(text, fetch.feed));
                else if (fetch.feed) root.error = "Could not read " + (fetch.feed.name || fetch.feed.url);
            }
        }
        onExited: root.next()
    }

    onFeedsChanged: refreshSoon.restart()
    Component.onCompleted: refreshSoon.restart()
    Timer { id: refreshSoon; interval: 800; onTriggered: root.refresh() }

    Timer {
        interval: Math.max(5, Config.calendar.refreshMinutes) * 60000
        repeat: true
        running: root.active
        onTriggered: root.refresh()
    }

    // Past midnight the window moves on.
    Connections {
        target: Time
        function onDateChanged() { root.refresh(); }
    }
}
