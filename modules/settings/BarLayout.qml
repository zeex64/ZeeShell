import QtQuick
import qs.config
import qs.components

// Reorder bar modules. Arrows move a module along the bar and across
// sections; removed modules drop into "Available".
Column {
    id: root

    readonly property var sections: ["left", "center", "right"]
    readonly property var unused: Object.keys(Config.barModules).filter(n => Config.bar.left.indexOf(n) < 0 && Config.bar.center.indexOf(n) < 0 && Config.bar.right.indexOf(n) < 0)

    function move(section, i, dir) {
        const arr = Config.bar[section].slice();
        const si = sections.indexOf(section), j = i + dir;
        if (j < 0 || j >= arr.length) {
            const other = sections[si + dir];
            if (!other) return;
            const m = arr.splice(i, 1)[0];
            Config.bar[section] = arr;
            Config.bar[other] = dir < 0 ? Config.bar[other].concat([m]) : [m].concat(Config.bar[other]);
        } else {
            const t = arr[i];
            arr[i] = arr[j];
            arr[j] = t;
            Config.bar[section] = arr;
        }
    }

    function remove(section, i) {
        const arr = Config.bar[section].slice();
        arr.splice(i, 1);
        Config.bar[section] = arr;
    }

    width: parent ? parent.width : 0
    spacing: 8

    Repeater {
        model: root.sections

        Rectangle {
            id: zone
            required property string modelData

            width: root.width
            height: flow.implicitHeight + 44
            radius: Theme.radius.sm
            color: Theme.layerHi

            Txt {
                x: 12
                y: 9
                text: zone.modelData.charAt(0).toUpperCase() + zone.modelData.slice(1)
                size: 11.5
                font.weight: Font.Bold
                color: Theme.textDim
            }

            Txt {
                anchors.centerIn: flow
                visible: Config.bar[zone.modelData].length === 0
                text: "Empty"
                color: Theme.textMute
                size: 12
            }

            Flow {
                id: flow
                x: 10
                y: 32
                width: parent.width - 20
                spacing: 6

                Repeater {
                    model: Config.bar[zone.modelData]

                    Rectangle {
                        id: chip
                        required property string modelData
                        required property int index
                        readonly property var info: Config.barModules[modelData] || { label: modelData, icon: "question" }

                        width: inner.implicitWidth + 12
                        height: 34
                        radius: Math.min(Theme.radius.full, 17)
                        color: Theme.accentSoft

                        Row {
                            id: inner
                            anchors.centerIn: parent
                            spacing: 2

                            IconBtn { size: 24; iconSize: 12; icon: "caret-left"; tint: Theme.softInk; onClicked: root.move(zone.modelData, chip.index, -1) }
                            Icon { anchors.verticalCenter: parent.verticalCenter; name: chip.info.icon; size: 15; color: Theme.softInk }
                            Txt { anchors.verticalCenter: parent.verticalCenter; text: chip.info.label; size: 12.5; font.weight: Font.Medium; color: Theme.softInk; leftPadding: 4; rightPadding: 2 }
                            IconBtn { size: 24; iconSize: 12; icon: "caret-right"; tint: Theme.softInk; onClicked: root.move(zone.modelData, chip.index, 1) }
                            IconBtn { size: 24; iconSize: 12; icon: "x"; tint: Theme.softInk; onClicked: root.remove(zone.modelData, chip.index) }
                        }
                    }
                }
            }
        }
    }

    Flow {
        width: parent.width
        spacing: 6
        topPadding: 4

        Txt {
            height: 32
            verticalAlignment: Text.AlignVCenter
            text: root.unused.length ? "Available" : "Every module is on the bar"
            size: 12
            color: Theme.textMute
            rightPadding: 6
        }

        Repeater {
            model: root.unused

            Chip {
                required property string modelData
                text: Config.barModules[modelData].label
                icon: "plus"
                onClicked: Config.bar.right = [modelData].concat(Config.bar.right)
            }
        }
    }
}
