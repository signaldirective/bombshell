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
        id: content
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.right: valueText.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Text {
            id: iconText
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
            // Device names can be long. Keep them inside the row.
            elide: Text.ElideRight
            width: Math.max(0, content.width
                - (iconText.visible ? iconText.width + content.spacing : 0))
        }
    }

    Text {
        id: valueText
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: row.value
        color: row.theme.muted
        font.family: row.theme.mono
        font.pixelSize: row.theme.fontSize
        elide: Text.ElideRight
        width: Math.min(implicitWidth, Math.max(0, row.width * 0.5))
    }

    MouseArea {
        anchors.fill: parent
        enabled: row.clickable
        onClicked: row.clicked()
    }
}
