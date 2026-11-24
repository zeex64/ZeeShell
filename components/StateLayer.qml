import QtQuick
import qs.config

// Hover / press feedback for anything clickable. Fills its parent.
MouseArea {
    id: root

    property color tint: Theme.text
    property real radius: parent && parent.radius !== undefined ? parent.radius : 0
    property bool showHover: true

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.tint
        opacity: !root.enabled || !root.showHover ? 0 : root.pressed ? 0.14 : root.containsMouse ? 0.08 : 0

        Behavior on opacity { Anim { ms: 160 } }
    }
}
