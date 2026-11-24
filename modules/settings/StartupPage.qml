import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// Apps the shell starts when the session begins.
Column {
    id: page

    function add(item) {
        if (Config.apps.startup.some(s => (item.id && s.id === item.id) || (item.cmd && s.cmd === item.cmd))) return;
        Config.apps.startup = Config.apps.startup.concat([item]);
    }
    function patch(index, change) {
        Config.apps.startup = Config.apps.startup.map((s, i) => i === index ? Object.assign({}, s, change) : s);
    }

    spacing: 12

    Group {
        title: "Start with the session"

        Txt {
            visible: Config.apps.startup.length === 0
            width: parent.width
            height: 44
            verticalAlignment: Text.AlignVCenter
            text: "Nothing yet. Add an app below and it opens each time you log in."
            color: Theme.textMute
            wrapMode: Text.Wrap
        }

        Repeater {
            model: Config.apps.startup

            Opt {
                id: item
                required property var modelData
                required property int index

                label: modelData.name
                hint: modelData.id ? "App" : modelData.cmd

                Toggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: item.modelData.enabled !== false
                    onToggled: v => page.patch(item.index, { enabled: v })
                }

                IconBtn {
                    icon: "trash"
                    flat: false
                    tint: Theme.danger
                    onClicked: Config.apps.startup = Config.apps.startup.filter((s, i) => i !== item.index)
                }
            }
        }
    }

    Group {
        title: "Add"

        SelectOpt {
            label: "An installed app"
            placeholder: "Choose an app"
            searchable: true
            options: Apps.all.map(a => [a.id, a.name, a.genericName || ""])
            current: ""
            onPicked: k => {
                const a = Apps.all.find(x => x.id === k);
                if (a) page.add({ id: a.id, name: a.name, cmd: "", enabled: true });
            }
        }

        Opt {
            label: "A command"
            hint: "Runs through sh, so arguments and && work"

            Field {
                id: command
                width: 260
                implicitHeight: 36
                icon: "terminal-window"
                placeholder: "for example: nm-applet"
                onAccepted: adder.clicked()
            }

            Btn {
                id: adder
                text: "Add"
                icon: "plus"
                onClicked: {
                    const c = command.text.trim();
                    if (c === "") return;
                    page.add({ id: "", name: c.split(/\s+/)[0], cmd: c, enabled: true });
                    command.text = "";
                }
            }
        }
    }

    Group {
        title: "Good to know"

        Opt {
            label: "Started once per login"
            hint: "Restarting the shell does not start them again. Apps your Hyprland config starts are not listed here."
        }
    }
}
