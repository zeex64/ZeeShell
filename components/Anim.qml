import QtQuick
import qs.config

NumberAnimation {
    property int ms: 320
    property list<real> curve: Theme.curve.standard

    duration: Theme.dur(ms)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: curve
}
