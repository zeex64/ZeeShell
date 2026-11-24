import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

Column {
    spacing: 12

    Group {
        title: "Colour"

        ToggleOpt {
            label: "Dark mode"
            checked: Config.appearance.dark
            onToggled: v => Config.appearance.dark = v
        }

        ToggleOpt {
            label: "Colours from wallpaper"
            hint: "Pick the accent from the current wallpaper"
            checked: Config.appearance.dynamicColors
            onToggled: v => Config.appearance.dynamicColors = v
        }

        Opt {
            label: "Accent"
            hint: Config.appearance.dynamicColors ? "Choosing one turns off wallpaper colours" : ""

            Repeater {
                model: ["#8fb8ff", "#b9a5ff", "#ff9ecb", "#ff9a8f", "#ffc67a", "#e6d96a", "#9fe08a", "#74dcc0", "#7fd3f2", "#c7ccd6"]

                Rectangle {
                    id: dot
                    required property string modelData
                    readonly property bool chosen: !Config.appearance.dynamicColors && Config.appearance.accent === modelData

                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 26
                    radius: 13
                    color: modelData
                    border.width: chosen ? 3 : 0
                    border.color: Theme.text
                    scale: pick.pressed ? 0.85 : pick.containsMouse ? 1.15 : 1

                    Behavior on scale { Anim { ms: 280; curve: Theme.curve.spring } }

                    MouseArea {
                        id: pick
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { Config.appearance.accent = dot.modelData; Config.appearance.dynamicColors = false; }
                    }
                }
            }
        }
    }

    Group {
        title: "Surfaces"

        SliderOpt {
            label: "Corner rounding"
            from: 0; to: 1.6; step: 0.05
            value: Config.appearance.rounding
            onMoved: v => Config.appearance.rounding = v
        }

        SliderOpt {
            label: "Panel opacity"
            from: 0.3; to: 1; step: 0.02
            value: Config.appearance.opacity
            onMoved: v => Config.appearance.opacity = v
        }

        ToggleOpt {
            label: "Background blur"
            hint: "Frosted glass behind panels"
            checked: Config.appearance.blur
            onToggled: v => Config.appearance.blur = v
        }

        ToggleOpt {
            label: "Borders"
            checked: Config.appearance.borders
            onToggled: v => Config.appearance.borders = v
        }

        ToggleOpt {
            label: "Shadows"
            checked: Config.appearance.shadows
            onToggled: v => Config.appearance.shadows = v
        }

        ToggleOpt {
            label: "Rounded screen corners"
            hint: "Softens the corners of every monitor; steps aside for fullscreen windows"
            checked: Config.appearance.screenCorners
            onToggled: v => Config.appearance.screenCorners = v
        }

        SliderOpt {
            visible: Config.appearance.screenCorners
            label: "Screen corner size"
            from: 4; to: 48; step: 1; decimals: 0; suffix: " px"
            value: Config.appearance.screenRadius
            onMoved: v => Config.appearance.screenRadius = v
        }
    }

    Group {
        title: "Other apps"

        ToggleOpt {
            label: "Colour KDE apps to match"
            hint: "Dolphin, Kate and other KDE apps follow the shell's colours, including wallpaper colours. Off puts your previous colour scheme back."
            checked: Config.apps.kde
            onToggled: v => Config.apps.kde = v
        }

        ToggleOpt {
            label: "Colour kitty and foot to match"
            hint: "Rewrites the terminal themes the installer hooked up; kitty updates at once, foot in new windows"
            checked: Config.apps.terminal
            onToggled: v => Config.apps.terminal = v
        }

        ToggleOpt {
            label: "Keep a matching Vesktop theme"
            hint: "Writes “ZeeShell” into Vesktop's themes; turn it on once in Vesktop → Settings → Themes"
            checked: Config.apps.vesktop
            onToggled: v => Config.apps.vesktop = v
        }

        ToggleOpt {
            visible: Config.apps.vesktop
            label: "See-through Vesktop window"
            hint: AppThemes.vesktopGlass ? "Glass like Settings and Files, with the desktop showing through"
                : "Glass like Settings and Files. Off, or until Vesktop allows it, the same theme is drawn solid."
            checked: Config.apps.vesktopGlass
            onToggled: v => Config.apps.vesktopGlass = v
        }

        Opt {
            visible: Config.apps.vesktop && Config.apps.vesktopGlass && AppThemes.vesktopFound && !AppThemes.vesktopClear
            label: "Vesktop's window transparency is off"
            hint: AppThemes.vesktopBusy ? "Restarting Vesktop…" : "It has to be on for the desktop to show through. This switches it on in Vesktop's settings and restarts Vesktop."

            Btn {
                visible: !AppThemes.vesktopBusy
                text: "Turn on and restart"
                icon: "arrows-clockwise"
                kind: "filled"
                onClicked: AppThemes.makeVesktopClear()
            }
        }
    }

    Group {
        title: "Windows"

        ToggleOpt {
            label: "Style app windows to match"
            hint: "Sets Hyprland's rounding, gaps, border and shadow from this theme"
            checked: Config.windows.enabled
            onToggled: v => Config.windows.enabled = v
        }

        SliderOpt {
            label: "Window rounding"
            hint: "Also follows Corner rounding above"
            from: 0; to: 28; step: 1; decimals: 0; suffix: " px"
            value: Config.windows.rounding
            onMoved: v => Config.windows.rounding = v
        }

        SliderOpt {
            label: "Border"
            from: 0; to: 6; step: 1; decimals: 0; suffix: " px"
            value: Config.windows.borderSize
            onMoved: v => Config.windows.borderSize = v
        }

        ToggleOpt {
            label: "Accent-coloured border on the focused window"
            checked: Config.windows.accentBorder
            onToggled: v => Config.windows.accentBorder = v
        }

        SliderOpt {
            label: "Gap between windows"
            from: 0; to: 16; step: 1; decimals: 0; suffix: " px"
            value: Config.windows.gapsIn * 2
            onMoved: v => Config.windows.gapsIn = Math.round(v / 2)
        }

        SliderOpt {
            label: "Gap to screen edge"
            from: 0; to: 32; step: 1; decimals: 0; suffix: " px"
            value: Config.windows.gapsOut
            onMoved: v => Config.windows.gapsOut = v
        }

        ToggleOpt {
            label: "Window shadows"
            checked: Config.windows.shadows
            onToggled: v => Config.windows.shadows = v
        }
    }

    Group {
        title: "Motion & type"

        ChoiceOpt {
            label: "Animation speed"
            options: [[0.6, "Relaxed"], [1, "Normal"], [1.6, "Snappy"], [20, "Off"]]
            current: Config.appearance.animSpeed
            onPicked: k => Config.appearance.animSpeed = k
        }

        SliderOpt {
            label: "Text size"
            from: 0.85; to: 1.3; step: 0.05
            value: Config.appearance.fontScale
            onMoved: v => Config.appearance.fontScale = v
        }

        TextOpt {
            label: "Font"
            hint: "Any installed family"
            value: Config.appearance.font
            onEdited: v => { if (v.trim() !== "") Config.appearance.font = v.trim(); }
        }
    }
}
