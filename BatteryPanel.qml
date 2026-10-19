// BatteryPanel.qml

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
    WlrLayershell.namespace: "bombshell-battery"
    visible: panel.theme.activePanel === "battery" && panel.screen !== null

    readonly property string stateText: {
        switch (panel.theme.batteryState) {
            case 1: return "Charging"
            case 2: return "Discharging"
            case 3: return "Empty"
            case 4: return "Fully charged"
        }
        return "Unknown"
    }

    PanelSurface {
        theme: panel.theme
        anchorX: panel.theme.panelAnchorX
        cardWidth: 280

        UiHeader { theme: panel.theme; title: "Battery" }

        Text {
            width: parent.width
            visible: !panel.theme.hasBattery
            text: "No battery detected"
            color: panel.theme.muted
            font.family: panel.theme.mono
            font.pixelSize: panel.theme.fontSize
        }

        Row {
            width: parent.width
            visible: panel.theme.hasBattery
            spacing: 12
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: panel.theme.batteryIcon()
                color: panel.theme.barFg
                font.family: panel.theme.mono
                font.pixelSize: 34
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: panel.theme.batteryPercent + "%"
                color: panel.theme.ink
                font.family: panel.theme.mono
                font.pixelSize: 26
                font.bold: true
            }
        }

        UiDivider { theme: panel.theme; visible: panel.theme.hasBattery }

        UiRow {
            theme: panel.theme
            visible: panel.theme.hasBattery
            label: "State"
            value: panel.stateText
            clickable: false
        }
        UiRow {
            theme: panel.theme
            visible: panel.theme.hasBattery && panel.theme.batteryTimeText !== ""
            label: panel.theme.batteryCharging ? "Time to full" : "Time remaining"
            value: panel.theme.batteryTimeText
            clickable: false
        }
        UiRow {
            theme: panel.theme
            visible: panel.theme.hasBattery && panel.theme.batteryHealth > 0
            label: "Health"
            value: Math.round(panel.theme.batteryHealth) + "%"
            clickable: false
        }
        UiRow {
            theme: panel.theme
            visible: panel.theme.hasBattery
            label: "Power source"
            value: panel.theme.onBattery ? "Battery" : "AC"
            clickable: false
        }
    }
}
