// WeatherWidget.qml

import QtQuick
import "Icons.js" as Icons

WidgetButton {
    id: weather
    tooltip: weather.theme.weatherReady
        ? (weather.theme.weatherDesc + (weather.theme.weatherLocation ? " · " + weather.theme.weatherLocation : ""))
        : "Weather"

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: weather.theme.weatherIcon()
        color: weather.theme.barFg
        font.family: weather.theme.mono
        font.pixelSize: weather.theme.fontSize + 2
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: weather.theme.weatherReady
            ? (weather.theme.pad(weather.theme.weatherTemp, 3) + weather.theme.weatherUnit) : " --°"
        color: weather.theme.ink
        font.family: weather.theme.mono
        font.pixelSize: weather.theme.fontSize
    }

    onPressed: (button) => {
        if (button === Qt.RightButton) weather.theme.refreshWeather()
        else weather.theme.togglePanel("weather", weather.mapToItem(null, weather.width / 2, 0).x)
    }
}
