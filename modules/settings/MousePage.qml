import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// Mouse and touchpad.
Column {
    spacing: 12
    Component.onCompleted: Input.refresh()

    Group {
        title: "Mouse"

        SliderOpt {
            label: "Pointer speed"
            from: -1; to: 1; step: 0.05
            value: Number(Input.value("sensitivity", 0))
            onMoved: v => Input.set("sensitivity", v)
        }

        ChoiceOpt {
            label: "Acceleration"
            hint: "Flat moves the pointer exactly as far as the mouse; adaptive speeds up with fast movements"
            options: [["", "Device default"], ["flat", "Flat"], ["adaptive", "Adaptive"]]
            current: String(Input.value("accel_profile", ""))
            onPicked: k => Input.set("accel_profile", k)
        }

        SliderOpt {
            label: "Scroll speed"
            from: 0.2; to: 3; step: 0.1; decimals: 1; suffix: "×"
            value: Number(Input.value("scroll_factor", 1))
            onMoved: v => Input.set("scroll_factor", v)
        }

        ToggleOpt {
            label: "Natural scrolling"
            hint: "Content follows your fingers, as on a phone"
            checked: !!Input.value("natural_scroll", false)
            onToggled: v => Input.set("natural_scroll", v)
        }

        ToggleOpt {
            label: "Left-handed"
            hint: "Swaps the left and right buttons"
            checked: !!Input.value("left_handed", false)
            onToggled: v => Input.set("left_handed", v)
        }

        ToggleOpt {
            label: "Focus the window under the pointer"
            hint: "Off means a window is focused only when you click it"
            checked: Number(Input.value("follow_mouse", 1)) > 0
            onToggled: v => Input.set("follow_mouse", v ? 1 : 0)
        }
    }

    Group {
        title: "Touchpad"

        ToggleOpt {
            label: "Tap to click"
            checked: !!Input.value("touchpad:tap-to-click", true)
            onToggled: v => Input.set("touchpad:tap-to-click", v)
        }

        ToggleOpt {
            label: "Natural scrolling"
            checked: !!Input.value("touchpad:natural_scroll", false)
            onToggled: v => Input.set("touchpad:natural_scroll", v)
        }

        ToggleOpt {
            label: "Ignore the touchpad while typing"
            checked: !!Input.value("touchpad:disable_while_typing", true)
            onToggled: v => Input.set("touchpad:disable_while_typing", v)
        }

        SliderOpt {
            label: "Scroll speed"
            from: 0.2; to: 3; step: 0.1; decimals: 1; suffix: "×"
            value: Number(Input.value("touchpad:scroll_factor", 1))
            onMoved: v => Input.set("touchpad:scroll_factor", v)
        }
    }

    Group {
        visible: Input.managed
        title: "Saved changes"

        Opt {
            label: "ZeeShell applies " + Object.keys(Config.input.overrides).length + (Object.keys(Config.input.overrides).length === 1 ? " input setting" : " input settings")
            hint: "They sit on top of your Hyprland config. Hand them back to return to what it says."
            Btn { text: "Hand back"; icon: "arrow-counter-clockwise"; kind: "ghost"; onClicked: Input.forgetAll() }
        }
    }
}
