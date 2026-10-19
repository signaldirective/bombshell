// NetworkWidget.qml

import QtQuick
import "Icons.js" as Icons

WidgetButton {
    id: network
    tooltip: network.theme.networkConnected
        ? ("Connected: " + (network.theme.networkName() || "yes"))
        : "Network"

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: network.theme.networkIcon()
        color: network.theme.networkConnected ? network.theme.barFg : network.theme.muted
        font.family: network.theme.mono
        font.pixelSize: network.theme.fontSize + 1
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: network.theme.networkConnected && network.theme.networkName() !== ""
        text: network.theme.networkName()
        color: network.theme.ink
        font.family: network.theme.mono
        font.pixelSize: network.theme.fontSize
    }

    onPressed: (button) => {
        if (button === Qt.RightButton) network.theme.run("xdg-terminal-exec nmtui 2>/dev/null || nmtui 2>/dev/null || true")
        else network.theme.togglePanel("network", network.mapToItem(null, network.width / 2, 0).x)
    }
}
