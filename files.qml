//@ pragma AppId zeeshell-files
//@ pragma Env QS_NO_RELOAD_POPUP=1

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config
import qs.services
import qs.modules.files

// ZeeShell Files: the file explorer. It runs as its own process, separate from
// the shell, and owns every explorer window. Start it with `zeeshell files`.
ShellRoot {
    id: app

    property var ids: []
    property var startPaths: ({})
    property int next: 1

    function open(path) {
        const id = next++, start = Object.assign({}, startPaths);
        start[id] = path && path !== "" ? path : Config.home;
        startPaths = start;
        ids = ids.concat([id]);
    }

    function close(id) {
        ids = ids.filter(i => i !== id);
        if (ids.length === 0) leave.restart();
    }

    Component.onCompleted: open(Quickshell.env("ZEE_FILES_PATH") || Config.home)

    Variants {
        id: wins
        model: app.ids

        FileWindow {
            startPath: app.startPaths[modelData] || Config.home
            onClosed: app.close(modelData)
            onCloseRequested: app.close(modelData)
            onNewWindow: path => app.open(path)
        }
    }

    // Nothing left to show: end the process.
    Timer {
        id: leave
        interval: 250
        onTriggered: if (app.ids.length === 0) Quickshell.execDetached(["kill", String(Quickshell.processId)])
    }

    IpcHandler {
        target: "files"

        function open(path: string): void { app.open(path); }

        // For scripted checks: `ipc call files state`, `ipc call files act <what> <argument>`
        function state(): string {
            const w = wins.instances[0];
            if (!w) return "{}";
            return JSON.stringify({
                windows: app.ids.length, tabs: w.tabs.map((t, i) => Files.nameOf(i === w.current ? w.path : t.path)), current: w.current, path: w.path, count: w.entries.length, names: w.entries.slice(0, 40).map(e => e.name),
                selected: w.chosen.map(Files.nameOf), view: Config.files.view, sort: Config.files.sortBy, filter: w.filter,
                menu: w.menu ? w.menu.items.filter(i => !i.separator).map(i => i.label) : null,
                prompt: w.prompt ? w.prompt.kind : null, typed: w.promptText, busy: Files.busy, message: Files.message, failed: Files.failed,
                clip: Files.clip.mode + ":" + Files.clip.paths.length, back: w.back.length, forward: w.forward.length,
                favourites: Config.files.bookmarks.map(Files.nameOf), drives: Files.drives.map(d => d.label + (d.mount !== "" ? "" : " (off)")), servers: Config.files.servers.length
            });
        }

        function act(what: string, argument: string): void {
            const w = wins.instances[0];
            if (w) w.script(what, argument);
        }
    }
}
