// BatteryWidget.qml

import QtQuick
import "Icons.js" as Icons

WidgetButton {
    id: battery
    visible: battery.theme.hasBattery
    tooltip: battery.theme.batteryPercent + "%"
        + (battery.theme.batteryCharging ? " · charging" : "")
        + (battery.theme.batteryTimeText ? " · " + battery.theme.batteryTimeText : "")

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: battery.theme.batteryIcon()
        color: battery.theme.batteryPercent <= 15 && !battery.theme.batteryCharging
            ? battery.theme.color01 : battery.theme.barFg
        font.family: battery.theme.mono
        font.pixelSize: battery.theme.fontSize + 3
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: battery.theme.pad(battery.theme.batteryPercent, 3) + "%"
        color: battery.theme.ink
        font.family: battery.theme.mono
        font.pixelSize: battery.theme.fontSize
    }

    onPressed: (button) => {
        if (button !== Qt.RightButton)
            battery.theme.togglePanel("battery", battery.mapToItem(null, battery.width / 2, 0).x)
    }
}
