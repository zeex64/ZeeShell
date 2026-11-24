import QtQuick
import QtQuick.Effects
import qs.config
import qs.components
import qs.services

// One desktop widget, picked by type. Shared by the desktop layer, the
// layout editor and the editor's tray previews.
Loader {
    id: root

    property string type: ""
    property real zoom: 1
    readonly property bool isWidgetBody: true // Txt and Icon look for this to switch to curve rendering
    readonly property color glass: Theme.alpha(Theme.bg, Math.min(0.86, Theme.panelAlpha + 0.06))

    scale: zoom
    transformOrigin: Item.TopLeft
    sourceComponent: type === "clock" ? clock : type === "weather" ? weather : type === "system" ? system
        : type === "media" ? media : type === "calendar" ? calendar : null

    Component {
        id: clock

        Item {
            implicitWidth: face.implicitWidth
            implicitHeight: face.implicitHeight

            // Only the shadow goes through a (blurred) layer. The text itself is
            // drawn directly, so it stays vector-sharp at any zoom.
            ClockText {
                y: 5
                ink: "black"
                soft: "black"
                opacity: 0.6
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 1
                    blurMax: 30
                    autoPaddingEnabled: true
                }
            }

            ClockText { id: face }
        }
    }

    Component { id: weather; WeatherCard { color: root.glass } }
    Component { id: system; SystemCard { color: root.glass } }
    Component { id: media; MediaCard { color: root.glass } }
    Component { id: calendar; CalendarCard { width: 340; color: root.glass } }
}
