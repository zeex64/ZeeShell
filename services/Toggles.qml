pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Small stateful switches that do not belong to a bigger service.
Singleton {
    id: root

    property bool nightLight: false
    property bool caffeine: false

    Process {
        command: ["gammastep", "-P", "-O", String(Config.sidebar.nightTemp)]
        running: root.nightLight
    }
}
