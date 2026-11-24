import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

Column {
    spacing: 12

    Group {
        title: "Lock screen"

        ToggleOpt { label: "Blur the wallpaper"; checked: Config.lock.blurWallpaper; onToggled: v => Config.lock.blurWallpaper = v }
        ToggleOpt { label: "Show weather"; checked: Config.lock.showWeather; onToggled: v => Config.lock.showWeather = v }
        ToggleOpt { label: "Show media controls"; checked: Config.lock.showMedia; onToggled: v => Config.lock.showMedia = v }

        Opt {
            label: "Try it"
            hint: "Preview shows the screen without locking the session"
            Btn { text: "Preview"; icon: "eye"; kind: "ghost"; onClicked: Ui.show("lockpreview") }
            Btn { text: "Lock now"; icon: "lock"; onClicked: { Ui.settingsOpen = false; Ui.locked = true; } }
        }
    }

    Group {
        title: "Startup"

        ToggleOpt {
            label: "Startup animation"
            hint: "Plays when the shell launches"
            checked: Config.startup.animation
            onToggled: v => Config.startup.animation = v
        }
    }
}
