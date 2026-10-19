// WidgetButton.qml — the shared shell for every bar widget: hover highlight,
// tooltip, click buttons and wheel. Widgets declare their visual content as
// children, which are laid out in a centred Row.
//
// The click MouseArea is declared *before* the content Row so the Row stacks on
// top of it. That lets a widget put its own MouseAreas inside the content (tray
// slots, workspace cells) and have them win; a MouseArea declared after the Row
// would sit on top and swallow every click first.

import QtQuick

Item {
    id: wb
    required property var theme
    property string tooltip: ""
    property int padH: 6
    property int spacing: 6
    property bool highlight: true
    default property alias content: row.data

    signal pressed(int button)
    signal wheelMoved(int steps)

    implicitWidth: row.implicitWidth + 2 * padH
    implicitHeight: theme.barHeight - 8
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: 6
        color: wb.highlight && hover.hovered ? wb.theme.fillHover : "transparent"
    }

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (hovered && wb.tooltip !== "")
                wb.theme.showTooltip(wb.tooltip, wb.mapToItem(null, wb.width / 2, 0).x, 0)
            else if (!hovered)
                wb.theme.hideTooltip()
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (mouse) => wb.pressed(mouse.button)
        onWheel: (wheel) => wb.wheelMoved(wheel.angleDelta.y > 0 ? 1 : -1)
        onEntered: if (wb.tooltip !== "") wb.theme.showTooltip(wb.tooltip, wb.mapToItem(null, wb.width / 2, 0).x, 0)
        onExited: wb.theme.hideTooltip()
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: wb.spacing
    }
}
