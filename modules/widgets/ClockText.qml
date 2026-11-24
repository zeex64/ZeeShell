import QtQuick
import qs.components
import qs.services

// The clock widget's two lines of text. Drawn twice: once blurred and dark as
// the shadow, once on top as the real text.
Column {
    id: root

    property color ink: "white"
    property color soft: Qt.rgba(1, 1, 1, 0.88)

    spacing: -6

    Txt {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Time.time
        size: 104
        font.weight: Font.Bold
        font.letterSpacing: -3
        font.features: { "tnum": 1 }
        color: root.ink
    }

    Txt {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Time.longDate
        size: 20
        font.weight: Font.Medium
        color: root.soft
        bottomPadding: 8
    }
}
