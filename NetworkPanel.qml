// NetworkPanel.qml — Wi-Fi radio, network list, and wired status.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Networking

PanelWindow {
    id: panel
    required property var theme

    readonly property var networks: {
        var a = panel.theme.wifiNetworks.slice()
        a.sort((x, y) => {
            if (x.connected !== y.connected) return x.connected ? -1 : 1
            return (y.signalStrength || 0) - (x.signalStrength || 0)
        })
        return a
    }

    function signalPct(net) {
        var s = net.signalStrength || 0
        return s <= 1 ? Math.round(s * 100) : Math.round(s)
    }

    screen: panel.theme.activePopupScreen || panel.theme.primaryScreen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bombshell-network"
    visible: panel.theme.activePanel === "network" && panel.screen !== null

    PanelSurface {
        theme: panel.theme
        anchorX: panel.theme.panelAnchorX
        cardWidth: 320

        UiHeader {
            theme: panel.theme
            title: "Network"
            trailing: panel.theme.wiredDevice && panel.theme.wiredDevice.connected ? "Wired" : ""
        }

        UiToggle {
            theme: panel.theme
            label: "Wi-Fi"
            checked: panel.theme.wifiEnabled
            onToggled: (v) => panel.theme.setWifiEnabled(v)
        }

        UiDivider { theme: panel.theme }
        UiSection { theme: panel.theme; title: "Networks" }

        Text {
            width: parent.width
            visible: panel.networks.length === 0
            text: panel.theme.wifiEnabled ? "Scanning…" : "Wi-Fi is off"
            color: panel.theme.muted
            font.family: panel.theme.mono
            font.pixelSize: panel.theme.fontSize
        }

        Repeater {
            model: panel.networks
            delegate: UiRow {
                required property var modelData
                theme: panel.theme
                icon: modelData.connected ? "\uf1eb" : "\uf1eb"
                label: modelData.name
                value: modelData.connected ? "connected" : (panel.signalPct(modelData) + "%")
                active: modelData.connected
                onClicked: {
                    if (modelData.connected) modelData.disconnect()
                    else modelData.connect()
                }
            }
        }

        UiDivider { theme: panel.theme; visible: panel.theme.wiredDevice !== null }
        UiSection {
            theme: panel.theme
            visible: panel.theme.wiredDevice !== null
            title: "Wired"
        }
        UiRow {
            theme: panel.theme
            visible: panel.theme.wiredDevice !== null
            icon: "\ueb2f"
            label: panel.theme.wiredDevice ? (panel.theme.wiredDevice.name || "Ethernet") : ""
            value: panel.theme.wiredDevice && panel.theme.wiredDevice.connected ? "connected" : "disconnected"
            active: panel.theme.wiredDevice !== null && panel.theme.wiredDevice.connected
            clickable: false
        }
    }
}
