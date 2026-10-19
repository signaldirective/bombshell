// CalendarPanel.qml — month calendar opened from the clock.

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: panel
    required property var theme

    property int monthOffset: 0
    property date today: new Date()

    readonly property date view: new Date(panel.today.getFullYear(), panel.today.getMonth() + panel.monthOffset, 1)
    readonly property int monthDays: new Date(panel.view.getFullYear(), panel.view.getMonth() + 1, 0).getDate()
    readonly property int lead: (panel.view.getDay() + 6) % 7     // Monday-first
    readonly property var cells: {
        var a = []
        for (var i = 0; i < 42; i++) {
            var d = i - panel.lead + 1
            a.push(d >= 1 && d <= panel.monthDays ? d : 0)
        }
        return a
    }
    screen: panel.theme.activePopupScreen || panel.theme.primaryScreen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bombshell-calendar"
    visible: panel.theme.activePanel === "calendar" && panel.screen !== null
    onVisibleChanged: if (visible) { panel.today = new Date(); panel.monthOffset = 0 }

    PanelSurface {
        theme: panel.theme
        anchorX: panel.theme.panelAnchorX
        cardWidth: 292

        Item {
            width: parent.width
            height: 26
            UiButton {
                theme: panel.theme
                icon: "‹"
                padH: 8
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                onClicked: panel.monthOffset--
            }
            Text {
                anchors.centerIn: parent
                text: Qt.formatDate(panel.view, "MMMM yyyy")
                color: panel.theme.ink
                font.family: panel.theme.mono
                font.pixelSize: panel.theme.fontSize + 1
                font.bold: true
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                UiButton {
                    theme: panel.theme
                    icon: "›"
                    padH: 8
                    onClicked: panel.monthOffset++
                }
                UiButton {
                    theme: panel.theme
                    icon: "✕"
                    padH: 8
                    onClicked: panel.theme.closePopups()
                }
            }
        }

        Row {
            width: parent.width
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                delegate: Text {
                    required property string modelData
                    width: parent.width / 7
                    text: modelData
                    horizontalAlignment: Text.AlignHCenter
                    color: panel.theme.muted
                    font.family: panel.theme.mono
                    font.pixelSize: panel.theme.fontSize - 1
                }
            }
        }

        Grid {
            width: parent.width
            columns: 7
            Repeater {
                model: panel.cells
                delegate: Item {
                    required property int modelData
                    readonly property bool isToday: modelData > 0
                        && modelData === panel.today.getDate()
                        && panel.view.getMonth() === panel.today.getMonth()
                        && panel.view.getFullYear() === panel.today.getFullYear()
                    width: parent.width / 7
                    height: 28
                    Rectangle {
                        anchors.centerIn: parent
                        width: 26
                        height: 24
                        radius: 6
                        color: parent.isToday ? panel.theme.fillActive : "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        text: modelData > 0 ? String(modelData) : ""
                        color: parent.isToday ? panel.theme.barFg : panel.theme.ink
                        opacity: modelData > 0 ? 1 : 0
                        font.family: panel.theme.mono
                        font.pixelSize: panel.theme.fontSize
                        font.bold: parent.isToday
                    }
                }
            }
        }
    }
}
