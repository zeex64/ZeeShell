import QtQuick
import qs.config

Text {
    property real size: 13
    property bool mono: false

    color: Theme.text
    font.family: mono ? Theme.mono : Theme.font
    font.pixelSize: Theme.fs(size)
    textFormat: Text.PlainText

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
