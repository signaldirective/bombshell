// VolumePanel.qml — master volume, mute, and output device selection.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
    id: panel
    required property var theme

    readonly property var sinks: {
        var out = []
        var nodes = Pipewire.nodes.values
        for (var i = 0; i < nodes.length; i++)
            if (nodes[i].isSink && !nodes[i].isStream) out.push(nodes[i])
        return out
    }
    readonly property int defaultSinkId: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.id : -1

    screen: panel.theme.activePopupScreen || panel.theme.primaryScreen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bombshell-volume"
    visible: panel.theme.activePanel === "volume" && panel.screen !== null

    PanelSurface {
        theme: panel.theme
        anchorX: panel.theme.panelAnchorX
        cardWidth: 300

        UiHeader {
            theme: panel.theme
            title: "Volume"
            trailing: panel.theme.audioSinkName
        }

        Row {
            width: parent.width
            spacing: 10
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: panel.theme.volumeIcon()
                color: panel.theme.barFg
                font.family: panel.theme.mono
                font.pixelSize: panel.theme.fontSize + 6
            }
            UiSlider {
                theme: panel.theme
                width: parent.width - 96
                anchors.verticalCenter: parent.verticalCenter
                value: panel.theme.volume / 100
                onMoved: (v) => panel.theme.setVolume(v * 100)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: panel.theme.volume + "%"
                color: panel.theme.ink
                font.family: panel.theme.mono
                font.pixelSize: panel.theme.fontSize
            }
        }

        UiToggle {
            theme: panel.theme
            label: "Mute"
            checked: panel.theme.audioMuted
            onToggled: panel.theme.toggleMute()
        }

        UiDivider { theme: panel.theme }
        UiSection { theme: panel.theme; title: "Output device" }

        Repeater {
            model: panel.sinks
            delegate: UiRow {
                required property var modelData
                theme: panel.theme
                icon: "\uf025"
                label: modelData.description || modelData.name
                value: modelData.id === panel.defaultSinkId ? "active" : ""
                active: modelData.id === panel.defaultSinkId
                onClicked: panel.theme.run("wpctl set-default " + modelData.id)
            }
        }
    }
}
