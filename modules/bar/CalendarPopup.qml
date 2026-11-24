import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// Opens under the clock: today, the month, and the forecast.
Overlay {
    id: ov

    open: Ui.active === "calendar"
    layerName: "calendar"
    enterMs: 380
    exitMs: 180
    onDismiss: Ui.hide()

    Item {
        id: root

        readonly property Item panel: sheet
        readonly property bool atTop: Config.bar.position === "top"
        readonly property real edge: Config.bar.height + (Config.bar.floating ? Config.bar.margin : 0) + 8

        Panel {
            id: sheet

            width: 380
            height: col.implicitHeight + 28
            x: Math.max(8, Math.min(root.width - width - 8, Ui.menuX - width / 2))
            y: root.atTop ? root.edge - (1 - ov.progress) * 16 : root.height - root.edge - height + (1 - ov.progress) * 16
            opacity: ov.progress
            scale: 0.94 + 0.06 * ov.progress
            transformOrigin: root.atTop ? Item.Top : Item.Bottom

            Column {
                id: col
                x: 14
                y: 14
                width: parent.width - 28
                spacing: 10

                Item {
                    width: parent.width
                    height: 58

                    Txt {
                        x: 6
                        text: Time.time + (Time.ampm !== "" ? " " + Time.ampm : "")
                        size: 34
                        font.weight: Font.Bold
                        font.letterSpacing: -1
                        font.features: { "tnum": 1 }
                    }

                    Txt {
                        x: 6
                        anchors.bottom: parent.bottom
                        text: Time.longDate + "  ·  week " + Time.week
                        color: Theme.textDim
                        font.weight: Font.Medium
                    }
                }

                CalendarCard { width: parent.width }
                WeatherCard { width: parent.width; visible: Config.clock.showWeather }
            }
        }
    }
}
