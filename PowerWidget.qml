// PowerWidget.qml — power profile indicator; left click opens the profile
// panel, right click cycles to the next profile.

import QtQuick

WidgetButton {
    id: power
    tooltip: "Power profile: " + power.theme.powerProfileLabel(power.theme.powerProfileName())

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: power.theme.powerProfileIcon(power.theme.powerProfileName())
        color: power.theme.barFg
        font.family: power.theme.mono
        font.pixelSize: power.theme.fontSize + 1
    }

    function cycle() {
        var order = ["power-saver", "balanced", "performance"]
        var i = order.indexOf(power.theme.powerProfileName())
        power.theme.setPowerProfile(order[(i + 1) % order.length])
    }

    onPressed: (button) => {
        if (button === Qt.RightButton) power.cycle()
        else power.theme.togglePanel("power", power.mapToItem(null, power.width / 2, 0).x)
    }
}
