import QtQuick
import qs.config
import qs.components

Opt {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property real step: 0.05
    property int decimals: 2
    property string suffix: ""

    signal moved(real value)

    Txt {
        anchors.verticalCenter: parent.verticalCenter
        width: 56
        horizontalAlignment: Text.AlignRight
        text: root.value.toFixed(root.decimals) + root.suffix
        color: Theme.textDim
        font.features: { "tnum": 1 }
    }

    Slide {
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 210
        implicitHeight: 28
        width: implicitWidth
        height: implicitHeight
        value: (root.value - root.from) / (root.to - root.from)
        step: root.step / (root.to - root.from)
        onMoved: v => {
            const raw = root.from + v * (root.to - root.from);
            const snapped = Math.round(raw / root.step) * root.step;
            root.moved(Math.min(root.to, Math.max(root.from, parseFloat(snapped.toFixed(4)))));
        }
    }
}
