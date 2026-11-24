import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

Column {
    id: page
    property var found: []
    spacing: 12

    Group {
        title: "Now"
        WeatherCard { width: parent.width; color: "transparent"; border.width: 0 }
    }

    Group {
        title: "Location"

        ToggleOpt {
            label: "Detect automatically"
            hint: "Looks up an approximate location from your public IP address (geojs.io)"
            checked: Config.weather.autoLocate
            onToggled: v => Config.weather.autoLocate = v
        }

        Opt {
            label: "City"
            hint: Config.weather.city !== "" && !Config.weather.autoLocate ? "Using " + Config.weather.city : "Search to pin a place"

            Field {
                id: city
                width: 280
                implicitHeight: 36
                icon: "map-pin"
                placeholder: "Search a city"
                onAccepted: Weather.search(text, r => page.found = r)
            }
        }

        Repeater {
            model: page.found

            Item {
                id: hit
                required property var modelData
                width: parent.width
                height: 42

                Row {
                    x: 4
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "map-pin"; size: 16; color: Theme.accent }
                    Txt { anchors.verticalCenter: parent.verticalCenter; text: hit.modelData.name; font.weight: Font.DemiBold }
                    Txt { anchors.verticalCenter: parent.verticalCenter; text: hit.modelData.detail; color: Theme.textMute }
                }

                StateLayer {
                    radius: Theme.radius.sm
                    onClicked: { Weather.setCity(hit.modelData); page.found = []; city.text = ""; }
                }
            }
        }
    }

    Group {
        title: "Display"

        ChoiceOpt {
            label: "Units"
            options: [[false, "Celsius"], [true, "Fahrenheit"]]
            current: Config.weather.fahrenheit
            onPicked: k => Config.weather.fahrenheit = k
        }

        SliderOpt {
            label: "Refresh every"
            from: 10; to: 120; step: 10; decimals: 0; suffix: " min"
            value: Config.weather.refreshMinutes
            onMoved: v => Config.weather.refreshMinutes = v
        }
    }
}
