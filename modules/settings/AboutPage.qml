import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// What this computer is, and what it runs.
Column {
    id: page

    property bool copied: false

    spacing: 12
    Component.onCompleted: Device.refresh()

    Group {
        title: "This computer"

        Opt {
            label: "Device name"
            hint: Device.message !== "" ? Device.message : "How this computer appears on the network. Changing it asks for permission."

            Field {
                id: name
                width: 220
                implicitHeight: 36
                placeholder: Device.host
                onAccepted: { Device.rename(text); text = ""; }
            }

            Btn { text: "Rename"; kind: "ghost"; onClicked: { if (name.text.trim() !== "") { Device.rename(name.text); name.text = ""; } } }
        }

        InfoOpt { visible: Device.model !== ""; label: "Model"; value: Device.model }
        InfoOpt { visible: Device.cpu !== ""; label: "Processor"; value: Device.cpu }
        InfoOpt { visible: Device.gpu !== ""; label: "Graphics"; value: Device.gpu }
        InfoOpt { label: "Memory"; value: SysInfo.gib(SysInfo.memTotal) + " GiB" }
    }

    Group {
        title: "Software"

        InfoOpt { label: "System"; value: Device.os }
        InfoOpt { label: "Kernel"; value: Device.kernel }
        InfoOpt { label: "Desktop"; value: Device.hyprland }
        InfoOpt { label: "Shell"; value: "ZeeShell " + Device.version }
        InfoOpt { label: "Toolkit"; value: Device.quickshell }
        InfoOpt { label: "Running for"; value: SysInfo.uptimeText() }

        Opt {
            label: "Share these details"
            hint: "Handy when asking for help or reporting a problem"

            Btn {
                text: page.copied ? "Copied" : "Copy"
                icon: page.copied ? "check" : "copy"
                onClicked: { Device.copy(Device.summary); page.copied = true; uncopy.restart(); }
            }
        }
    }

    Group {
        title: "ZeeShell"

        Opt {
            label: "Project page"
            hint: "Source code, help and issue reports"
            Btn { text: "Open"; icon: "arrow-square-out"; kind: "ghost"; onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/zeex64/ZeeShell"]) }
        }

        Opt {
            label: "Keybinding cheat sheet"
            Btn { text: "Show"; icon: "keyboard"; kind: "ghost"; onClicked: { Ui.settingsOpen = false; Ui.show("keybinds"); } }
        }
    }

    Timer { id: uncopy; interval: 2000; onTriggered: page.copied = false }
}
