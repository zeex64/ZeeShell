import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

Column {
    spacing: 12

    Group {
        title: "Workspaces"

        SliderOpt {
            label: "Shown workspaces"
            hint: "Occupied workspaces beyond this still appear"
            from: 1; to: 10; step: 1; decimals: 0
            value: Config.workspaces.count
            onMoved: v => Config.workspaces.count = v
        }

        ChoiceOpt {
            label: "Style"
            options: [["dots", "Dots"], ["numbers", "Numbers"], ["apps", "App icons"]]
            current: Config.workspaces.style
            onPicked: k => Config.workspaces.style = k
        }

        ToggleOpt {
            label: "Per-monitor highlight"
            hint: "Each bar highlights the workspace on its own monitor"
            checked: Config.workspaces.perMonitor
            onToggled: v => Config.workspaces.perMonitor = v
        }
    }

    Group {
        title: "App tray"

        ToggleOpt {
            label: "Collapse behind an arrow"
            hint: "Keeps tray icons out of the bar; click the arrow to see them"
            checked: Config.tray.collapsed
            onToggled: v => Config.tray.collapsed = v
        }
    }

    Group {
        title: "App drawer"

        ChoiceOpt {
            label: "Position"
            hint: "Centre of the screen, a panel down the left side, or a start menu at the bottom with an A–Z list and pinned apps"
            options: [["center", "Centre"], ["side", "Side panel"], ["bottom-left", "Bottom left"], ["bottom-center", "Bottom centre"]]
            current: Config.launcher.position
            onPicked: k => Config.launcher.position = k
        }

        SliderOpt {
            label: "Columns"
            from: 4; to: 9; step: 1; decimals: 0
            value: Config.launcher.columns
            onMoved: v => Config.launcher.columns = v
        }

        ToggleOpt { label: "Category chips"; checked: Config.launcher.showCategories; onToggled: v => Config.launcher.showCategories = v }
    }

    Group {
        title: "Quick settings"

        ChoiceOpt {
            label: "Side"
            options: [["left", "Left"], ["right", "Right"]]
            current: Config.sidebar.side
            onPicked: k => Config.sidebar.side = k
        }

        SliderOpt {
            label: "Width"
            from: 360; to: 520; step: 10; decimals: 0; suffix: " px"
            value: Config.sidebar.width
            onMoved: v => Config.sidebar.width = v
        }
    }
}
