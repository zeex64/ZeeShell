import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

Column {
    spacing: 12

    Group {
        title: "Desktop widgets"

        ToggleOpt {
            label: "Show widgets"
            checked: Config.widgets.enabled
            onToggled: v => Config.widgets.enabled = v
        }

        Opt {
            label: "Arrange"
            hint: "Opens the full-screen editor; Settings comes back when you are done"
            Btn {
                text: "Edit layout"
                icon: "arrows-out-cardinal"
                kind: "filled"
                onClicked: Ui.startWidgetEdit(Ui.screen, true)
            }
        }
    }

    Group {
        title: "Placed"

        Txt {
            visible: Config.widgets.items.length === 0
            height: 40
            verticalAlignment: Text.AlignVCenter
            text: "No widgets yet. Use Edit layout to add some."
            color: Theme.textMute
        }

        Repeater {
            model: Config.widgets.items

            Opt {
                id: placed
                required property var modelData
                required property int index

                label: modelData.type.charAt(0).toUpperCase() + modelData.type.slice(1)
                hint: (modelData.screen || "All screens") + "  ·  " + Math.round(modelData.x * 100) + "% × " + Math.round(modelData.y * 100) + "%"

                Choice {
                    options: [["", "All"]].concat(Quickshell.screens.map(s => [s.name, s.name]))
                    current: placed.modelData.screen || ""
                    onPicked: k => {
                        const items = Config.widgets.items.map(w => Object.assign({}, w));
                        if (k === "") delete items[placed.index].screen;
                        else items[placed.index].screen = k;
                        Config.widgets.items = items;
                    }
                }

                IconBtn {
                    icon: "trash"
                    flat: false
                    tint: Theme.danger
                    onClicked: Config.widgets.items = Config.widgets.items.filter((w, i) => i !== placed.index)
                }
            }
        }
    }
}
