pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import qs.config

Singleton {
    id: root

    property list<QtObject> all: []
    readonly property list<QtObject> popups: all.filter(n => n.popup).slice(0, Config.notifications.maxPopups)
    readonly property int count: all.length
    readonly property bool dnd: Config.notifications.dnd

    function add(n) {
        const critical = n.urgency === NotificationUrgency.Critical;
        const e = entry.createObject(root, {
            notification: n,
            summary: n.summary,
            body: n.body,
            appName: n.appName,
            appIcon: n.appIcon,
            image: n.image,
            critical: critical,
            actions: n.actions,
            timeout: n.expireTimeout > 0 ? n.expireTimeout * 1000 : Config.notifications.timeout,
            popup: critical || !root.dnd
        });
        all = [e, ...all];
    }

    function remove(e) {
        if (all.indexOf(e) < 0) return;
        all = all.filter(x => x !== e);
        e.popup = false;
        e.destroy(2000); // cards are still animating out; let them finish first
    }

    function clear() { for (const e of all.slice()) e.dismiss(); }

    // Used by `ipc call zee notifyTest` to preview the popups.
    function test() {
        const samples = [
            ["ZeeShell", "Welcome aboard", "Notifications slide in here. Hover one to keep it around.", "sparkle"],
            ["Messages", "Robin", "Are we still on for tonight? I can bring the board games.", "chat-circle-dots"],
            ["System", "Update ready", "12 packages can be upgraded.", "arrow-circle-up"]
        ];
        const s = samples[Math.floor(Math.random() * samples.length)];
        const e = entry.createObject(root, { appName: s[0], summary: s[1], body: s[2], glyph: s[3], timeout: Config.notifications.timeout, popup: true });
        all = [e, ...all];
    }

    NotificationServer {
        keepOnReload: false
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        onNotification: n => {
            n.tracked = true;
            root.add(n);
        }
    }

    Component {
        id: entry

        QtObject {
            id: e

            property var notification: null
            property string summary: ""
            property string body: ""
            property string appName: ""
            property string appIcon: ""
            property string image: ""
            property string glyph: "bell"
            property bool critical: false
            property var actions: []
            property int timeout: 6000
            property bool popup: false
            property bool hovered: false
            readonly property date time: new Date()

            readonly property Timer timer: Timer {
                interval: e.timeout
                running: e.popup && !e.hovered && !e.critical
                onTriggered: e.popup = false
            }

            readonly property Connections conn: Connections {
                target: e.notification
                function onClosed() { root.remove(e); }
            }

            function dismiss() {
                if (notification) notification.dismiss();
                else root.remove(e);
            }
        }
    }
}
