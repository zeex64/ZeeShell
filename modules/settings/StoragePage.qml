import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// Disk space: every mounted drive, what fills the home folder, and the trash.
Column {
    id: page

    property bool confirmEmpty: false

    function volumeName(v) {
        if (v.mount === "/") return "System";
        if (v.mount === Config.home || v.mount === "/home") return "Home";
        if (v.label !== "") return v.label;
        const last = v.mount.slice(v.mount.lastIndexOf("/") + 1) || v.mount;
        // Drives without a label are mounted under their ID, which says nothing.
        return /^[0-9a-fA-F-]{9,}$/.test(last) ? Storage.human(v.size) + " drive" : last;
    }

    spacing: 12
    Component.onCompleted: Storage.refresh()

    Group {
        title: "Drives"

        Repeater {
            model: Storage.volumes

            Item {
                id: vol

                required property var modelData
                readonly property real share: modelData.size > 0 ? modelData.used / modelData.size : 0

                width: parent.width
                height: 68

                Icon {
                    id: glyph
                    anchors.verticalCenter: parent.verticalCenter
                    name: vol.modelData.mount === "/" ? "hard-drives" : "hard-drive"
                    size: 22
                    color: Theme.accent
                }

                Txt {
                    x: 36
                    y: 10
                    text: page.volumeName(vol.modelData)
                    font.weight: Font.DemiBold
                }

                Txt {
                    anchors.right: parent.right
                    y: 11
                    text: Storage.human(vol.modelData.free) + " free of " + Storage.human(vol.modelData.size)
                    size: 12
                    color: Theme.textDim
                }

                Rectangle {
                    x: 36
                    y: 34
                    width: parent.width - 36
                    height: 8
                    radius: 4
                    color: Theme.layerHi

                    Rectangle {
                        width: Math.max(8, parent.width * vol.share)
                        height: parent.height
                        radius: 4
                        color: vol.share > 0.92 ? Theme.danger : vol.share > 0.8 ? Theme.warn : Theme.accent
                    }
                }

                Txt {
                    x: 36
                    y: 46
                    width: parent.width - 36
                    text: vol.modelData.mount + "  ·  " + vol.modelData.type + "  ·  " + vol.modelData.device
                    size: 11
                    color: Theme.textMute
                    elide: Text.ElideMiddle
                }
            }
        }
    }

    Group {
        title: "Home folder"

        Opt {
            label: Storage.analysed ? "Your files take " + Storage.human(Storage.homeSize) : "See what takes up space"
            hint: Storage.analysing ? "Measuring your folders. Large ones can take a minute." : "Adds up each folder in your home folder, hidden ones included"

            Spinner { anchors.verticalCenter: parent.verticalCenter; visible: Storage.analysing; size: 20 }
            Btn { visible: !Storage.analysing; text: Storage.analysed ? "Measure again" : "Measure"; icon: "chart-pie-slice"; onClicked: Storage.analyse() }
        }

        Repeater {
            model: Storage.folders

            Item {
                id: dir

                required property var modelData

                width: parent.width
                height: 40

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(6, parent.width * (Storage.folders.length ? dir.modelData.size / Storage.folders[0].size : 0))
                    height: 32
                    radius: Theme.radius.xs + 2
                    color: Theme.alpha(Theme.accent, 0.16)
                }

                Icon { x: 10; anchors.verticalCenter: parent.verticalCenter; name: dir.modelData.name.startsWith(".") ? "folder-dashed" : "folder"; size: 17; color: Theme.accent }
                Txt { x: 36; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 150; text: dir.modelData.name; elide: Text.ElideRight }
                Txt { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: Storage.human(dir.modelData.size); color: Theme.textDim; font.features: { "tnum": 1 } }

                StateLayer {
                    radius: Theme.radius.xs + 2
                    onClicked: Quickshell.execDetached([Quickshell.shellPath("zeeshell"), "files", dir.modelData.path])
                }
            }
        }
    }

    Group {
        title: "Clean up"

        Opt {
            label: "Trash"
            hint: Storage.trashSize > 4096 ? Storage.human(Storage.trashSize) + " waiting to be removed for good" : "Empty"

            Btn {
                visible: Storage.trashSize > 4096
                text: page.confirmEmpty ? "Really empty it?" : "Empty trash"
                icon: "trash"
                kind: page.confirmEmpty ? "danger" : "ghost"
                onClicked: {
                    if (!page.confirmEmpty) { page.confirmEmpty = true; forget.restart(); return; }
                    page.confirmEmpty = false;
                    Storage.emptyTrash();
                }
            }
        }

        Opt {
            label: "App caches"
            hint: Storage.human(Storage.cacheSize) + " in ~/.cache. Apps rebuild what they need, so old folders there are safe to delete."

            Btn { text: "Open folder"; icon: "folder-open"; kind: "ghost"; onClicked: Quickshell.execDetached([Quickshell.shellPath("zeeshell"), "files", Config.home + "/.cache"]) }
        }
    }

    Timer { id: forget; interval: 4000; onTriggered: page.confirmEmpty = false }
}
