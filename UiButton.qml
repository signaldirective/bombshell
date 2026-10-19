// UiButton.qml — small pill button used across the panels.

import QtQuick

Rectangle {
    id: btn
    required property var theme
    property string icon: ""
    property string label: ""
    property bool active: false
    property bool selected: false
    property int padH: 10
    signal clicked()

    implicitWidth: content.implicitWidth + 2 * padH
    implicitHeight: 28
    radius: 6
    color: selected ? btn.theme.fillActive
        : active ? btn.theme.fillHover
        : (hover.hovered ? btn.theme.fillHover : "transparent")
    border.width: active ? 1 : 0
    border.color: btn.theme.barFg

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6
        Text {
            visible: btn.icon !== ""
            text: btn.icon
            font.family: btn.theme.mono
            font.pixelSize: btn.theme.fontSize + 1
            color: btn.active ? btn.theme.barFg : btn.theme.ink
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: btn.label !== ""
            text: btn.label
            font.family: btn.theme.mono
            font.pixelSize: btn.theme.fontSize
            color: btn.active ? btn.theme.barFg : btn.theme.ink
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: btn.clicked()
    }
}
