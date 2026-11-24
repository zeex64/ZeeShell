import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

Column {
    spacing: 12

    Group {
        title: "Placement"

        ChoiceOpt {
            label: "Position"
            options: [["top", "Top"], ["bottom", "Bottom"]]
            current: Config.bar.position
            onPicked: k => Config.bar.position = k
        }

        ChoiceOpt {
            label: "Show on"
            hint: "Which monitor gets the bar"
            options: [["", "All monitors"]].concat(Quickshell.screens.map(s => [s.name, s.name]))
            current: Quickshell.screens.some(s => s.name === Config.bar.monitor) ? Config.bar.monitor : ""
            onPicked: k => Config.bar.monitor = k
        }

        ChoiceOpt {
            label: "Style"
            hint: "Islands group modules; pills separate each one; solid is one strip"
            options: [["islands", "Islands"], ["pills", "Pills"], ["solid", "Solid"]]
            current: Config.bar.style
            onPicked: k => Config.bar.style = k
        }

        ToggleOpt {
            label: "Floating"
            hint: "Leave a gap between the bar and the screen edge"
            checked: Config.bar.floating
            onToggled: v => Config.bar.floating = v
        }

        SliderOpt {
            label: "Height"
            from: 32; to: 60; step: 1; decimals: 0; suffix: " px"
            value: Config.bar.height
            onMoved: v => Config.bar.height = v
        }

        SliderOpt {
            visible: Config.bar.floating
            label: "Edge gap"
            from: 0; to: 24; step: 1; decimals: 0; suffix: " px"
            value: Config.bar.margin
            onMoved: v => Config.bar.margin = v
        }
    }

    Group {
        title: "Modules"
        BarLayout { topPadding: 4; bottomPadding: 8 }
    }
}
