import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// Settings for the apps that ship with the shell.
Column {
    spacing: 12

    Timer { id: refresh; interval: 900; onTriggered: DefaultApps.refresh() }

    Group {
        title: "Files"

        ToggleOpt {
            label: "Open folders with ZeeShell Files"
            hint: "Makes the built-in explorer your default file manager. Off hands folders back to the one you had."
            checked: Config.files.handleFolders
            onToggled: v => { Config.files.handleFolders = v; Files.useAsDefault(v); refresh.restart(); }
        }

        ToggleOpt {
            label: "Show hidden files"
            checked: Config.files.showHidden
            onToggled: v => Config.files.showHidden = v
        }

        Opt {
            label: "Explorer"
            hint: "Also on the start rail, in the app drawer, and as: zeeshell files"
            Btn { text: "Open Files"; icon: "folder"; onClicked: Quickshell.execDetached([Quickshell.shellPath("zeeshell"), "files"]) }
        }
    }

    Group {
        title: "Steam workspace"

        ToggleOpt {
            label: "Keep Steam in its own workspace"
            hint: "Steam's windows stay in a hidden workspace that Super + G drops over the desktop. Off returns Steam to normal windows."
            checked: Config.steam.enabled
            onToggled: v => Config.steam.enabled = v
        }

        ToggleOpt {
            visible: Config.steam.enabled
            label: "Start Steam at login"
            checked: Config.steam.autostart
            onToggled: v => Config.steam.autostart = v
        }

        SliderOpt {
            visible: Config.steam.enabled
            label: "Width on wide monitors"
            from: 50; to: 100; step: 2; decimals: 0; suffix: "%"
            value: Config.steam.fill * 100
            onMoved: v => Config.steam.fill = v / 100
        }

        SliderOpt {
            visible: Config.steam.enabled
            label: "Friends List column"
            from: 15; to: 50; step: 1; decimals: 0; suffix: "%"
            value: Config.steam.friends * 100
            onMoved: v => Config.steam.friends = v / 100
        }
    }

    Group {
        title: "Clipboard history"

        ToggleOpt {
            label: "Keep a clipboard history"
            hint: !Clipboard.available ? "Needs cliphist and wl-clipboard to be installed"
                : Clipboard.watcherFound ? "Something else (likely your Hyprland config) already records the clipboard, so this switch has no effect"
                : "Everything you copy is kept by cliphist, so you can paste it again later"
            checked: Config.clipboard.enabled
            onToggled: v => Config.clipboard.enabled = v
        }

        Opt {
            label: "History"
            hint: "Opens with its keybind, the Clipboard tile in quick settings, or /clipboard in the app drawer"

            Btn { text: "Open"; icon: "clipboard-text"; kind: "ghost"; onClicked: { Ui.settingsOpen = false; Ui.show("clipboard"); } }
            Btn { text: "Clear"; icon: "broom"; kind: "danger"; onClicked: Clipboard.wipe() }
        }
    }
}
