import QtQuick
import qs.config

// Flickable with a draggable scrollbar.
Flickable {
    id: root

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 3200
    maximumFlickVelocity: 3600

    ScrollHandle {
        parent: root
        z: 10
        flick: root
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
    }
}
