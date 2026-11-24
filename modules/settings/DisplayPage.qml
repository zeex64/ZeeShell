import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// Monitors: where they sit, their resolution, refresh rate, scale and
// rotation. Changes are gathered as a draft, tried out with Apply, and only
// saved once the "keep?" question is answered.
Column {
    id: page

    property string selected: ""
    property var draft: ({}) // name -> rule, not applied yet

    readonly property var mons: Displays.monitors
    readonly property var mon: mons.find(m => m.name === selected) || mons.find(m => m.focused) || mons[0] || null
    readonly property var rule: mon ? ruleFor(mon) : null
    readonly property var mode: rule ? Displays.parseMode(rule.mode) : null
    readonly property bool dirty: Object.keys(draft).length > 0
    readonly property int enabledCount: mons.filter(m => !ruleFor(m).disabled).length

    function ruleFor(m) { return draft[m.name] || Displays.ruleOf(m); }
    function change(m, patch) {
        const d = Object.assign({}, draft);
        d[m.name] = Object.assign({}, ruleFor(m), patch);
        draft = d;
    }

    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }
    function align(v, lo, hi, marks, tolerance) {
        v = clamp(v, Math.min(lo, hi), Math.max(lo, hi));
        for (const m of marks) if (Math.abs(v - m) < tolerance) return m;
        return v;
    }

    // Put a dragged screen against the nearest edge of another one, so the
    // layout never has gaps or overlaps the pointer cannot cross.
    function drop(name, nx, ny, tolerance) {
        const me = stage.rects.find(r => r.name === name), others = stage.rects.filter(r => r.name !== name);
        if (!me || !others.length) return;
        let best = null;
        const consider = (x, y) => {
            const d = (x - nx) * (x - nx) + (y - ny) * (y - ny);
            if (!best || d < best.d) best = { x: x, y: y, d: d };
        };
        for (const o of others) {
            const y = align(ny, o.y - me.h + 1, o.y + o.h - 1, [o.y, o.y + o.h - me.h, o.y + (o.h - me.h) / 2], tolerance);
            consider(o.x - me.w, y);
            consider(o.x + o.w, y);
            const x = align(nx, o.x - me.w + 1, o.x + o.w - 1, [o.x, o.x + o.w - me.w, o.x + (o.w - me.w) / 2], tolerance);
            consider(x, o.y - me.h);
            consider(x, o.y + o.h);
        }
        const m = mons.find(x => x.name === name);
        if (best && m) change(m, { x: Math.round(best.x), y: Math.round(best.y) });
    }

    spacing: 12
    Component.onCompleted: Displays.refresh()

    Group {
        title: "Arrangement"

        Item {
            id: stage

            readonly property var rects: page.mons.filter(m => !page.ruleFor(m).disabled).map(m => {
                const r = page.ruleFor(m), s = Displays.logicalSize(r);
                return { name: m.name, x: r.x, y: r.y, w: s.w, h: s.h, label: m.model || m.description || m.name };
            })
            readonly property real minX: rects.reduce((a, r) => Math.min(a, r.x), Infinity)
            readonly property real minY: rects.reduce((a, r) => Math.min(a, r.y), Infinity)
            readonly property real spanW: rects.reduce((a, r) => Math.max(a, r.x + r.w), -Infinity) - minX
            readonly property real spanH: rects.reduce((a, r) => Math.max(a, r.y + r.h), -Infinity) - minY
            readonly property real k: rects.length ? Math.min((width - 80) / Math.max(1, spanW), (height - 36) / Math.max(1, spanH)) : 1
            readonly property real offX: (width - spanW * k) / 2
            readonly property real offY: (height - spanH * k) / 2

            width: parent.width
            height: 230

            Repeater {
                model: stage.rects

                Rectangle {
                    id: box

                    required property var modelData
                    readonly property bool current: page.mon !== null && modelData.name === page.mon.name
                    property real dragX: 0
                    property real dragY: 0

                    x: stage.offX + (modelData.x - stage.minX) * stage.k + dragX
                    y: stage.offY + (modelData.y - stage.minY) * stage.k + dragY
                    z: grab.pressed ? 2 : current ? 1 : 0
                    width: modelData.w * stage.k - 4
                    height: modelData.h * stage.k - 4
                    radius: Math.min(Theme.radius.sm, 10)
                    color: current ? Theme.accentSoft : Theme.layerHi
                    border.width: current ? 2 : 1
                    border.color: current ? Theme.accent : Theme.outlineHi
                    scale: grab.pressed ? 1.03 : 1

                    Behavior on scale { Anim { ms: 220; curve: Theme.curve.spring } }
                    Behavior on color { CAnim {} }

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        spacing: 1

                        Txt {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: box.modelData.name
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                            color: box.current ? Theme.softInk : Theme.text
                        }

                        Txt {
                            width: parent.width
                            visible: box.height > 54
                            horizontalAlignment: Text.AlignHCenter
                            text: Math.round(box.modelData.w) + " × " + Math.round(box.modelData.h)
                            size: 11
                            elide: Text.ElideRight
                            color: Theme.alpha(box.current ? Theme.softInk : Theme.text, 0.65)
                        }
                    }

                    MouseArea {
                        id: grab

                        property real startX: 0
                        property real startY: 0

                        anchors.fill: parent
                        preventStealing: true
                        cursorShape: stage.rects.length > 1 ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.PointingHandCursor
                        onPressed: e => {
                            const p = mapToItem(stage, e.x, e.y);
                            startX = p.x;
                            startY = p.y;
                            page.selected = box.modelData.name;
                        }
                        onPositionChanged: e => {
                            if (!pressed || stage.rects.length < 2) return;
                            const p = mapToItem(stage, e.x, e.y);
                            box.dragX = p.x - startX;
                            box.dragY = p.y - startY;
                        }
                        onReleased: {
                            const moved = Math.abs(box.dragX) + Math.abs(box.dragY) > 6;
                            const nx = box.modelData.x + box.dragX / stage.k, ny = box.modelData.y + box.dragY / stage.k;
                            box.dragX = 0;
                            box.dragY = 0;
                            if (moved) page.drop(box.modelData.name, nx, ny, 40 / stage.k);
                        }
                    }
                }
            }
        }

        Txt {
            width: parent.width
            height: 26
            horizontalAlignment: Text.AlignHCenter
            text: stage.rects.length > 1 ? "Drag a screen to where it sits on your desk. It snaps to the others." : "One screen connected"
            size: 11.5
            color: Theme.textMute
        }
    }

    // Shown while something is waiting on the user.
    Card {
        width: parent.width
        height: page.dirty || Displays.pending ? 60 : 0
        visible: height > 1
        clip: true
        color: Displays.pending ? Theme.accentSoft : Theme.layer

        Behavior on height { Anim { ms: 300; curve: Theme.curve.enter } }

        Txt {
            x: 18
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 300
            text: Displays.pending ? "Keep this layout? Going back in " + Displays.secondsLeft + " s" : "These changes are not applied yet"
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            color: Displays.pending ? Theme.softInk : Theme.text
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Btn {
                text: Displays.pending ? "Go back" : "Discard"
                kind: "ghost"
                onClicked: Displays.pending ? Displays.revert() : page.draft = ({})
            }

            Btn {
                text: Displays.pending ? "Keep" : "Apply"
                icon: "check"
                kind: "filled"
                onClicked: {
                    if (Displays.pending) { Displays.keep(); return; }
                    Displays.attempt(page.draft);
                    page.draft = ({});
                }
            }
        }
    }

    Group {
        visible: page.mon !== null
        title: page.mon ? (page.mon.description || page.mon.name) : ""

        SelectOpt {
            label: "Resolution"
            options: {
                if (!page.mon) return [];
                const seen = {}, out = [];
                for (const m of Displays.modes(page.mon)) {
                    const k = m.w + "x" + m.h;
                    if (seen[k]) continue;
                    seen[k] = true;
                    out.push([k, m.w + " × " + m.h, ""]);
                }
                return out;
            }
            current: page.mode ? page.mode.w + "x" + page.mode.h : ""
            onPicked: k => {
                // The fastest refresh rate that size offers.
                const best = Displays.modes(page.mon).find(m => m.w + "x" + m.h === k);
                if (best) page.change(page.mon, { mode: best.key });
            }
        }

        SelectOpt {
            label: "Refresh rate"
            options: page.mon && page.mode ? Displays.modes(page.mon).filter(m => m.w === page.mode.w && m.h === page.mode.h).map(m => [m.key, m.rate.toFixed(2).replace(/\.00$/, "") + " Hz", ""]) : []
            current: page.rule ? page.rule.mode : ""
            onPicked: k => page.change(page.mon, { mode: k })
        }

        SelectOpt {
            label: "Scale"
            hint: "Makes everything on this screen larger"
            options: page.mode ? Displays.scales(page.mode.w, page.mode.h).map(s => [s, Math.round(s * 100) + "%", ""]) : []
            current: {
                if (!page.rule || !page.mode) return 1;
                const all = Displays.scales(page.mode.w, page.mode.h);
                let best = all[0] || 1;
                for (const s of all) if (Math.abs(s - page.rule.scale) < Math.abs(best - page.rule.scale)) best = s;
                return best;
            }
            onPicked: k => page.change(page.mon, { scale: k })
        }

        ChoiceOpt {
            label: "Orientation"
            options: [[0, "Landscape"], [1, "Portrait"], [2, "Upside down"], [3, "Portrait, flipped"]]
            current: page.rule ? page.rule.transform % 4 : 0
            onPicked: k => page.change(page.mon, { transform: k })
        }

        ToggleOpt {
            visible: page.mon !== null && (!page.mon.hardwareDetails || page.mon.hardwareDetails.vrrCapable !== false)
            label: "Variable refresh rate"
            hint: "Lets the screen follow the frame rate of games and video"
            checked: page.rule !== null && page.rule.vrr > 0
            onToggled: v => page.change(page.mon, { vrr: v ? 1 : 0 })
        }

        ToggleOpt {
            visible: page.mons.length > 1
            label: "Use this screen"
            hint: "Off turns the screen off and moves its windows to the others"
            checked: page.rule !== null && !page.rule.disabled
            onToggled: v => { if (v || page.enabledCount > 1) page.change(page.mon, { disabled: !v }); }
        }
    }

    Group {
        title: "Brightness & colour"

        SliderOpt {
            visible: Brightness.available
            label: "Brightness"
            from: 0; to: 100; step: 1; decimals: 0; suffix: "%"
            value: Math.round(Brightness.value * 100)
            onMoved: v => Brightness.set(v / 100)
        }

        ToggleOpt {
            label: "Night light"
            hint: "Warmer colours in the evening, easier on the eyes"
            checked: Toggles.nightLight
            onToggled: v => Toggles.nightLight = v
        }

        SliderOpt {
            label: "Night light warmth"
            from: 2500; to: 6000; step: 100; decimals: 0; suffix: " K"
            value: Config.sidebar.nightTemp
            onMoved: v => Config.sidebar.nightTemp = v
        }
    }

    Group {
        title: "Saved layout"

        Opt {
            label: Displays.managed ? "ZeeShell sets up your screens" : "Your Hyprland config sets up your screens"
            hint: Displays.managed
                ? "The layout kept here is applied every time you log in. Hand it back to return to what your Hyprland config says."
                : "Nothing is changed until you keep a layout here. From then on ZeeShell applies it at login."

            Btn {
                visible: Displays.managed
                text: "Hand back"
                icon: "arrow-counter-clockwise"
                kind: "ghost"
                onClicked: { page.draft = ({}); Displays.forgetAll(); }
            }
        }
    }
}
