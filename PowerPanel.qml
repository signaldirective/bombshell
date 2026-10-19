// PowerPanel.qml — power profile picker.

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: panel
    required property var theme

    readonly property var profiles: panel.theme.hasPerformanceProfile
        ? ["power-saver", "balanced", "performance"]
        : ["power-saver", "balanced"]

    screen: panel.theme.activePopupScreen || panel.theme.primaryScreen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bombshell-power"
    visible: panel.theme.activePanel === "power" && panel.screen !== null

    PanelSurface {
        theme: panel.theme
        anchorX: panel.theme.panelAnchorX
        cardWidth: 240

        UiHeader { theme: panel.theme; title: "Power profile" }

        Repeater {
            model: panel.profiles
            delegate: UiRow {
                required property string modelData
                theme: panel.theme
                icon: panel.theme.powerProfileIcon(modelData)
                label: panel.theme.powerProfileLabel(modelData)
                active: panel.theme.powerProfileName() === modelData
                value: panel.theme.powerProfileName() === modelData ? "active" : ""
                onClicked: panel.theme.setPowerProfile(modelData)
            }
        }

        UiDivider { theme: panel.theme }

        UiRow {
            theme: panel.theme
            label: "Power source"
            value: panel.theme.onBattery ? "Battery" : "AC"
            clickable: false
        }
        UiRow {
            theme: panel.theme
            visible: panel.theme.hasBattery
            label: "Battery"
            value: panel.theme.batteryPercent + "%"
            clickable: false
        }
    }
}
