import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import qs.config

// Rounds the corners of each monitor by drawing four small black wedges on
// top of everything. Four tiny click-through windows per screen, rather than
// one full-screen overlay, so there is nothing for the compositor to blend.
// They step aside while a window is fullscreen.
Variants {
    model: Quickshell.screens

    Scope {
        id: scope

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool fullscreen: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.hasFullscreen : false
        readonly property int size: Math.max(1, Config.appearance.screenRadius)

        Variants {
            // 0 top-left, 1 top-right, 2 bottom-right, 3 bottom-left
            model: Config.appearance.screenCorners ? [0, 1, 2, 3] : []

            PanelWindow {
                id: win

                required property int modelData

                screen: scope.modelData
                visible: !scope.fullscreen
                color: "transparent"
                implicitWidth: scope.size
                implicitHeight: scope.size
                exclusionMode: ExclusionMode.Ignore
                mask: Region {}
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "zeeshell-corner"

                anchors {
                    top: win.modelData < 2
                    bottom: win.modelData >= 2
                    left: win.modelData === 0 || win.modelData === 3
                    right: win.modelData === 1 || win.modelData === 2
                }

                Shape {
                    anchors.fill: parent
                    rotation: win.modelData * 90
                    preferredRendererType: Shape.CurveRenderer

                    // The corner of a square, minus a quarter circle.
                    ShapePath {
                        strokeWidth: -1
                        fillColor: "black"
                        startX: 0
                        startY: 0

                        PathLine { x: scope.size; y: 0 }
                        PathArc { x: 0; y: scope.size; radiusX: scope.size; radiusY: scope.size; direction: PathArc.Counterclockwise }
                        PathLine { x: 0; y: 0 }
                    }
                }
            }
        }
    }
}
