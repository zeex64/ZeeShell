import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.components
import qs.services

// You: name, picture, password and session.
Column {
    spacing: 12
    Component.onCompleted: Device.refresh()

    Card {
        width: parent.width
        height: 116

        ClippingRectangle {
            id: face
            x: 22
            anchors.verticalCenter: parent.verticalCenter
            width: 72
            height: 72
            radius: 36
            color: Theme.accent

            Txt {
                anchors.centerIn: parent
                visible: Device.avatar === ""
                text: Device.user.charAt(0).toUpperCase()
                size: 30
                font.weight: Font.Bold
                color: Theme.accentInk
            }

            Image {
                anchors.fill: parent
                visible: Device.avatar !== ""
                source: Device.avatar !== "" ? "file://" + Device.avatar + "?" + Device.avatarStamp : ""
                sourceSize.width: 160
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
            }
        }

        Column {
            anchors.left: face.right
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Txt { text: Device.fullName !== "" ? Device.fullName : Device.user; size: 22; font.weight: Font.Bold }
            Txt { text: Device.user + (Device.host !== "" ? " on " + Device.host : ""); color: Theme.textDim }
        }
    }

    Group {
        title: "Picture"

        TextOpt {
            label: "Picture file"
            hint: Device.message !== "" ? Device.message : "The path of an image. It is copied to ~/.face, where login screens and other apps look for it."
            placeholder: "~/Pictures/me.jpg"
            onEdited: v => { if (v.trim() !== "") Device.setAvatar(v); }
        }
    }

    Group {
        title: "Sign-in"

        Opt {
            label: "Password"
            hint: "Opens a terminal running passwd. The shell never sees your password."
            Btn { text: "Change"; icon: "key"; kind: "ghost"; onClicked: Device.runInTerminal("passwd") }
        }

        Opt {
            label: "Lock screen"
            hint: "What it shows, and a preview"
            Btn { text: "Lock screen settings"; icon: "lock"; kind: "ghost"; onClicked: Ui.settingsPage = "lock" }
        }
    }

    Group {
        title: "Session"

        Opt {
            label: "Leave"
            Btn { text: "Lock"; icon: "lock"; kind: "ghost"; onClicked: { Ui.settingsOpen = false; Ui.locked = true; } }
            Btn { text: "Power menu"; icon: "power"; onClicked: { Ui.settingsOpen = false; Ui.show("power"); } }
        }
    }
}
