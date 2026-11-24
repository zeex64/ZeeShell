pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    readonly property var list: Mpris.players.values
    // The player the shell shows: the one you picked, else whatever is
    // playing, else the first one.
    property var chosen: null
    readonly property var active: {
        if (chosen && list.indexOf(chosen) >= 0) return chosen;
        for (const p of list) if (p.isPlaying) return p;
        return list.length ? list[0] : null;
    }

    function pick(player) { chosen = player; }
    readonly property bool playing: active ? active.isPlaying : false
    readonly property string title: active ? (active.trackTitle || "Unknown title") : ""
    readonly property string artist: active ? (active.trackArtist || active.identity || "") : ""
    readonly property string art: active ? (active.trackArtUrl || "") : ""
    readonly property real progress: active && active.length > 0 ? Math.min(1, active.position / active.length) : 0

    function toggle() { if (active && active.canTogglePlaying) active.togglePlaying(); }
    function next() { if (active && active.canGoNext) active.next(); }
    function previous() { if (active && active.canGoPrevious) active.previous(); }
    function time(s) {
        s = Math.max(0, Math.floor(s));
        const m = Math.floor(s / 60), r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: root.active.positionChanged()
    }
}
