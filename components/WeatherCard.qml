import QtQuick
import qs.config
import qs.services

Card {
    id: root

    property int hours: 6

    implicitWidth: 380
    implicitHeight: 152

    Icon {
        id: glyph
        x: 18
        y: 16
        name: Weather.icon
        fill: true
        size: 46
        color: Theme.accent
    }

    Txt {
        id: temp
        anchors.left: glyph.right
        anchors.leftMargin: 12
        anchors.verticalCenter: glyph.verticalCenter
        text: Weather.tempText
        size: 34
        font.weight: Font.Bold
    }

    Column {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: glyph.verticalCenter
        spacing: 2

        Txt {
            anchors.right: parent.right
            text: Weather.ready ? Weather.description : (Weather.error || "Loading…")
            font.weight: Font.DemiBold
        }

        Txt {
            anchors.right: parent.right
            text: Weather.city
            color: Theme.textDim
            size: 12
            visible: text !== ""
        }

        Txt {
            anchors.right: parent.right
            text: "Feels " + Math.round(Weather.feels) + "°  ·  " + Weather.humidity + "%  ·  " + Math.round(Weather.wind) + (Config.weather.fahrenheit ? " mph" : " km/h")
            color: Theme.textMute
            size: 11.5
            visible: Weather.ready
        }
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        Repeater {
            model: Weather.hourly.slice(0, root.hours)

            Column {
                required property var modelData
                width: parent.width / root.hours
                spacing: 3

                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: Time.hourLabel(modelData.hour); size: 10.5; color: Theme.textMute }
                Icon { anchors.horizontalCenter: parent.horizontalCenter; name: Weather.iconFor(modelData.code, true); size: 17; color: Theme.textDim }
                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.temp + "°"; size: 12; font.weight: Font.DemiBold }
            }
        }
    }
}
