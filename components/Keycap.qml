import QtQuick
import qs.config

Rectangle {
    property string label: ""
    property bool dim: false

    implicitWidth: Math.max(26, cap.implicitWidth + 14)
    implicitHeight: 24
    radius: Theme.radius.xs
    color: Theme.layerHi
    border.width: 1
    border.color: Theme.outlineHi
    opacity: dim ? 0.45 : 1

    Txt {
        id: cap
        anchors.centerIn: parent
        text: parent.label
        size: 11.5
        font.weight: Font.DemiBold
    }
}
