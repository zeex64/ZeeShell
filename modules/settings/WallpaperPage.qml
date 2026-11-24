import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

Column {
    spacing: 12

    Group {
        title: "Library"

        TextOpt {
            label: "Folder"
            hint: "Leave empty for ~/Pictures/Wallpapers. Downloads land here too."
            placeholder: Wallpapers.dir
            value: Config.wallpaper.directory
            onEdited: v => Config.wallpaper.directory = v.trim().replace(/^~/, Config.home).replace(/\/+$/, "")
        }

        Opt {
            label: "Browse"
            hint: Wallpapers.local.length + " images found"
            Btn { text: "Random"; icon: "shuffle"; kind: "ghost"; onClicked: Wallpapers.random() }
            Btn { text: "Open picker"; icon: "image"; onClicked: Ui.show("wallpaper") }
        }
    }

    Group {
        title: "Transition"

        ChoiceOpt {
            label: "Effect"
            options: [["circle", "Iris"], ["wipe", "Wipe"], ["fade", "Fade"]]
            current: Config.wallpaper.transition
            onPicked: k => Config.wallpaper.transition = k
        }

        SliderOpt {
            label: "Duration"
            from: 200; to: 2500; step: 100; decimals: 0; suffix: " ms"
            value: Config.wallpaper.transitionMs
            onMoved: v => Config.wallpaper.transitionMs = v
        }
    }

    Group {
        title: "wallhaven.cc"

        ToggleOpt {
            label: "Only wallpapers that fit my largest screen"
            checked: Config.wallpaper.havenMatchScreen
            onToggled: v => Config.wallpaper.havenMatchScreen = v
        }

        ToggleOpt {
            label: "Include “sketchy” results"
            hint: "Off keeps results safe-for-work only"
            checked: Config.wallpaper.havenSketchy
            onToggled: v => Config.wallpaper.havenSketchy = v
        }

        TextOpt {
            label: "API key"
            hint: "Optional. Stored in plain text in config.json; sent only to wallhaven.cc"
            secret: true
            placeholder: "Not set"
            value: Config.wallpaper.havenKey
            onEdited: v => Config.wallpaper.havenKey = v.trim()
        }
    }
}
