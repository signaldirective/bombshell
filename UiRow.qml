// UiRow.qml — a clickable list row: optional icon, label, trailing value.

import QtQuick

Item {
    id: row
    required property var theme
    property string icon: ""
    property string iconFont: ""
    property string label: ""
    property string value: ""
    property bool active: false
    property bool clickable: true
    signal clicked()

    implicitHeight: 30
    width: parent ? parent.width : implicitWidth

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: (hover.hovered && row.clickable) || row.active ? row.theme.fillHover : "transparent"
    }

    HoverHandler {
        id: hover
        cursorShape: row.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Text {
            visible: row.icon !== ""
            text: row.icon
            color: row.active ? row.theme.barFg : row.theme.ink
            font.family: row.iconFont !== "" ? row.iconFont : row.theme.mono
            font.pixelSize: row.theme.fontSize + 1
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: row.label
            color: row.active ? row.theme.barFg : row.theme.ink
            font.family: row.theme.mono
            font.pixelSize: row.theme.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: row.value
        color: row.theme.muted
        font.family: row.theme.mono
        font.pixelSize: row.theme.fontSize
    }

    MouseArea {
        anchors.fill: parent
        enabled: row.clickable
        onClicked: row.clicked()
    }
}
