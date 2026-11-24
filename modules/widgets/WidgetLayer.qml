import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// Desktop widgets living on the wallpaper. Positions are stored as fractions
// of the screen (to the widget centre) so layouts survive resolution changes.
// Arranging them happens in WidgetEditor.
Item {
    id: desk

    property var screen
    readonly property var items: Config.widgets.items.filter(w => !w.screen || w.screen === screen.name)
    readonly property var byId: {
        const m = {};
        for (const w of items) m[w.id] = w;
        return m;
    }

    opacity: Ui.booted ? 1 : 0
    scale: Ui.booted ? 1 : 0.97

    Behavior on opacity { Anim { ms: 900 } }
    Behavior on scale { Anim { ms: 900; curve: Theme.curve.enter } }

    Repeater {
        // Keyed by id, so moving one widget never rebuilds the others.
        model: ScriptModel { values: desk.items.map(w => w.id) }

        Item {
            id: frame

            required property string modelData
            readonly property var w: desk.byId[modelData] || null
            readonly property real s: w && w.scale ? w.scale : 1

            width: body.implicitWidth * s
            height: body.implicitHeight * s
            x: w ? Math.round(Math.max(8, Math.min(desk.width - width - 8, w.x * desk.width - width / 2))) : 0
            y: w ? Math.round(Math.max(8, Math.min(desk.height - height - 8, w.y * desk.height - height / 2))) : 0

            Behavior on x { Anim { ms: 420; curve: Theme.curve.springSoft } }
            Behavior on y { Anim { ms: 420; curve: Theme.curve.springSoft } }

            WidgetBody {
                id: body
                type: frame.w ? frame.w.type : ""
                zoom: frame.s
            }
        }
    }
}
