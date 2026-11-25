import Quickshell
import Quickshell.Services.Polkit
import QtQuick
import qs.config
import qs.components
import qs.services

// The shell's own polkit agent: the password prompt apps get when they ask
// for admin rights (pkexec, installers, disk tools, Settings itself).
// If another agent already serves the session this one stays out of the way.
Scope {
    id: scope

    readonly property var flow: agent.flow
    readonly property bool registered: agent.isRegistered
    property string notice: "" // "Wrong password" after a failed try

    PolkitAgent {
        id: agent
    }

    Connections {
        target: scope.flow
        ignoreUnknownSignals: true
        function onAuthenticationFailed() { scope.notice = "That password did not work. Try again."; }
        function onAuthenticationSucceeded() { scope.notice = ""; }
        function onAuthenticationRequestCancelled() { scope.notice = ""; }
    }

    onFlowChanged: notice = ""

    Overlay {
        id: ov

        open: agent.isActive && scope.flow !== null && !scope.flow.isCompleted
        layerName: "polkit"
        dim: true
        screen: Ui.focusedScreen()
        onDismiss: if (scope.flow) scope.flow.cancelAuthenticationRequest()

        Item {
            id: root

            readonly property Item panel: sheet
            readonly property var flow: scope.flow
            readonly property bool asking: flow !== null && flow.isResponseRequired
            readonly property var who: flow ? flow.selectedIdentity : null
            readonly property string whoName: who ? (who.displayName || who.name || "") : ""
            readonly property string prompt: {
                const p = flow ? String(flow.inputPrompt || "").replace(/:\s*$/, "").trim() : "";
                return p === "" || /^password$/i.test(p) ? "Password" : p;
            }

            function submit() {
                if (!asking) return;
                scope.notice = "";
                flow.submit(pass.text);
                pass.text = "";
            }

            Connections {
                target: scope
                function onNoticeChanged() { if (scope.notice !== "") shake.restart(); }
            }

            Panel {
                id: sheet

                anchors.centerIn: parent
                anchors.verticalCenterOffset: (1 - ov.progress) * 30
                width: 460
                height: body.implicitHeight + 56
                opacity: ov.progress
                scale: 0.95 + 0.05 * ov.progress

                transform: Translate { id: nudge }

                SequentialAnimation {
                    id: shake
                    loops: 1
                    NumberAnimation { target: nudge; property: "x"; to: -10; duration: 50 }
                    NumberAnimation { target: nudge; property: "x"; to: 10; duration: 80 }
                    NumberAnimation { target: nudge; property: "x"; to: -6; duration: 70 }
                    NumberAnimation { target: nudge; property: "x"; to: 0; duration: 60 }
                }

                Column {
                    id: body

                    x: 28
                    y: 28
                    width: parent.width - 56
                    spacing: 14

                    Rectangle {
                        width: 52
                        height: 52
                        radius: Theme.radius.md
                        color: Theme.accentSoft

                        Icon {
                            anchors.centerIn: parent
                            name: "shield-check"
                            fill: true
                            size: 28
                            color: Theme.softInk
                        }
                    }

                    Txt {
                        text: "Authentication required"
                        size: 19
                        font.weight: Font.DemiBold
                    }

                    Txt {
                        width: parent.width
                        text: root.flow ? root.flow.message : ""
                        wrapMode: Text.Wrap
                        color: Theme.textDim
                        visible: text !== ""
                    }

                    // Who is signing in, when more than one account can.
                    Flow {
                        width: parent.width
                        spacing: 6
                        visible: root.flow !== null && root.flow.identities.length > 1

                        Repeater {
                            model: root.flow ? root.flow.identities : []

                            Chip {
                                required property var modelData
                                icon: "user"
                                text: modelData.displayName || modelData.name || "?"
                                active: root.who === modelData
                                onClicked: root.flow.selectedIdentity = modelData
                            }
                        }
                    }

                    Txt {
                        visible: root.whoName !== "" && !(root.flow && root.flow.identities.length > 1)
                        text: "As " + root.whoName
                        size: 12
                        color: Theme.textMute
                    }

                    Field {
                        id: pass
                        width: parent.width
                        implicitHeight: 46
                        icon: "lock-key"
                        password: !(root.flow && root.flow.responseVisible)
                        placeholder: root.prompt
                        autoFocus: true
                        enabled: root.asking
                        opacity: root.asking ? 1 : 0.6
                        onAccepted: root.submit()
                    }

                    Txt {
                        width: parent.width
                        readonly property bool err: scope.notice !== "" || (root.flow && root.flow.supplementaryIsError)
                        text: scope.notice !== "" ? scope.notice : root.flow ? root.flow.supplementaryMessage : ""
                        visible: text !== ""
                        wrapMode: Text.Wrap
                        size: 12.5
                        color: err ? Theme.danger : Theme.textDim
                    }

                    Item {
                        width: parent.width
                        height: 40

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            visible: root.flow !== null && !root.asking

                            Spinner { anchors.verticalCenter: parent.verticalCenter; size: 16 }
                            Txt { anchors.verticalCenter: parent.verticalCenter; text: "Checking…"; color: Theme.textDim }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Btn {
                                text: "Cancel"
                                kind: "ghost"
                                onClicked: if (root.flow) root.flow.cancelAuthenticationRequest()
                            }

                            Btn {
                                text: "Authenticate"
                                kind: "filled"
                                enabled: root.asking && pass.text !== ""
                                onClicked: root.submit()
                            }
                        }
                    }
                }
            }
        }
    }
}
