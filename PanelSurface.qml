// PanelSurface.qml — the shared frame every dropdown panel is drawn inside.
// Fills its panel window with a click-to-dismiss backdrop and positions a card
// under (or above) the bar, centred on the widget that opened it.

import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: surface
    required property var theme
    property real anchorX: 0
    property int cardWidth: 280
    // Set when the content scrolls: the card is sized by hand instead of
    // following the content.
    property int cardHeight: 0
    property int gap: 8
    default property alias content: body.data

    readonly property int barBottom: surface.theme.barReserve

    anchors.fill: parent

    MouseArea {
        anchors.fill: parent
        onClicked: surface.theme.closePopups()
    }

    Rectangle {
        id: caret
        width: 12
        height: 12
        rotation: 45
        color: surface.theme.panelBg
        z: 1
        visible: surface.anchorX > 0
        x: Math.round(card.x + Math.max(10, Math.min(card.width - 22, surface.anchorX - card.x - 6)))
        y: surface.theme.barPosition === "bottom" ? (card.y + card.height - 6) : (card.y - 6)
    }

    Rectangle {
        id: card
        width: surface.cardWidth
        height: surface.cardHeight > 0
            ? surface.cardHeight
            : body.implicitHeight + 2 * surface.theme.panelPad
        radius: surface.theme.panelRadius
        color: surface.theme.panelBg
        border.width: 1
        border.color: surface.theme.panelBorder
        x: Math.round(Math.max(6, Math.min(surface.anchorX - width / 2, surface.width - width - 6)))
        y: surface.theme.barPosition === "bottom"
            ? (surface.height - surface.barBottom - surface.gap - height)
            : (surface.barBottom + surface.gap)

        // Swallow clicks on empty card space so they do not reach the dismiss
        // layer behind the card. Declared before the content so it stays below.
        MouseArea { anchors.fill: parent }

        Column {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: surface.theme.panelPad
            spacing: 8
        }
    }
}
