import QtQuick
import qs.components

Opt {
    id: root

    property bool checked: false
    signal toggled(bool value)

    Toggle {
        checked: root.checked
        onToggled: v => root.toggled(v)
    }
}
