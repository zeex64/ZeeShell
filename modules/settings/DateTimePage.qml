import Quickshell
import QtQuick
import qs.config
import qs.components
import qs.services

// Time zone, automatic time, and how the clock is written.
Column {
    spacing: 12
    Component.onCompleted: DateTime.refresh()

    Card {
        width: parent.width
        height: 104

        Row {
            x: 22
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Txt { id: big; text: Time.time; size: 44; font.weight: Font.Bold; font.features: { "tnum": 1 } }
            Txt { anchors.baseline: big.baseline; visible: Time.ampm !== ""; text: Time.ampm; size: 16; font.weight: Font.DemiBold; color: Theme.accent }
        }

        Column {
            anchors.right: parent.right
            anchors.rightMargin: 22
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Txt { anchors.right: parent.right; text: Time.longDate; font.weight: Font.DemiBold }
            Txt { anchors.right: parent.right; text: (DateTime.zone !== "" ? DateTime.zone.replace(/_/g, " ") : "") + "  ·  week " + Time.week; size: 12; color: Theme.textMute }
        }
    }

    Group {
        title: "Date & time"

        ToggleOpt {
            label: "Set the time automatically"
            hint: DateTime.error !== "" ? DateTime.error : DateTime.ntp ? (DateTime.synced ? "In step with internet time" : "Waiting to hear from a time server") : "The clock runs on its own"
            checked: DateTime.ntp
            onToggled: v => DateTime.setNtp(v)
        }

        SelectOpt {
            label: "Time zone"
            hint: "Changing it asks for permission"
            searchable: true
            buttonWidth: 280
            options: DateTime.zones.length ? DateTime.zones.map(z => [z, z.replace(/_/g, " "), ""]) : (DateTime.zone !== "" ? [[DateTime.zone, DateTime.zone.replace(/_/g, " "), ""]] : [])
            current: DateTime.zone
            onOpened: DateTime.loadZones()
            onPicked: k => DateTime.setZone(k)
        }
    }

    Group {
        title: "Clock"

        ToggleOpt { label: "24-hour time"; checked: Config.clock.use24h; onToggled: v => Config.clock.use24h = v }
        ToggleOpt { label: "Show seconds"; checked: Config.clock.showSeconds; onToggled: v => Config.clock.showSeconds = v }
        ToggleOpt { label: "Show date in bar"; checked: Config.clock.showDate; onToggled: v => Config.clock.showDate = v }
        ToggleOpt { label: "Show weather in the clock"; hint: "One pill for time and weather; clicking it opens the calendar"; checked: Config.clock.showWeather; onToggled: v => Config.clock.showWeather = v }
    }

    Group {
        title: "Calendars"

        Opt {
            visible: Config.calendar.feeds.length === 0
            label: "No calendars yet"
            hint: "Paste a calendar's .ics link (Google: Settings → your calendar → Secret address in iCal format). Its events show under the clock and in quick settings."
        }

        Repeater {
            model: Config.calendar.feeds

            Opt {
                required property var modelData
                required property int index
                label: modelData.name || "Calendar"
                hint: String(modelData.url).replace(/^(https?:\/\/[^/]+\/).{12,}(.{8})$/, "$1…$2")

                Toggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: modelData.enabled !== false
                    onToggled: v => {
                        const f = Config.calendar.feeds.slice();
                        f[index] = Object.assign({}, f[index], { enabled: v });
                        Config.calendar.feeds = f;
                    }
                }
                IconBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "trash"
                    onClicked: Config.calendar.feeds = Config.calendar.feeds.filter((x, i) => i !== index)
                }
            }
        }

        Opt {
            label: "Add a calendar"
            hint: Calendar.loading ? "Fetching…" : Calendar.error !== "" ? Calendar.error : Calendar.active ? Calendar.events.length + " events in the next two months" : ""

            Field {
                id: calName
                width: 120
                implicitHeight: 36
                placeholder: "Name"
            }
            Field {
                id: calUrl
                width: 230
                implicitHeight: 36
                placeholder: "https://…/basic.ics"
                onAccepted: addCal.clicked()
            }
            Btn {
                id: addCal
                text: "Add"
                enabled: /^(https?|webcal):\/\//.test(calUrl.text.trim())
                onClicked: {
                    if (!enabled) return;
                    Config.calendar.feeds = Config.calendar.feeds.concat([{ url: calUrl.text.trim(), name: calName.text.trim() || "Calendar", enabled: true }]);
                    calUrl.text = "";
                    calName.text = "";
                }
            }
        }
    }

    Group {
        title: "Region"

        InfoOpt {
            label: "Language and formats"
            hint: "Set system-wide, with localectl or your distribution's own tools"
            value: DateTime.locale !== "" ? DateTime.locale : "Not set"
        }
    }
}
