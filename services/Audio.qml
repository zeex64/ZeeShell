pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property real micVolume: source && source.audio ? source.audio.volume : 0
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false
    readonly property string sinkName: sink ? (sink.description || sink.nickname || sink.name) : "No output"
    readonly property string icon: muted || volume <= 0 ? "speaker-x" : volume < 0.34 ? "speaker-low" : volume < 0.67 ? "speaker-high" : "speaker-high"
    property bool armed: false

    signal changed()

    function setVolume(v) {
        if (!sink || !sink.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.min(1, Math.max(0, v));
    }
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted; }
    function setMicVolume(v) { if (source && source.audio) source.audio.volume = Math.min(1, Math.max(0, v)); }
    function toggleMic() { if (source && source.audio) source.audio.muted = !source.audio.muted; }

    onVolumeChanged: if (armed) changed()
    onMutedChanged: if (armed) changed()

    PwObjectTracker { objects: [root.sink, root.source] }

    // Don't flash the OSD while PipeWire is still settling at startup.
    Timer { interval: 2500; running: true; onTriggered: root.armed = true }
}
