// MemoryPanel.qml

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: panel
    required property var theme

    screen: panel.theme.activePopupScreen || panel.theme.primaryScreen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bombshell-memory"
    visible: panel.theme.activePanel === "memory" && panel.screen !== null

    function gib(mib) { return (mib / 1024).toFixed(1) + " GiB" }

    PanelSurface {
        theme: panel.theme
        anchorX: panel.theme.panelAnchorX
        cardWidth: 280

        UiHeader { theme: panel.theme; title: "Memory" }

        Row {
            width: parent.width
            spacing: 12
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: panel.theme.memPercent + "%"
                color: panel.theme.barFg
                font.family: panel.theme.mono
                font.pixelSize: 28
                font.bold: true
            }
            Rectangle {
                width: parent.width - 90
                height: 8
                radius: 4
                color: panel.theme.trackBg
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    width: parent.width * panel.theme.memPercent / 100
                    height: parent.height
                    radius: 4
                    color: panel.theme.barFg
                }
            }
        }

        UiDivider { theme: panel.theme }

        UiRow { theme: panel.theme; label: "Used"; value: panel.gib(panel.theme.memUsedMiB); clickable: false }
        UiRow { theme: panel.theme; label: "Total"; value: panel.gib(panel.theme.memTotalMiB); clickable: false }
        UiRow {
            theme: panel.theme
            label: "Free"
            value: panel.gib(Math.max(0, panel.theme.memTotalMiB - panel.theme.memUsedMiB))
            clickable: false
        }
    }
}
