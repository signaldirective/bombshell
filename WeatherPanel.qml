// WeatherPanel.qml — current conditions, a short forecast, and a location
// field that writes Omarchy's own weather.json (shared with the stock bar).

import QtQuick
import Quickshell
import Quickshell.Wayland
import "Icons.js" as Icons

PanelWindow {
    id: panel
    required property var theme

    screen: panel.theme.activePopupScreen || panel.theme.primaryScreen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bombshell-weather"
    WlrLayershell.keyboardFocus:
        visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: panel.theme.activePanel === "weather" && panel.screen !== null
    onVisibleChanged: if (visible) panel.theme.refreshWeather()

    PanelSurface {
        theme: panel.theme
        anchorX: panel.theme.panelAnchorX
        cardWidth: 300

        UiHeader {
            theme: panel.theme
            title: "Weather"
            trailing: panel.theme.weatherLocationLabel
        }

        Row {
            id: weatherRow
            width: parent.width
            spacing: 14
            Text {
                id: weatherIcon
                anchors.verticalCenter: parent.verticalCenter
                text: panel.theme.weatherReady ? panel.theme.weatherIcon() : Icons.icon("weather")
                color: panel.theme.barFg
                font.family: panel.theme.mono
                font.pixelSize: 34
            }
            Column {
                width: Math.max(0, weatherRow.width - weatherIcon.width - weatherRow.spacing)
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: panel.theme.weatherReady
                        ? (panel.theme.weatherTemp + panel.theme.weatherUnit) : "--°"
                    color: panel.theme.ink
                    font.family: panel.theme.mono
                    font.pixelSize: 22
                    font.bold: true
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: panel.theme.weatherDesc || "Loading…"
                    color: panel.theme.muted
                    font.family: panel.theme.mono
                    font.pixelSize: panel.theme.fontSize
                }
            }
        }

        Text {
            width: parent.width
            visible: panel.theme.weatherReady
            text: "Humidity " + panel.theme.weatherHumidity + "%   Wind "
                + panel.theme.weatherWindKph + " km/h"
            color: panel.theme.muted
            font.family: panel.theme.mono
            font.pixelSize: panel.theme.fontSize - 1
        }

        UiDivider { theme: panel.theme; visible: panel.theme.weatherReady }

        Repeater {
            model: panel.theme.weatherDays
            delegate: UiRow {
                required property var modelData
                theme: panel.theme
                icon: Icons.weatherGlyph(modelData.code)
                label: Qt.formatDate(new Date(modelData.date), "dddd")
                value: {
                    var lo = panel.theme.weatherImperial ? Math.round(modelData.minC * 9 / 5 + 32) : modelData.minC
                    var hi = panel.theme.weatherImperial ? Math.round(modelData.maxC * 9 / 5 + 32) : modelData.maxC
                    return lo + "° / " + hi + "°"
                }
                clickable: false
            }
        }

        UiDivider { theme: panel.theme }
        UiSection { theme: panel.theme; title: "Location" }

        Rectangle {
            width: parent.width
            height: 30
            radius: 6
            color: panel.theme.trackBg

            Text {
                anchors.fill: parent
                anchors.leftMargin: 8
                verticalAlignment: Text.AlignVCenter
                visible: locationInput.text === ""
                text: "Blank = auto-detect"
                color: panel.theme.muted
                font.family: panel.theme.mono
                font.pixelSize: panel.theme.fontSize
            }

            TextInput {
                id: locationInput
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                color: panel.theme.ink
                font.family: panel.theme.mono
                font.pixelSize: panel.theme.fontSize
                selectByMouse: true
                clip: true
                focus: panel.visible
                text: panel.theme.weatherLocationIsAuto ? "" : panel.theme.weatherPlaceName
                onAccepted: panel.theme.setWeatherLocation(locationInput.text)
                Keys.onEscapePressed: panel.theme.closePopups()
            }
        }

        Text {
            width: parent.width
            text: "Type a city and press Enter. Leave blank for IP auto-detect."
            color: panel.theme.muted
            font.family: panel.theme.mono
            font.pixelSize: panel.theme.fontSize - 1
        }
    }
}
