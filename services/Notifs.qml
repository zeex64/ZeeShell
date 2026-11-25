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
    readonly property bool replying: popups.some(e => e.replying) // a popup wants the keyboard

    // Per-app rules from Settings: "mute" | "quiet" | "keep" (or nothing).
    function rule(app) { return Config.notifications.rules[app] || ""; }
    function setRule(app, r) {
        const o = Object.assign({}, Config.notifications.rules);
        if (r === "") delete o[app];
        else o[app] = r;
        Config.notifications.rules = o;
    }

    // Remember who has sent something, so Settings can offer rules for it.
    function noteApp(app) {
        if (!app || Config.notifications.apps.indexOf(app) >= 0) return;
        Config.notifications.apps = Config.notifications.apps.concat([app]).slice(-60);
    }

    function add(n) {
        const critical = n.urgency === NotificationUrgency.Critical;
        const app = n.appName || "";
        const r = rule(app);
        noteApp(app);
        if (r === "mute" && !critical) {
            n.dismiss();
            return;
        }
        const e = entry.createObject(root, {
            notification: n,
            summary: n.summary,
            body: n.body,
            appName: app,
            appIcon: n.appIcon,
            image: n.image,
            critical: critical,
            sticky: r === "keep",
            actions: n.actions,
            canReply: n.hasInlineReply === true,
            replyHint: n.inlineReplyPlaceholder || "",
            // expireTimeout arrives in milliseconds, as the spec sends it
            timeout: n.expireTimeout > 0 ? n.expireTimeout : Config.notifications.timeout,
            popup: critical || (!root.dnd && r !== "quiet")
        });
        all = [e, ...all];
    }

    // The history stacked by app, newest group first.
    readonly property var groups: {
        const out = [], at = {};
        for (const e of all) {
            const k = e.appName || "Notification";
            if (at[k] === undefined) { at[k] = out.length; out.push({ app: k, items: [] }); }
            out[at[k]].items.push(e);
        }
        return out;
    }
    property var expanded: ({}) // app name -> true while its stack is open
    function toggleGroup(app) {
        const o = Object.assign({}, expanded);
        if (o[app]) delete o[app];
        else o[app] = true;
        expanded = o;
    }
    function clearGroup(app) { for (const e of all.filter(x => (x.appName || "Notification") === app)) e.dismiss(); }

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
        const e = entry.createObject(root, { appName: s[0], summary: s[1], body: s[2], glyph: s[3], canReply: s[0] === "Messages", timeout: Config.notifications.timeout, popup: true });
        all = [e, ...all];
    }

    NotificationServer {
        keepOnReload: false
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        inlineReplySupported: true
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
            property bool sticky: false // the app's rule says keep it up
            property bool canReply: false
            property string replyHint: ""
            property bool replying: false
            readonly property date time: new Date()

            readonly property Timer timer: Timer {
                interval: e.timeout
                running: e.popup && !e.hovered && !e.replying && !e.critical && !e.sticky
                onTriggered: e.popup = false
            }

            readonly property Connections conn: Connections {
                target: e.notification
                function onClosed() { root.remove(e); }
            }

            function reply(text) {
                if (notification && canReply && text !== "") notification.sendInlineReply(text);
                replying = false;
                popup = false;
            }

            function dismiss() {
                if (notification) notification.dismiss();
                else root.remove(e);
            }
        }
    }
}
