import QtQuick
import qs.config

Text {
    property string name: "circle"
    property bool fill: false
    property real size: 18

    text: Ph.get(name)
    color: Theme.text
    font.family: fill ? "Phosphor-Fill" : "Phosphor"
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    // Text inside a desktop widget may be zoomed, so it is drawn as curves
    // (sharp at any scale) instead of being rasterised once and stretched.
    property bool crisp: false
    Component.onCompleted: {
        for (let p = parent; p; p = p.parent) {
            if (p.isWidgetBody === true) { crisp = true; break; }
        }
    }
    renderType: crisp ? Text.CurveRendering : Text.QtRendering
}
