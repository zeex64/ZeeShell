import QtQuick

Opt {
    id: root

    property var options: []
    property var current
    signal picked(var key)

    Choice {
        options: root.options
        current: root.current
        onPicked: k => root.picked(k)
    }
}
