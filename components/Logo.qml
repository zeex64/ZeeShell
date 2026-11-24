import QtQuick
import QtQuick.Shapes
import qs.config

// The ZeeShell mark: a soft tile with a Z drawn as one flowing stroke. The
// corners of the Z are curves, so the line never changes direction abruptly.
Rectangle {
    id: root

    property real size: 24
    property color stroke: Theme.accentInk
    property real draw: 1 // 0..1, for the draw-on animation

    implicitWidth: size
    implicitHeight: size
    radius: Math.min(size * 0.32, Theme.radius.md * size / 30 + 2)
    gradient: Gradient {
        GradientStop { position: 0; color: Qt.lighter(Theme.accent, 1.14) }
        GradientStop { position: 1; color: Qt.darker(Theme.accent, 1.1) }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: path

            readonly property real s: root.size
            readonly property real len: s * 1.16 / strokeWidth // path length, in dash units

            strokeColor: root.stroke
            strokeWidth: s * 0.108
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            strokeStyle: ShapePath.DashLine
            dashPattern: [len, len]
            dashOffset: (1 - root.draw) * len
            startX: s * 0.29
            startY: s * 0.335

            // top bar, easing into the diagonal
            PathLine { x: path.s * 0.55; y: path.s * 0.335 }
            PathCubic {
                control1X: path.s * 0.74; control1Y: path.s * 0.335
                control2X: path.s * 0.74; control2Y: path.s * 0.40
                x: path.s * 0.60; y: path.s * 0.46
            }
            // diagonal, easing into the bottom bar
            PathLine { x: path.s * 0.40; y: path.s * 0.54 }
            PathCubic {
                control1X: path.s * 0.26; control1Y: path.s * 0.60
                control2X: path.s * 0.26; control2Y: path.s * 0.665
                x: path.s * 0.45; y: path.s * 0.665
            }
            PathLine { x: path.s * 0.71; y: path.s * 0.665 }
        }
    }
}
