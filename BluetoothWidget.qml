// BluetoothWidget.qml

import QtQuick

WidgetButton {
    id: bluetooth
    tooltip: "Bluetooth " + (bluetooth.theme.btEnabled ? "on" : "off")
        + (bluetooth.theme.btConnectedCount > 0 ? " · " + bluetooth.theme.btConnectedCount + " connected" : "")

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: bluetooth.theme.bluetoothIcon()
        color: bluetooth.theme.btEnabled ? bluetooth.theme.barFg : bluetooth.theme.muted
        font.family: bluetooth.theme.mono
        font.pixelSize: bluetooth.theme.fontSize + 2
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: bluetooth.theme.btConnectedCount > 0
        text: String(bluetooth.theme.btConnectedCount)
        color: bluetooth.theme.ink
        font.family: bluetooth.theme.mono
        font.pixelSize: bluetooth.theme.fontSize
    }

    onPressed: (button) => {
        if (button === Qt.RightButton) bluetooth.theme.setBtEnabled(!bluetooth.theme.btEnabled)
        else bluetooth.theme.togglePanel("bluetooth", bluetooth.mapToItem(null, bluetooth.width / 2, 0).x)
    }
}
