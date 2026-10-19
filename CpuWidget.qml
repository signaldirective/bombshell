// CpuWidget.qml

import QtQuick
import "Icons.js" as Icons

WidgetButton {
    id: cpu
    tooltip: "CPU " + cpu.theme.cpuPercent + "% · load " + cpu.theme.loadAvg

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.icon("cpu")
        color: cpu.theme.barFg
        font.family: cpu.theme.mono
        font.pixelSize: cpu.theme.fontSize + 1
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: cpu.theme.pad(cpu.theme.cpuPercent, 3) + "%"
        color: cpu.theme.ink
        font.family: cpu.theme.mono
        font.pixelSize: cpu.theme.fontSize
    }

    onPressed: (button) => {
        if (button !== Qt.RightButton)
            cpu.theme.togglePanel("cpu", cpu.mapToItem(null, cpu.width / 2, 0).x)
    }
}
