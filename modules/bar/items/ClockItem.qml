import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.bar

// Time, date and (optionally) the weather in one pill. Opens the calendar.
BarItem {
    id: root

    pad: 14
    spacing: 8
    active: Ui.active === "calendar"
    onClicked: Ui.popup("calendar", mapToItem(null, width / 2, 0).x, screen)
    onRightClicked: Weather.refresh()

    Txt {
        anchors.verticalCenter: parent.verticalCenter
        text: Time.time + (Time.ampm !== "" ? " " + Time.ampm : "")
        size: 13.5
        font.weight: Font.Bold
        font.features: { "tnum": 1 }
    }

    Rectangle {
        visible: Config.clock.showDate
        anchors.verticalCenter: parent.verticalCenter
        width: 4
        height: 4
        radius: 2
        color: Theme.accent
    }

    Txt {
        visible: Config.clock.showDate
        anchors.verticalCenter: parent.verticalCenter
        text: Time.date
        color: Theme.textDim
        font.weight: Font.Medium
    }

    Rectangle {
        visible: Config.clock.showWeather
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: 14
        color: Theme.outlineHi
    }

    Icon {
        visible: Config.clock.showWeather
        anchors.verticalCenter: parent.verticalCenter
        name: Weather.icon
        fill: true
        size: 16
        color: Theme.accent
    }

    Txt {
        visible: Config.clock.showWeather
        anchors.verticalCenter: parent.verticalCenter
        text: Weather.tempText
        font.weight: Font.DemiBold
    }
}
