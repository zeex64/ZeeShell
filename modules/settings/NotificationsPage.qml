import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

Column {
    spacing: 12

    Group {
        title: "Popups"

        ChoiceOpt {
            label: "Show on"
            hint: "A fixed monitor, or whichever one you are working on"
            options: [["", "Focused monitor"]].concat(Quickshell.screens.map(s => [s.name, s.name]))
            current: Quickshell.screens.some(s => s.name === Config.notifications.monitor) ? Config.notifications.monitor : ""
            onPicked: k => Config.notifications.monitor = k
        }

        ChoiceOpt {
            label: "Position"
            options: [["top-left", "Top left"], ["top-center", "Top"], ["top-right", "Top right"], ["bottom-left", "Bottom left"], ["bottom-right", "Bottom right"]]
            current: Config.notifications.position
            onPicked: k => Config.notifications.position = k
        }

        SliderOpt {
            label: "Stay on screen"
            from: 2; to: 20; step: 1; decimals: 0; suffix: " s"
            value: Config.notifications.timeout / 1000
            onMoved: v => Config.notifications.timeout = v * 1000
        }

        SliderOpt {
            label: "Maximum at once"
            from: 1; to: 8; step: 1; decimals: 0
            value: Config.notifications.maxPopups
            onMoved: v => Config.notifications.maxPopups = v
        }

        ToggleOpt {
            label: "Do not disturb"
            hint: "Critical notifications still appear"
            checked: Config.notifications.dnd
            onToggled: v => Config.notifications.dnd = v
        }

        Opt {
            label: "Preview"
            Btn { text: "Send a test"; icon: "paper-plane-tilt"; onClicked: Notifs.test() }
        }
    }

    Group {
        title: "Volume & brightness indicator"

        ToggleOpt { label: "Show indicator"; checked: Config.osd.enabled; onToggled: v => Config.osd.enabled = v }

        ChoiceOpt {
            label: "Position"
            options: [["top", "Top"], ["bottom", "Bottom"]]
            current: Config.osd.position
            onPicked: k => Config.osd.position = k
        }
    }
}
