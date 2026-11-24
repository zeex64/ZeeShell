import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.components
import qs.services

// Volume / brightness feedback pill.
Scope {
    id: root

    property string kind: "volume"
    property bool shown: false
    property real progress: shown ? 1 : 0
    readonly property real value: kind === "volume" ? Audio.volume : Brightness.value
    readonly property string icon: kind === "volume" ? Audio.icon : "sun"

    function flash(k) {
        if (!Config.osd.enabled || Ui.active === "sidebar") return;
        kind = k;
        shown = true;
        hide.restart();
    }

    Behavior on progress { Anim { ms: root.shown ? 380 : 240; curve: root.shown ? Theme.curve.springSoft : Theme.curve.exit } }

    Timer { id: hide; interval: 1600; onTriggered: root.shown = false }

    Connections {
        target: Audio
        function onChanged() { root.flash("volume"); }
    }

    Connections {
        target: Brightness
        function onChanged() { root.flash("brightness"); }
    }

    LazyLoader {
        active: root.shown || root.progress > 0

        PanelWindow {
            id: win

            readonly property bool top: Config.osd.position === "top"

            screen: {
                const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
                for (const s of Quickshell.screens) if (s.name === name) return s;
                return Quickshell.screens[0];
            }
            color: "transparent"
            implicitWidth: 340
            implicitHeight: 120
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "zeeshell-osd"
            BackgroundEffect.blurRegion: Config.appearance.blur && root.progress > 0.6 ? blur : null

            anchors {
                top: win.top
                bottom: !win.top
            }

            margins {
                top: 70
                bottom: 70
            }

            Region { id: blur; item: pill.body; radius: pill.radius }

            Panel {
                id: pill

                readonly property Item body: pill

                anchors.centerIn: parent
                anchors.verticalCenterOffset: (1 - root.progress) * (win.top ? -30 : 30)
                width: 300
                height: 56
                radius: Math.min(Theme.radius.full, 28)
                opacity: Math.min(1, root.progress * 1.4)
                scale: 0.86 + 0.14 * root.progress

                Icon {
                    id: glyph
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.icon
                    fill: true
                    size: 22
                    color: root.kind === "volume" && Audio.muted ? Theme.textMute : Theme.accent
                }

                Rectangle {
                    anchors.left: glyph.right
                    anchors.leftMargin: 14
                    anchors.right: label.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    height: 8
                    radius: 4
                    color: Theme.layerHi

                    Rectangle {
                        height: parent.height
                        radius: 4
                        width: Math.max(height, parent.width * Math.min(1, root.value))
                        color: root.kind === "volume" && Audio.muted ? Theme.textMute : Theme.accent

                        Behavior on width { Anim { ms: 180 } }
                    }
                }

                Txt {
                    id: label
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    horizontalAlignment: Text.AlignRight
                    text: root.kind === "volume" && Audio.muted ? "Mute" : Math.round(root.value * 100)
                    font.weight: Font.Bold
                    font.features: { "tnum": 1 }
                }
            }
        }
    }
}
