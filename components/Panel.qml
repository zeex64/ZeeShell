import QtQuick
import QtQuick.Effects
import qs.config

// The translucent sheet every popup sits on.
Item {
    id: root

    default property alias content: body.data
    property real radius: Theme.radius.xl
    property alias color: body.color
    property bool shadow: Config.appearance.shadows

    RectangularShadow {
        visible: root.shadow
        anchors.fill: body
        radius: body.radius
        blur: 44
        spread: -6
        offset: Qt.vector2d(0, 14)
        color: Theme.shadow
        cached: true
    }

    // Swallow clicks so they never reach the dismiss area underneath.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onWheel: e => e.accepted = true
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: root.radius
        color: Theme.panel
        border.width: 1
        border.color: Theme.border
    }
}
