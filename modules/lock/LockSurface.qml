import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.config
import qs.components
import qs.services

// Everything drawn on a locked screen. Also used by the non-locking preview.
Item {
    id: root

    required property var auth
    property bool preview: false
    property real appear: 0
    property real show: auth.leaving ? 0 : appear

    Component.onCompleted: { appear = 1; field.forceActiveFocus(); }

    Behavior on appear { Anim { ms: 700; curve: Theme.curve.enter } }
    Behavior on show { Anim { ms: 320 } }

    Rectangle { anchors.fill: parent; color: "black" }

    Image {
        id: wall
        anchors.fill: parent
        source: Wallpapers.current !== "" ? "file://" + Wallpapers.current : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(root.width / 2, root.height / 2)
        visible: !Config.lock.blurWallpaper
        scale: 1.08 - 0.08 * root.show
    }

    MultiEffect {
        anchors.fill: wall
        source: wall
        visible: Config.lock.blurWallpaper
        blurEnabled: true
        blur: 1
        blurMax: 64
        scale: wall.scale
        autoPaddingEnabled: false
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.38)
    }

    Item {
        anchors.fill: parent
        opacity: root.show

        // ---- clock ----
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.16 + (1 - root.show) * -30
            spacing: -4

            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Time.time
                size: Math.min(150, root.height * 0.14)
                font.weight: Font.Bold
                font.letterSpacing: -4
                font.features: { "tnum": 1 }
                color: "white"
            }

            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Time.longDate
                size: 22
                font.weight: Font.Medium
                color: Qt.rgba(1, 1, 1, 0.85)
            }
        }

        // ---- sign in ----
        Column {
            id: login
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.56 + (1 - root.show) * 40
            spacing: 14

            Logo { anchors.horizontalCenter: parent.horizontalCenter; size: 72 }

            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: SysInfo.user
                size: 20
                font.weight: Font.Bold
                color: "white"
            }

            Rectangle {
                id: box

                property real shake: 0

                anchors.horizontalCenter: parent.horizontalCenter
                width: 320
                height: 52
                radius: Math.min(Theme.radius.full, 26)
                color: Qt.rgba(1, 1, 1, 0.12)
                border.width: 1.5
                border.color: root.auth.message !== "" ? Theme.danger : field.activeFocus ? Theme.accent : Qt.rgba(1, 1, 1, 0.2)
                transform: Translate { x: box.shake }

                Behavior on border.color { CAnim {} }

                SequentialAnimation {
                    id: shaker
                    NumberAnimation { target: box; property: "shake"; to: -14; duration: 50 }
                    NumberAnimation { target: box; property: "shake"; to: 12; duration: 70 }
                    NumberAnimation { target: box; property: "shake"; to: -8; duration: 70 }
                    NumberAnimation { target: box; property: "shake"; to: 5; duration: 60 }
                    NumberAnimation { target: box; property: "shake"; to: 0; duration: 60 }
                }

                Connections {
                    target: root.auth
                    function onFailure() { field.text = ""; shaker.restart(); }
                }

                Icon {
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    name: "lock-key"
                    size: 19
                    color: Qt.rgba(1, 1, 1, 0.75)
                    visible: !root.auth.busy
                }

                Spinner {
                    x: 17
                    anchors.verticalCenter: parent.verticalCenter
                    size: 20
                    color: "white"
                    visible: root.auth.busy
                }

                TextInput {
                    id: field
                    anchors.fill: parent
                    anchors.leftMargin: 50
                    anchors.rightMargin: 50
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    color: "white"
                    font.family: Theme.font
                    font.pixelSize: 15
                    font.letterSpacing: 3
                    clip: true
                    focus: true
                    enabled: !root.auth.busy
                    onTextChanged: if (text !== "") root.auth.message = ""
                    onAccepted: root.preview ? root.auth.fakeFail() : root.auth.submit(text)

                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: field.text === ""
                        text: root.auth.busy ? "Checking…" : "Password"
                        size: 14
                        color: Qt.rgba(1, 1, 1, 0.5)
                    }
                }

                IconBtn {
                    anchors.right: parent.right
                    anchors.rightMargin: 7
                    anchors.verticalCenter: parent.verticalCenter
                    size: 38
                    icon: "arrow-right"
                    active: field.text !== ""
                    tint: Qt.rgba(1, 1, 1, 0.6)
                    onClicked: field.accepted()
                }
            }

            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                height: 18
                text: root.auth.message !== "" ? root.auth.message : root.preview ? "Preview — press Esc to close" : ""
                color: root.auth.message !== "" ? Theme.danger : Qt.rgba(1, 1, 1, 0.6)
                font.weight: Font.Medium
            }
        }

        // ---- corners ----
        Row {
            visible: Config.lock.showWeather && Weather.ready
            x: 36
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 32
            spacing: 12

            Icon { anchors.verticalCenter: parent.verticalCenter; name: Weather.icon; fill: true; size: 34; color: "white" }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                Txt { text: Weather.tempText + "  " + Weather.description; size: 16; font.weight: Font.DemiBold; color: "white" }
                Txt { text: Weather.city; size: 12; color: Qt.rgba(1, 1, 1, 0.7) }
            }
        }

        Row {
            visible: Config.lock.showMedia && Players.active !== null
            anchors.right: parent.right
            anchors.rightMargin: 36
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 30
            spacing: 12

            ClippingRectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: Players.art !== ""
                width: 52
                height: 52
                radius: Theme.radius.sm
                color: Qt.rgba(1, 1, 1, 0.12)

                Image {
                    anchors.fill: parent
                    source: Players.art
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(104, 104)
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                Txt { anchors.right: parent.right; text: Players.title; width: Math.min(implicitWidth, 320); elide: Text.ElideRight; size: 14; font.weight: Font.DemiBold; color: "white" }
                Txt { anchors.right: parent.right; text: Players.artist; size: 12; color: Qt.rgba(1, 1, 1, 0.7) }
            }

            IconBtn { anchors.verticalCenter: parent.verticalCenter; icon: "skip-back"; fill: true; tint: "white"; onClicked: Players.previous() }
            IconBtn { anchors.verticalCenter: parent.verticalCenter; icon: Players.playing ? "pause" : "play"; fill: true; active: true; size: 40; onClicked: Players.toggle() }
            IconBtn { anchors.verticalCenter: parent.verticalCenter; icon: "skip-forward"; fill: true; tint: "white"; onClicked: Players.next() }
        }
    }
}
