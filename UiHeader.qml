// UiHeader.qml — a panel title with an optional trailing hint and close button.

import QtQuick

Item {
    id: header
    required property var theme
    property string title: ""
    property string trailing: ""

    implicitHeight: 26
    width: parent ? parent.width : implicitWidth

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: header.title
        color: header.theme.ink
        font.family: header.theme.mono
        font.pixelSize: header.theme.fontSize + 1
        font.bold: true
    }

    Text {
        anchors.right: closeBtn.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: header.trailing
        color: header.theme.muted
        font.family: header.theme.mono
        font.pixelSize: header.theme.fontSize - 1
    }

    UiButton {
        id: closeBtn
        theme: header.theme
        icon: "✕"
        padH: 6
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        onClicked: header.theme.closePopups()
    }
}
