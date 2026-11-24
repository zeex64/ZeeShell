import QtQuick
import qs.config
import qs.components

// One group of bar modules. Draws its own island in the "islands" style.
Rectangle {
    id: root

    property var modules: []
    property var screen
    readonly property string style: Config.bar.style
    readonly property real pad: style === "pills" ? 0 : 5

    function file(name) { return "items/" + name.charAt(0).toUpperCase() + name.slice(1) + "Item.qml"; }

    visible: modules.length > 0
    height: parent.height
    width: row.implicitWidth + pad * 2
    radius: Math.min(Theme.radius.lg, height / 2)
    color: style === "islands" ? Theme.panel : "transparent"
    border.width: style === "islands" ? 1 : 0
    border.color: Theme.border
    clip: true

    Behavior on width { Anim { ms: 420 } }
    Behavior on color { CAnim {} }

    Row {
        id: row
        x: root.pad
        height: parent.height
        spacing: root.style === "pills" ? 6 : 0

        Repeater {
            model: root.modules

            Loader {
                required property string modelData

                height: row.height
                visible: status === Loader.Ready && item.shown
                source: Config.barModules[modelData] ? root.file(modelData) : ""
                onLoaded: item.screen = root.screen
            }
        }
    }
}
