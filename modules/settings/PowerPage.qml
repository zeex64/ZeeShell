import Quickshell
import Quickshell.Services.UPower
import QtQuick
import qs.config
import qs.components
import qs.services

// Power mode, battery, and what the computer does when left alone.
Column {
    id: page

    readonly property var waits: [[0, "Never", ""], [1, "1 minute", ""], [2, "2 minutes", ""], [5, "5 minutes", ""], [10, "10 minutes", ""],
        [15, "15 minutes", ""], [30, "30 minutes", ""], [60, "1 hour", ""], [120, "2 hours", ""]]

    spacing: 12

    Group {
        title: "Power mode"

        ChoiceOpt {
            visible: Power.profiles
            label: "Mode"
            hint: "Power saver runs cooler and quieter; performance lets the hardware run flat out"
            options: Power.hasPerformance
                ? [[PowerProfile.PowerSaver, "Power saver"], [PowerProfile.Balanced, "Balanced"], [PowerProfile.Performance, "Performance"]]
                : [[PowerProfile.PowerSaver, "Power saver"], [PowerProfile.Balanced, "Balanced"]]
            current: Power.profile
            onPicked: k => Power.setProfile(k)
        }

        Opt {
            visible: !Power.profiles
            label: "Power modes are not available"
            hint: "They need power-profiles-daemon (or tuned-ppd) to be installed and running"
        }
    }

    Group {
        visible: Power.hasBattery
        title: "Battery"

        Opt {
            label: Power.charging ? "Charging" : "On battery"
            hint: Power.batteryText

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 210
                height: 10
                radius: 5
                color: Theme.layerHi

                Rectangle {
                    width: parent.width * Power.percent
                    height: parent.height
                    radius: 5
                    color: Power.percent < 0.15 && !Power.charging ? Theme.danger : Theme.accent
                }
            }
        }

        InfoOpt {
            visible: Power.hasBattery && Power.battery.healthSupported
            label: "Battery health"
            value: Power.hasBattery ? Math.round(Power.battery.healthPercentage) + "%" : ""
        }
    }

    Group {
        title: "When left alone"

        SelectOpt {
            label: "Turn the screens off after"
            options: page.waits
            current: Config.power.screenOffMin
            onPicked: k => Config.power.screenOffMin = k
        }

        SelectOpt {
            label: "Lock after"
            options: page.waits
            current: Config.power.lockMin
            onPicked: k => Config.power.lockMin = k
        }

        SelectOpt {
            label: "Sleep after"
            hint: "The session is locked first"
            options: page.waits
            current: Config.power.suspendMin
            onPicked: k => Config.power.suspendMin = k
        }

        ToggleOpt {
            label: "Stay awake"
            hint: "Holds all three back until you turn it off. Apps playing video do the same on their own."
            checked: Toggles.caffeine
            onToggled: v => Toggles.caffeine = v
        }
    }

    Group {
        title: "Right now"

        Opt {
            label: "Session"

            Btn { text: "Lock"; icon: "lock"; kind: "ghost"; onClicked: { Ui.settingsOpen = false; Ui.locked = true; } }
            Btn { text: "Sleep"; icon: "moon"; kind: "ghost"; onClicked: Power.suspend() }
            Btn { text: "Power menu"; icon: "power"; onClicked: { Ui.settingsOpen = false; Ui.show("power"); } }
        }
    }
}
