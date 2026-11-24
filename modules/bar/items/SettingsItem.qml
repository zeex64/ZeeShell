import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.bar

BarItem {
    pad: 10
    active: Ui.settingsOpen
    onClicked: Ui.settings()

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: "gear"
        size: 17
        color: Theme.text
    }
}
