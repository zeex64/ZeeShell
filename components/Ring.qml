import QtQuick
import QtQuick.Shapes
import qs.config

// Circular progress ring.
Item {
    id: root

    property real value: 0 // 0..1
    property real thickness: 5
    property color color: Theme.accent
    property color trackColor: Theme.layerHi
    property real shown: Math.min(1, Math.max(0, value))

    implicitWidth: 56
    implicitHeight: 56

    Behavior on shown { Anim { ms: 600 } }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.trackColor
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.thickness) / 2
                radiusY: (root.height - root.thickness) / 2
                startAngle: 0
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.thickness) / 2
                radiusY: (root.height - root.thickness) / 2
                startAngle: -90
                sweepAngle: Math.max(0.01, 360 * root.shown)
            }
        }
    }
}
