import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// Keyboard layout and typing. Values come from Hyprland; anything changed
// here is kept by ZeeShell and applied on top of your Hyprland config.
Column {
    id: page

    readonly property string layouts: String(Input.value("kb_layout", "us"))
    readonly property string first: layouts.split(",")[0].trim()
    readonly property string variant: String(Input.value("kb_variant", "")).split(",")[0].trim()

    spacing: 12
    Component.onCompleted: Input.refresh()

    Group {
        title: "Layout"

        SelectOpt {
            label: "Keyboard layout"
            searchable: true
            options: Input.layouts.map(l => [l[0], l[1], l[0]])
            current: page.first
            onPicked: k => { Input.set("kb_layout", k); Input.set("kb_variant", ""); }
        }

        SelectOpt {
            visible: (Input.variants[page.first] || []).length > 0
            label: "Variant"
            searchable: (Input.variants[page.first] || []).length > 8
            options: [["", "Standard", ""]].concat((Input.variants[page.first] || []).map(v => [v[0], v[1], v[0]]))
            current: page.variant
            onPicked: k => Input.set("kb_variant", k)
        }

        TextOpt {
            label: "Several layouts"
            hint: "Codes separated by commas, for example us,de. Add a switching shortcut under Options."
            fieldWidth: 250
            value: page.layouts
            onEdited: v => { const t = v.replace(/\s+/g, ""); if (t !== "" && t !== page.layouts) Input.set("kb_layout", t); }
        }

        TextOpt {
            label: "Options"
            hint: "XKB options, for example caps:escape or grp:alt_shift_toggle"
            fieldWidth: 250
            placeholder: "None"
            value: String(Input.value("kb_options", ""))
            onEdited: v => { const t = v.trim(); if (t !== String(Input.value("kb_options", ""))) Input.set("kb_options", t); }
        }
    }

    Group {
        title: "Typing"

        SliderOpt {
            label: "Repeat speed"
            hint: "How fast a held key repeats"
            from: 10; to: 80; step: 1; decimals: 0; suffix: " /s"
            value: Number(Input.value("repeat_rate", 25))
            onMoved: v => Input.set("repeat_rate", v)
        }

        SliderOpt {
            label: "Delay before repeating"
            from: 150; to: 1000; step: 10; decimals: 0; suffix: " ms"
            value: Number(Input.value("repeat_delay", 600))
            onMoved: v => Input.set("repeat_delay", v)
        }

        ToggleOpt {
            label: "Num Lock on at login"
            checked: !!Input.value("numlock_by_default", false)
            onToggled: v => Input.set("numlock_by_default", v)
        }
    }

    Group {
        title: "Shortcuts"

        Opt {
            label: "Keybinds"
            hint: "Every key combination, with an editor to change them"
            Btn { text: "Open keybinds"; icon: "keyboard"; onClicked: Ui.settingsPage = "shortcuts" }
        }
    }

    Group {
        visible: Input.managed
        title: "Saved changes"

        Opt {
            label: "ZeeShell applies " + Object.keys(Config.input.overrides).length + (Object.keys(Config.input.overrides).length === 1 ? " input setting" : " input settings")
            hint: "Keyboard, mouse and touchpad settings changed here sit on top of your Hyprland config. Hand them back to return to what it says."
            Btn { text: "Hand back"; icon: "arrow-counter-clockwise"; kind: "ghost"; onClicked: Input.forgetAll() }
        }
    }
}
