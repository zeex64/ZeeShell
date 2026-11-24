import QtQuick
import qs.config
import qs.components

// A row that only tells: a label and the value it has.
Opt {
    id: root

    property string value: ""
    property bool mono: false

    Txt {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, 420)
        horizontalAlignment: Text.AlignRight
        text: root.value
        mono: root.mono
        elide: Text.ElideRight
        color: Theme.textDim
    }
}
