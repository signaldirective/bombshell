// UiToggle.qml — a labelled on/off switch.

import QtQuick

Item {
    id: toggle
    required property var theme
    property string label: ""
    property bool checked: false
    signal toggled(bool value)

    implicitHeight: 30
    width: parent ? parent.width : implicitWidth

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: toggle.label
        color: toggle.theme.ink
        font.family: toggle.theme.mono
        font.pixelSize: toggle.theme.fontSize
    }

    Rectangle {
        id: sw
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        height: 20
        radius: 10
        color: toggle.checked ? toggle.theme.barFg : toggle.theme.trackBg

        Rectangle {
            width: 16
            height: 16
            radius: 8
            color: toggle.theme.paper
            y: 2
            x: toggle.checked ? sw.width - width - 2 : 2
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: toggle.toggled(!toggle.checked)
    }
}
