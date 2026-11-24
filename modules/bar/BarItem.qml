import QtQuick
import qs.config
import qs.components

// Base for every bar module: hover pill, click + wheel handling.
Item {
    id: root

    default property alias content: row.data
    property var screen
    property bool shown: true
    property bool interactive: true
    property bool active: false
    property real pad: 10
    property real spacing: 6
    readonly property bool pills: Config.bar.style === "pills"
    readonly property alias hovered: layer.containsMouse

    signal clicked()
    signal rightClicked()
    signal scrolled(int direction)

    implicitWidth: row.implicitWidth + pad * 2
    scale: layer.pressed && interactive ? 0.94 : 1

    Behavior on scale { Anim { ms: 320; curve: Theme.curve.spring } }

    Rectangle {
        id: pill
        anchors.fill: parent
        anchors.topMargin: root.pills ? 0 : 5
        anchors.bottomMargin: root.pills ? 0 : 5
        radius: Math.min(Theme.radius.lg, height / 2)
        color: root.active ? Theme.accentSoft : root.pills ? Theme.panel : "transparent"
        border.width: root.pills ? 1 : 0
        border.color: Theme.border

        Behavior on color { CAnim {} }

        StateLayer {
            id: layer
            showHover: root.interactive
            cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: e => e.button === Qt.LeftButton ? root.clicked() : root.rightClicked()
            onWheel: e => root.scrolled(e.angleDelta.y > 0 ? 1 : -1)
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.spacing
    }
}
