// TooltipOverlay.qml — a click-through overlay that shows the hovered widget's
// tooltip just below the bar.

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: tip
    required property var theme

    screen: tip.theme.activePopupScreen || tip.theme.primaryScreen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bombshell-tooltip"
    visible: tip.theme.tooltipVisible
    mask: Region { width: 0; height: 0 }

    Rectangle {
        id: bubble
        width: label.implicitWidth + 16
        height: label.implicitHeight + 8
        radius: 6
        color: tip.theme.panelBg
        border.width: 1
        border.color: tip.theme.panelBorder
        x: Math.round(Math.max(4, Math.min(tip.theme.tooltipX - width / 2, tip.width - width - 4)))
        y: tip.theme.barPosition === "bottom"
            ? (tip.height - tip.theme.barReserve - height - 6)
            : (tip.theme.barReserve + 6)

        Text {
            id: label
            anchors.centerIn: parent
            text: tip.theme.tooltipText
            color: tip.theme.ink
            font.family: tip.theme.mono
            font.pixelSize: tip.theme.fontSize - 1
        }
    }
}
