// UiSegment.qml — a small segmented control: a row of exclusive choices.
//
// Used for the island a plugin widget lands in. `segments` is a list of
// { v: value, l: label } and `current` is the value that is picked.

import QtQuick

Item {
    id: seg
    required property var theme
    property var segments: []
    property string current: ""
    signal picked(string value)

    implicitWidth: cells.width
    implicitHeight: 22
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        id: track
        anchors.fill: parent
        radius: 6
        color: seg.theme.trackBg
    }

    Row {
        id: cells
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: 22

        Repeater {
            model: seg.segments

            Rectangle {
                id: cell
                required property var modelData
                readonly property bool sel: seg.current === modelData.v

                width: Math.max(24, label.implicitWidth + 10)
                height: 22
                radius: 6
                color: cell.sel ? seg.theme.fillActive
                    : (cellHover.hovered ? seg.theme.fillHover : "transparent")

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: cell.modelData.l
                    color: cell.sel ? seg.theme.barFg : seg.theme.muted
                    font.family: seg.theme.mono
                    font.pixelSize: seg.theme.fontSize - 1
                }

                HoverHandler {
                    id: cellHover
                    cursorShape: Qt.PointingHandCursor
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: seg.picked(cell.modelData.v)
                }
            }
        }
    }
}
