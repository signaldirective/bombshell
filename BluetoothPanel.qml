// BluetoothPanel.qml — radio toggle and paired device control.

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: panel
    required property var theme

    readonly property var devices: {
        var out = []
        var d = panel.theme.btDevices
        for (var i = 0; i < d.length; i++)
            if (d[i].paired || d[i].bonded || d[i].connected) out.push(d[i])
        out.sort((x, y) => (y.connected ? 1 : 0) - (x.connected ? 1 : 0))
        return out
    }

    screen: panel.theme.activePopupScreen || panel.theme.primaryScreen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bombshell-bluetooth"
    visible: panel.theme.activePanel === "bluetooth" && panel.screen !== null

    PanelSurface {
        theme: panel.theme
        anchorX: panel.theme.panelAnchorX
        cardWidth: 320

        UiHeader { theme: panel.theme; title: "Bluetooth" }

        UiToggle {
            theme: panel.theme
            label: "Bluetooth"
            checked: panel.theme.btEnabled
            onToggled: (v) => panel.theme.setBtEnabled(v)
        }

        UiDivider { theme: panel.theme }
        UiSection { theme: panel.theme; title: "Devices" }

        Text {
            width: parent.width
            visible: panel.devices.length === 0
            text: panel.theme.btEnabled ? "No paired devices" : "Bluetooth is off"
            color: panel.theme.muted
            font.family: panel.theme.mono
            font.pixelSize: panel.theme.fontSize
        }

        Repeater {
            model: panel.devices
            delegate: UiRow {
                required property var modelData
                theme: panel.theme
                icon: "\ue1a7"
                label: modelData.name || modelData.deviceName || modelData.address
                value: modelData.connected ? "connected"
                    : modelData.paired ? "paired" : ""
                active: modelData.connected
                onClicked: {
                    if (modelData.connected) modelData.disconnect()
                    else if (modelData.paired) modelData.connect()
                    else modelData.pair()
                }
            }
        }
    }
}
