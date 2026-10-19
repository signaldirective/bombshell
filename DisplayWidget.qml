// DisplayWidget.qml — left click opens the Display panel, wheel adjusts
// screen brightness.

import QtQuick
import "Icons.js" as Icons

WidgetButton {
    id: display
    tooltip: "Display"

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.icon("display")
        color: display.theme.barFg
        font.family: display.theme.mono
        font.pixelSize: display.theme.fontSize + 1
    }

    onPressed: (button) => {
        if (button !== Qt.RightButton)
            display.theme.togglePanel("display", display.mapToItem(null, display.width / 2, 0).x)
    }

    onWheelMoved: (steps) => display.theme.run("brightnessctl set " + (steps > 0 ? "5%+" : "5%-"))
}
