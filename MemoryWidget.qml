// MemoryWidget.qml

import QtQuick
import "Icons.js" as Icons

WidgetButton {
    id: memory
    tooltip: "RAM " + memory.theme.memPercent + "% · "
        + (memory.theme.memUsedMiB / 1024).toFixed(1) + " / "
        + (memory.theme.memTotalMiB / 1024).toFixed(1) + " GiB"

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.icon("memory")
        color: memory.theme.barFg
        font.family: memory.theme.mono
        font.pixelSize: memory.theme.fontSize + 1
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: memory.theme.pad(memory.theme.memPercent, 3) + "%"
        color: memory.theme.ink
        font.family: memory.theme.mono
        font.pixelSize: memory.theme.fontSize
    }

    onPressed: (button) => {
        if (button !== Qt.RightButton)
            memory.theme.togglePanel("memory", memory.mapToItem(null, memory.width / 2, 0).x)
    }
}
