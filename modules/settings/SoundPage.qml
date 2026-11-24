import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import qs.config
import qs.components
import qs.services

// Speakers, microphones and what each app is playing.
Column {
    id: page

    readonly property var nodes: Pipewire.nodes.values
    readonly property var outputs: nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var inputs: nodes.filter(n => n.audio && !n.isSink && !n.isStream)
    readonly property var apps: nodes.filter(n => n.audio && n.isStream && !n.isSink)

    function deviceName(n) { return n.description || n.nickname || n.name; }
    function appName(n) {
        const p = n.properties || {};
        return p["application.name"] || n.description || n.nickname || n.name;
    }
    function appDetail(n) {
        const p = n.properties || {}, m = p["media.name"] || "";
        return m !== appName(n) ? m : "";
    }

    spacing: 12

    PwObjectTracker { objects: page.outputs.concat(page.inputs, page.apps) }

    Group {
        title: "Output"

        Txt { visible: page.outputs.length === 0; height: 40; verticalAlignment: Text.AlignVCenter; text: "No speakers or headphones found"; color: Theme.textMute }

        Repeater {
            model: page.outputs

            SoundRow {
                required property var modelData
                node: modelData
                title: page.deviceName(modelData)
                detail: chosen ? "In use" : ""
                selectable: page.outputs.length > 1
                chosen: Audio.sink !== null && Audio.sink.id === modelData.id
                onChoose: Pipewire.preferredDefaultAudioSink = modelData
            }
        }
    }

    Group {
        title: "Input"

        Txt { visible: page.inputs.length === 0; height: 40; verticalAlignment: Text.AlignVCenter; text: "No microphone found"; color: Theme.textMute }

        Repeater {
            model: page.inputs

            SoundRow {
                required property var modelData
                node: modelData
                icon: "microphone"
                mutedIcon: "microphone-slash"
                title: page.deviceName(modelData)
                detail: chosen ? "In use" : ""
                selectable: page.inputs.length > 1
                chosen: Audio.source !== null && Audio.source.id === modelData.id
                onChoose: Pipewire.preferredDefaultAudioSource = modelData
            }
        }
    }

    Group {
        title: "Apps"

        Txt { visible: page.apps.length === 0; height: 40; verticalAlignment: Text.AlignVCenter; text: "Nothing is playing right now"; color: Theme.textMute }

        Repeater {
            model: page.apps

            SoundRow {
                required property var modelData
                node: modelData
                icon: "music-notes"
                title: page.appName(modelData)
                detail: page.appDetail(modelData)
            }
        }
    }

    Group {
        title: "Indicator"

        ToggleOpt {
            label: "Show the volume indicator"
            hint: "The pill that appears when volume or brightness changes"
            checked: Config.osd.enabled
            onToggled: v => Config.osd.enabled = v
        }
    }
}
