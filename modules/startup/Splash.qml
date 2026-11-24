import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.components
import qs.services

// Boot animation: the mark draws itself, then the cover lifts and the bar
// and widgets settle in.
Scope {
    id: root

    property bool done: false
    property bool decided: false
    property bool play: false

    // Survives hot reloads, so editing the shell does not replay the intro.
    PersistentProperties {
        id: persist
        reloadableId: "zeeshellSplash"
        property bool played: false
    }

    function decide() {
        if (decided) return;
        decided = true;
        play = Config.startup.animation && !persist.played;
        persist.played = true;
        if (!play) finish();
    }

    function finish() {
        Ui.booted = true;
        done = true;
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            property real draw: 0
            property real pop: 0
            property real lift: 0

            screen: modelData
            visible: !root.done
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "zeeshell-splash"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.bg
                opacity: 1 - win.lift
            }

            Column {
                anchors.centerIn: parent
                spacing: 22
                opacity: win.pop * (1 - win.lift)
                scale: 0.7 + 0.3 * win.pop + 0.5 * win.lift

                Logo {
                    anchors.horizontalCenter: parent.horizontalCenter
                    size: 112
                    draw: win.draw
                }

                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "ZeeShell"
                    size: 26
                    font.weight: Font.Bold
                    font.letterSpacing: 2 + (1 - win.draw) * 14
                    opacity: win.draw
                }
            }

            SequentialAnimation {
                id: intro

                ParallelAnimation {
                    Anim { target: win; property: "pop"; from: 0; to: 1; ms: 620; curve: Theme.curve.spring }
                    Anim { target: win; property: "draw"; from: 0; to: 1; ms: 900 }
                }
                PauseAnimation { duration: Theme.dur(260) }
                ScriptAction { script: Ui.booted = true }
                Anim { target: win; property: "lift"; from: 0; to: 1; ms: 620 }
                ScriptAction { script: root.done = true }
            }

            Connections {
                target: Config
                function onReadyChanged() { win.begin(); }
            }

            function begin() {
                if (!Config.ready || intro.running || root.done) return;
                root.decide();
                if (root.play) intro.start();
            }

            Component.onCompleted: begin()
        }
    }
}
