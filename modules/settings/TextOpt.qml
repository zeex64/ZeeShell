import QtQuick
import qs.components

Opt {
    id: root

    property string value: ""
    property string placeholder: ""
    property bool secret: false
    property real fieldWidth: 280

    signal edited(string value)

    Field {
        id: field
        width: root.fieldWidth
        implicitHeight: 36
        password: root.secret
        placeholder: root.placeholder
        Component.onCompleted: text = root.value
        onAccepted: root.edited(text)
        onEditingDone: root.edited(text)
    }
}
