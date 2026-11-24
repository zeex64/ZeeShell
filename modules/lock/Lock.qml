import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.components
import qs.services

// Session lock. Authentication goes through PAM (assets/pam/zeeshell).
Scope {
    id: root

    property string message: ""
    property string buffer: ""
    property bool leaving: false
    readonly property bool busy: pam.active

    signal failure()

    function submit(password) {
        if (pam.active || password === "") return;
        buffer = password;
        message = "";
        pam.start();
    }

    function fakeFail() {
        message = "Preview only — nothing was checked";
        failure();
    }

    PamContext {
        id: pam

        configDirectory: Quickshell.shellPath("assets/pam")
        config: "zeeshell"

        onPamMessage: {
            if (responseRequired) respond(root.buffer);
            else if (messageIsError && message !== "") root.message = message;
        }

        onCompleted: result => {
            root.buffer = "";
            if (result === PamResult.Success) {
                root.leaving = true;
                release.start();
            } else {
                root.message = result === PamResult.MaxTries ? "Too many attempts" : "Wrong password";
                root.failure();
            }
        }

        onError: e => {
            root.buffer = "";
            root.message = "Authentication failed to start";
            root.failure();
        }
    }

    Timer {
        id: release
        interval: 340
        onTriggered: {
            Ui.locked = false;
            root.leaving = false;
            root.message = "";
        }
    }

    WlSessionLock {
        locked: Ui.locked

        WlSessionLockSurface {
            color: "black"

            LockSurface {
                anchors.fill: parent
                auth: root
            }
        }
    }

    // `ipc call zee lockPreview` shows the lock screen without locking.
    Overlay {
        open: Ui.active === "lockpreview"
        layerName: "lock-preview"
        onDismiss: { root.message = ""; Ui.hide(); }

        Item {
            LockSurface {
                anchors.fill: parent
                auth: root
                preview: true
            }
        }
    }
}
