// ClockWidget.qml — date/time with the Omarchy status indicators revealed on
// hover (dictation, screen recording, reminder, night light, silence
// notifications, stay awake). Left click opens the calendar; right click
// switches between 12h and 24h.

import QtQuick
import "Icons.js" as Icons

Item {
    id: clock
    required property var theme

    property date now: new Date()
    property bool hovered: false
    readonly property bool showIndicators: hovered
    readonly property string timeString: Qt.formatDateTime(now, clock.theme.clock12h ? "hh:mm AP" : "HH:mm")
    readonly property string dateString: Qt.formatDateTime(now, "ddd d MMM")

    implicitWidth: row.implicitWidth + 12
    implicitHeight: clock.theme.barHeight - 8
    width: implicitWidth
    height: implicitHeight

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clock.now = new Date()
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: 6
        color: clock.hovered ? clock.theme.fillHover : "transparent"
    }

    HoverHandler {
        onHoveredChanged: clock.hovered = hovered
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Item {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: labelRow.implicitWidth
            implicitHeight: 20

            Row {
                id: labelRow
                anchors.centerIn: parent
                spacing: 8

                Text {
                    id: timeText
                    anchors.verticalCenter: parent.verticalCenter
                    text: clock.timeString
                    color: clock.theme.barFg
                    font.family: clock.theme.mono
                    font.pixelSize: clock.theme.fontSize + 1
                    font.bold: true
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: clock.dateString
                    color: clock.theme.ink
                    font.family: clock.theme.mono
                    font.pixelSize: clock.theme.fontSize
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton)
                        clock.theme.clock12h = !clock.theme.clock12h
                    else
                        clock.theme.togglePanel("calendar", timeText.mapToItem(null, timeText.width / 2, 0).x)
                }
            }
        }

        Row {
            id: indicators
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            visible: clock.showIndicators
            opacity: clock.showIndicators ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 130 } }

            IndicatorButton {
                theme: clock.theme
                icon: Icons.icon("dictation")
                tip: "Dictate"
                active: clock.theme.voxState === "recording"
                activeColor: clock.theme.color01
                onTriggered: clock.theme.run("voxtype record toggle 2>/dev/null || omarchy-voxtype-config")
            }
            IndicatorButton {
                theme: clock.theme
                icon: Icons.icon("recording")
                tip: "Screen recording"
                active: clock.theme.recording
                activeColor: clock.theme.color01
                onTriggered: clock.theme.run(clock.theme.recording
                    ? "omarchy-capture-screenrecording --stop-recording"
                    : "omarchy-capture-screenrecording")
            }
            IndicatorButton {
                theme: clock.theme
                icon: Icons.icon("reminder")
                tip: "Reminders"
                active: clock.theme.reminders > 0
                badge: clock.theme.reminders
                onTriggered: clock.theme.run(clock.theme.reminders > 0
                    ? "omarchy-reminder show"
                    : "omarchy-reminder -i")
            }
            IndicatorButton {
                theme: clock.theme
                icon: Icons.icon("nightlight")
                tip: "Night light"
                active: clock.theme.nightlight
                onTriggered: clock.theme.run("omarchy-toggle-nightlight")
            }
            IndicatorButton {
                theme: clock.theme
                icon: Icons.icon("dnd")
                tip: "Silence notifications"
                active: clock.theme.dnd
                onTriggered: clock.theme.run("omarchy-toggle-notification-silencing")
            }
            IndicatorButton {
                theme: clock.theme
                icon: Icons.icon("stayAwake")
                tip: "Stay awake"
                active: clock.theme.stayAwake
                onTriggered: clock.theme.run("omarchy-toggle-idle")
            }
        }
    }

    component IndicatorButton: Item {
        id: ib
        required property var theme
        property string icon: ""
        property bool active: false
        property string tip: ""
        property color activeColor: theme.barFg
        property int badge: 0
        signal triggered()

        implicitWidth: 22
        implicitHeight: 22

        Rectangle {
            anchors.fill: parent
            radius: 5
            color: ibHover.hovered ? ib.theme.fillHover : "transparent"
        }
        HoverHandler {
            id: ibHover
            onHoveredChanged: {
                if (hovered) ib.theme.showTooltip(ib.tip, ib.mapToItem(null, ib.width / 2, 0).x, 0)
                else ib.theme.hideTooltip()
            }
        }
        Text {
            anchors.centerIn: parent
            text: ib.icon
            font.family: ib.theme.mono
            font.pixelSize: ib.theme.fontSize + 1
            color: ib.active ? ib.activeColor : ib.theme.muted
            opacity: ib.active ? 1 : 0.7
        }
        Rectangle {
            visible: ib.badge > 0
            width: 12
            height: 12
            radius: 6
            color: ib.theme.barFg
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -2
            anchors.topMargin: -1
            Text {
                anchors.centerIn: parent
                text: String(Math.min(99, ib.badge))
                color: ib.theme.paper
                font.family: ib.theme.mono
                font.pixelSize: 8
                font.bold: true
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ib.triggered()
        }
    }
}
