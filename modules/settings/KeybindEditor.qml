import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components
import qs.services

// Edit or create one keybind: pick the keys, then what they do.
Card {
    id: root

    required property var draft
    signal closed()

    property string combo: draft.combo
    property string type: draft.action.type
    property string value: draft.action.value
    property string appName: draft.action.name || ""
    property string description: draft.description
    property bool describedByHand: false

    readonly property var action: type === "app" ? { type: type, value: value, name: appName } : { type: type, value: value }
    readonly property string clash: Keybinds.conflict(draft, combo)
    readonly property bool valid: combo !== "" && value !== ""
    readonly property var typeOptions: {
        const o = [["shell", "Shell"], ["app", "App"], ["command", "Command"], ["window", "Window"]];
        if (draft.action.type === "lua") o.push(["lua", "Original"]);
        return o;
    }
    readonly property var windowGroups: {
        const out = [];
        for (const a of Keybinds.windowActions) {
            let g = out.find(x => x.name === a.group);
            if (!g) { g = { name: a.group, items: [] }; out.push(g); }
            g.items.push(a);
        }
        return out;
    }

    function pick(newType, newValue, name) {
        type = newType;
        value = newValue;
        appName = name || "";
        if (!describedByHand) description = "";
    }

    function save() {
        Keybinds.upsert({
            id: draft.id,
            replaces: draft.replaces || "",
            combo: Keybinds.tidy(combo),
            action: action,
            description: description.trim() !== "" ? description.trim() : Keybinds.describe(action),
            flags: draft.flags || "",
            origin: draft.origin || ""
        });
        closed();
    }

    width: parent ? parent.width : 0
    implicitHeight: col.implicitHeight + 32
    height: implicitHeight
    color: Theme.alpha(Theme.accentSoft, 0.4)
    border.color: Theme.alpha(Theme.accent, 0.6)

    // While listening for keys, ask Hyprland not to act on its own binds.
    ShortcutInhibitor {
        window: root.QsWindow.window
        enabled: capture.active
    }

    Column {
        id: col
        x: 18
        y: 16
        width: parent.width - 36
        spacing: 12

        Item {
            width: parent.width
            height: 30

            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: root.draft.fresh ? "New keybind" : root.draft.replaces ? "Change keybind" : "Edit keybind"
                size: 15
                font.weight: Font.Bold
            }

            IconBtn { anchors.right: parent.right; size: 30; icon: "x"; onClicked: root.closed() }
        }

        // ---- keys ----
        Row {
            width: parent.width
            spacing: 10

            Rectangle {
                id: capture

                property bool active: false

                width: 300
                height: 46
                radius: Theme.radius.sm
                color: active ? Theme.accent : Theme.layerHi
                border.width: 1
                border.color: active ? Theme.accent : Theme.outlineHi

                Behavior on color { CAnim {} }

                onActiveFocusChanged: if (!activeFocus) active = false

                Keys.onPressed: e => {
                    if (!active) return;
                    e.accepted = true;
                    if (e.key === Qt.Key_Escape && e.modifiers === Qt.NoModifier) { active = false; return; }
                    const k = Keybinds.keyName(e);
                    if (k === "") return; // a modifier on its own; keep listening
                    root.combo = Keybinds.format(Keybinds.modsOf(e.modifiers), k);
                    active = false;
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 5
                    visible: !capture.active && root.combo !== ""

                    Repeater {
                        model: Keybinds.caps(root.combo)
                        Keycap { required property string modelData; label: modelData }
                    }
                }

                Txt {
                    anchors.centerIn: parent
                    visible: capture.active || root.combo === ""
                    text: capture.active ? "Press the keys…  Esc cancels" : "Click, then press the keys"
                    color: capture.active ? Theme.accentInk : Theme.textDim
                    font.weight: Font.Medium
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        capture.active = !capture.active;
                        if (capture.active) capture.forceActiveFocus();
                    }
                }
            }

            Txt { anchors.verticalCenter: parent.verticalCenter; text: "or type"; color: Theme.textMute; size: 12 }

            Field {
                id: manual
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 300 - 80
                implicitHeight: 40
                placeholder: "SUPER + SHIFT + W"
                Component.onCompleted: text = root.combo
                onEditingDone: root.combo = Keybinds.tidy(text)

                Connections {
                    target: root
                    function onComboChanged() { if (manual.text !== root.combo) manual.text = root.combo; }
                }
            }
        }

        Txt {
            width: parent.width
            visible: root.clash !== ""
            wrapMode: Text.Wrap
            text: "These keys currently do “" + root.clash + "”. Saving replaces that."
            color: Theme.warn
            size: 12.5
        }

        // ---- action ----
        Choice {
            options: root.typeOptions
            current: root.type
            onPicked: k => {
                if (k === root.type) return;
                if (k === "lua") root.pick("lua", root.draft.action.value);
                else if (k === "shell") root.pick("shell", "launcher");
                else root.pick(k, "");
            }
        }

        Flow {
            width: parent.width
            visible: root.type === "shell"
            spacing: 6

            Repeater {
                model: Keybinds.shellActions

                Chip {
                    required property var modelData
                    text: modelData.label
                    icon: modelData.icon
                    active: root.value === modelData.key
                    onClicked: root.pick("shell", modelData.key)
                }
            }
        }

        Column {
            width: parent.width
            visible: root.type === "app"
            spacing: 6

            Field {
                id: appSearch
                width: parent.width
                implicitHeight: 40
                icon: "magnifying-glass"
                placeholder: root.value !== "" ? "Opens " + (root.appName || root.value) + " — search to change" : "Search your apps"
            }

            Repeater {
                model: root.type === "app" && appSearch.text.trim() !== "" ? Apps.search(appSearch.text, "all").slice(0, 6) : []

                Item {
                    id: app
                    required property var modelData
                    width: parent.width
                    height: 40

                    IconImage { x: 8; anchors.verticalCenter: parent.verticalCenter; implicitSize: 24; source: Apps.icon(app.modelData) }
                    Txt { x: 44; anchors.verticalCenter: parent.verticalCenter; text: app.modelData.name; font.weight: Font.Medium }
                    Txt { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; width: Math.min(implicitWidth, parent.width * 0.5); elide: Text.ElideRight; text: app.modelData.execString; mono: true; size: 11; color: Theme.textMute }

                    StateLayer {
                        radius: Theme.radius.sm
                        onClicked: {
                            root.pick("app", app.modelData.execString.replace(/%[a-zA-Z]/g, "").replace(/\s+/g, " ").trim(), app.modelData.name);
                            appSearch.text = "";
                        }
                    }
                }
            }
        }

        Field {
            id: command
            width: parent.width
            visible: root.type === "command"
            implicitHeight: 40
            icon: "terminal-window"
            placeholder: "Command line, run through your shell"
            Component.onCompleted: if (root.type === "command") text = root.value

            Connections {
                target: command.input
                function onTextEdited() { if (root.type === "command") root.value = command.text.trim(); }
            }

            Connections {
                target: root
                function onTypeChanged() { if (root.type === "command" && command.text !== root.value) command.text = root.value; }
            }
        }

        Column {
            width: parent.width
            visible: root.type === "window"
            spacing: 8

            Repeater {
                model: root.type === "window" ? root.windowGroups : []

                Column {
                    id: group
                    required property var modelData
                    width: parent.width
                    spacing: 5

                    Txt { text: group.modelData.name; size: 11.5; font.weight: Font.DemiBold; color: Theme.textDim }

                    Flow {
                        width: parent.width
                        spacing: 5

                        Repeater {
                            model: group.modelData.items

                            Chip {
                                required property var modelData
                                text: modelData.label
                                active: root.value === modelData.lua
                                onClicked: root.pick("window", modelData.lua)
                            }
                        }
                    }
                }
            }
        }

        Txt {
            width: parent.width
            visible: root.type === "lua"
            wrapMode: Text.WrapAnywhere
            text: "Keeps what it does now:  " + root.value
            mono: true
            size: 11.5
            color: Theme.textDim
        }

        Field {
            id: label
            width: parent.width
            implicitHeight: 40
            icon: "text-aa"
            placeholder: Keybinds.describe(root.action) || "Description (shown in the cheat sheet)"
            Component.onCompleted: text = root.description

            Connections {
                target: label.input
                function onTextEdited() { root.describedByHand = true; root.description = label.text; }
            }

            Connections {
                target: root
                function onDescriptionChanged() { if (label.text !== root.description) label.text = root.description; }
            }
        }

        Item {
            width: parent.width
            height: 36

            Row {
                anchors.right: parent.right
                spacing: 8

                Btn { kind: "ghost"; text: "Cancel"; onClicked: root.closed() }
                Btn { kind: "filled"; icon: "check"; text: "Save"; enabled: root.valid; onClicked: root.save() }
            }
        }
    }
}
