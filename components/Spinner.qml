import QtQuick
import qs.config

Icon {
    id: root
    name: "circle-notch"
    size: 22
    color: Theme.accent

    RotationAnimation on rotation {
        running: root.visible
        from: 0
        to: 360
        duration: 800
        loops: Animation.Infinite
    }
}
