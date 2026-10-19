// DisplayPanel.qml — brightness, text size, scale and per-display controls
// (the bombshell equivalent of the stock omarchy Display panel).

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Icons.js" as Icons

PanelWindow {
    id: panel
    required property var theme

    property int brightness: 50
    property int textSize: 12
    property string scale: "1"
    property string focusedMonitor: ""
    property var monitors: []

    readonly property var textSizes: [9, 10, 11, 12, 14, 16, 20]
    readonly property var scaleOptions: ["1", "1.25", "1.6", "2", "3", "4"]

    function refresh() {
        brightnessProc.running = false; brightnessProc.running = true
        monitorsProc.running = false; monitorsProc.running = true
        textSizeProc.running = false; textSizeProc.running = true
        scaleProc.running = false; scaleProc.running = true
    }
    function setBrightness(pct) {
        var v = Math.max(1, Math.min(100, Math.round(pct)))
        panel.brightness = v
        panel.theme.run("omarchy-brightness-display --monitor \"" + panel.focusedMonitor + "\" " + v + "%")
    }
    function setTextSize(px) {
        panel.theme.run("omarchy-display-text-size " + px)
        panel.textSize = px
    }
    function setScale(s) {
        panel.theme.run("omarchy-hyprland-monitor-scaling " + s)
        panel.scale = s
    }
    function toggleMonitor(name, enabled) {
        if (enabled) panel.theme.run("hyprctl keyword monitor " + name + ",disable")
        else panel.theme.run("hyprctl keyword monitor " + name + ",preferred,auto,auto")
    }

    screen: panel.theme.activePopupScreen || panel.theme.primaryScreen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bombshell-display"
    visible: panel.theme.activePanel === "display" && panel.screen !== null
    onVisibleChanged: if (visible) panel.refresh()

    Process {
        id: brightnessProc
        command: ["bash", "-c",
            "omarchy-brightness-display --monitor \"$(hyprctl -j monitors | jq -r '.[]|select(.focused==true)|.name')\" 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(this.text.trim(), 10)
                if (!isNaN(v)) panel.brightness = v
            }
        }
    }
    Process {
        id: monitorsProc
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var a = JSON.parse(this.text)
                    var out = []
                    panel.focusedMonitor = ""
                    for (var i = 0; i < a.length; i++) {
                        var m = a[i]
                        out.push({ name: m.name, enabled: m.disabled !== true, focused: m.focused === true })
                        if (m.focused) panel.focusedMonitor = m.name
                    }
                    panel.monitors = out
                } catch (e) {}
            }
        }
    }
    Process {
        id: textSizeProc
        command: ["omarchy-display-text-size"]
        stdout: StdioCollector {
            onStreamFinished: {
                var m = this.text.match(/text size:\s*(\d+)/)
                if (m) panel.textSize = parseInt(m[1], 10)
            }
        }
    }
    Process {
        id: scaleProc
        command: ["omarchy-hyprland-monitor-scaling"]
        stdout: StdioCollector {
            onStreamFinished: {
                var s = this.text.trim()
                if (s !== "") panel.scale = s
            }
        }
    }

    PanelSurface {
        theme: panel.theme
        anchorX: panel.theme.panelAnchorX
        cardWidth: 320

        UiHeader {
            theme: panel.theme
            title: "Display"
            trailing: panel.focusedMonitor
        }

        Row {
            width: parent.width
            spacing: 10
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.icon("brightness")
                color: panel.theme.barFg
                font.family: panel.theme.mono
                font.pixelSize: panel.theme.fontSize + 5
            }
            UiSlider {
                theme: panel.theme
                width: parent.width - 96
                anchors.verticalCenter: parent.verticalCenter
                value: panel.brightness / 100
                onMoved: (v) => panel.setBrightness(v * 100)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: panel.brightness + "%"
                color: panel.theme.ink
                font.family: panel.theme.mono
                font.pixelSize: panel.theme.fontSize
            }
        }

        Text {
            width: parent.width
            text: "Text size"
            color: panel.theme.muted
            font.family: panel.theme.mono
            font.pixelSize: panel.theme.fontSize - 1
        }
        Row {
            width: parent.width
            spacing: 5
            Repeater {
                model: panel.textSizes
                delegate: UiButton {
                    required property int modelData
                    theme: panel.theme
                    label: String(modelData)
                    padH: 8
                    active: panel.textSize === modelData
                    onClicked: panel.setTextSize(modelData)
                }
            }
        }

        Text {
            width: parent.width
            text: "Scale"
            color: panel.theme.muted
            font.family: panel.theme.mono
            font.pixelSize: panel.theme.fontSize - 1
        }
        Row {
            width: parent.width
            spacing: 5
            Repeater {
                model: panel.scaleOptions
                delegate: UiButton {
                    required property string modelData
                    theme: panel.theme
                    label: modelData
                    padH: 8
                    active: panel.scale === modelData
                    onClicked: panel.setScale(modelData)
                }
            }
        }

        UiDivider { theme: panel.theme; visible: panel.monitors.length > 1 }
        UiSection {
            theme: panel.theme
            visible: panel.monitors.length > 1
            title: "Displays"
        }
        Repeater {
            model: panel.monitors
            delegate: UiToggle {
                required property var modelData
                theme: panel.theme
                label: modelData.name + (modelData.focused ? "  •" : "")
                checked: modelData.enabled
                onToggled: (v) => panel.toggleMonitor(modelData.name, v)
            }
        }
    }
}
