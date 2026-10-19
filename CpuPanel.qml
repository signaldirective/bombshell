// CpuPanel.qml

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: panel
    required property var theme
    property string model: ""

    screen: panel.theme.activePopupScreen || panel.theme.primaryScreen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bombshell-cpu"
    visible: panel.theme.activePanel === "cpu" && panel.screen !== null
    onVisibleChanged: if (visible) modelProc.running = true

    Process {
        id: modelProc
        command: ["bash", "-c", "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ //'"]
        stdout: StdioCollector {
            onStreamFinished: panel.model = this.text.trim()
        }
    }

    PanelSurface {
        theme: panel.theme
        anchorX: panel.theme.panelAnchorX
        cardWidth: 280

        UiHeader { theme: panel.theme; title: "CPU" }

        Text {
            width: parent.width
            text: panel.model || "CPU"
            color: panel.theme.ink
            font.family: panel.theme.mono
            font.pixelSize: panel.theme.fontSize - 1
            wrapMode: Text.WordWrap
        }

        Row {
            width: parent.width
            spacing: 12
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: panel.theme.cpuPercent + "%"
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
                    width: parent.width * panel.theme.cpuPercent / 100
                    height: parent.height
                    radius: 4
                    color: panel.theme.barFg
                }
            }
        }

        UiDivider { theme: panel.theme }

        UiRow { theme: panel.theme; label: "Clock"; value: panel.theme.cpuClockMHz + " MHz"; clickable: false }
        UiRow { theme: panel.theme; label: "Load (1/5/15)"; value: panel.theme.loadAvg; clickable: false }
    }
}
