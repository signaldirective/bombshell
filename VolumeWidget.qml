// VolumeWidget.qml — left click opens the mixer, right click mutes, wheel
// adjusts the volume.

import QtQuick
import "Icons.js" as Icons

WidgetButton {
    id: volume
    tooltip: "Volume " + (volume.theme.audioMuted ? "(muted)" : volume.theme.volume + "%")

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: volume.theme.volumeIcon()
        color: volume.theme.audioMuted ? volume.theme.muted : volume.theme.barFg
        font.family: volume.theme.mono
        font.pixelSize: volume.theme.fontSize + 1
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: !volume.theme.audioMuted
        text: volume.theme.pad(volume.theme.volume, 3) + "%"
        color: volume.theme.ink
        font.family: volume.theme.mono
        font.pixelSize: volume.theme.fontSize
    }

    onPressed: (button) => {
        if (button === Qt.RightButton) volume.theme.toggleMute()
        else volume.theme.togglePanel("volume", volume.mapToItem(null, volume.width / 2, 0).x)
    }

    onWheelMoved: (steps) => volume.theme.setVolume(volume.theme.volume + (steps > 0 ? 5 : -5))
}
