import QtQuick
import qs.config
import qs.components
import qs.services

// Settings -> Keybinds: every bind Hyprland has, editable.
Column {
    id: page

    property var draft: null
    property bool mineOnly: false
    readonly property var order: ["Shell", "Apps", "Windows", "Workspaces", "Media", "Capture", "Other"]
    readonly property var groups: {
        const q = search.text.trim().toLowerCase(), by = {};
        for (const r of Keybinds.rows) {
            if (mineOnly && r.kind !== "managed") continue;
            if (q !== "" && (r.description + " " + r.combo + " " + Keybinds.caps(r.combo).join(" ") + " " + r.detail).toLowerCase().indexOf(q) < 0) continue;
            (by[r.category] = by[r.category] || []).push(r);
        }
        const out = [];
        for (const name of order) {
            if (!by[name]) continue;
            out.push({ name: name, rows: by[name].sort((a, b) => a.description.localeCompare(b.description)) });
        }
        return out;
    }

    function edit(d) {
        draft = null;
        draft = d;
        // Bring the editor into view: it sits at the top of the page.
        for (let p = parent; p; p = p.parent) {
            if (p.contentY !== undefined) { p.contentY = 0; break; }
        }
    }

    spacing: 12

    Item {
        width: parent.width
        height: 42

        Field {
            id: search
            width: 260
            icon: "magnifying-glass"
            placeholder: "Search keys or actions"
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Chip { anchors.verticalCenter: parent.verticalCenter; text: "My changes"; icon: "user"; active: page.mineOnly; onClicked: page.mineOnly = !page.mineOnly }
            Btn { kind: "ghost"; icon: "keyboard"; text: "Cheat sheet"; onClicked: Ui.show("keybinds") }
            Btn { kind: "filled"; icon: "plus"; text: "Add keybind"; onClicked: page.edit(Keybinds.draftNew()) }
        }
    }

    Txt {
        width: parent.width
        wrapMode: Text.Wrap
        size: 12
        color: !Hypr.lua || !Keybinds.recorderOk ? Theme.warn : Theme.textMute
        text: !Hypr.lua ? "The keybind editor needs Hyprland's Lua config."
            : !Hypr.hooked ? "ZeeShell's Hyprland hooks are not installed, so binds cannot be listed or changed. Run install.sh from the ZeeShell folder."
            : !Keybinds.recorderOk ? "Hyprland has not reported its binds yet. Reload Hyprland (hyprctl reload) and they will appear."
            : "Binds from your Hyprland config can be moved to other keys, changed or switched off here without touching those files. Undoing a change puts the original back."
    }

    Loader {
        width: parent.width
        active: page.draft !== null
        visible: active
        sourceComponent: Component {
            KeybindEditor {
                draft: page.draft
                onClosed: page.draft = null
            }
        }
    }

    Repeater {
        model: page.groups

        Group {
            id: group
            required property var modelData
            title: modelData.name + "  ·  " + modelData.rows.length

            Repeater {
                model: group.modelData.rows

                KeybindRow {
                    required property var modelData
                    row: modelData
                    onEdit: page.edit(Keybinds.draftFor(modelData))
                }
            }
        }
    }

    Txt {
        visible: page.groups.length === 0
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        topPadding: 30
        text: page.mineOnly ? "You have not changed any keybinds yet" : "Nothing matches"
        color: Theme.textMute
    }
}
