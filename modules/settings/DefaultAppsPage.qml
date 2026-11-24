import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// Which app opens links, folders, pictures and so on.
Column {
    spacing: 12
    Component.onCompleted: DefaultApps.refresh()

    Group {
        title: "Open with"

        Repeater {
            model: DefaultApps.kinds

            SelectOpt {
                id: pick

                required property var modelData
                readonly property var ids: {
                    const list = (DefaultApps.choices[modelData.key] || []).slice(), cur = DefaultApps.current[modelData.key];
                    if (cur && list.indexOf(cur) < 0) list.unshift(cur);
                    return list;
                }

                label: modelData.label
                hint: ids.length === 0 && DefaultApps.loaded ? "No installed app says it can open this" : ""
                placeholder: DefaultApps.loaded ? "Not set" : "…"
                searchable: ids.length > 8
                options: ids.map(id => [id, DefaultApps.name(id), ""]).sort((a, b) => a[1].localeCompare(b[1]))
                current: DefaultApps.current[modelData.key] || ""
                onPicked: k => DefaultApps.choose(modelData.key, k)
            }
        }
    }

    Group {
        title: "Good to know"

        Opt {
            label: "These are the system-wide defaults"
            hint: "The same ones xdg-open and other desktops use, so apps you start from a terminal follow them too."
        }
    }
}
