// UiSlider.qml — a value slider (0..1). Emits `moved` on release.

import QtQuick

Item {
    id: slider
    required property var theme
    property real value: 0
    signal moved(real value)

    implicitHeight: 28
    property real _v: Math.max(0, Math.min(1, value))
    property bool _dragging: false

    onValueChanged: if (!slider._dragging) slider._v = Math.max(0, Math.min(1, value))

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: slider.theme.trackBg
    }

    Rectangle {
        id: fill
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: slider.theme.barFg
        width: Math.round(slider._v * track.width)
    }

    Rectangle {
        id: knob
        width: 12
        height: 12
        radius: 6
        color: slider.theme.ink
        anchors.verticalCenter: parent.verticalCenter
        x: Math.round(slider._v * track.width - width / 2 + track.x)
    }

    MouseArea {
        id: area
        anchors.fill: parent
        function update(m) {
            slider._v = Math.max(0, Math.min(1, m.x / Math.max(1, area.width)))
        }
        onPressed: (m) => { slider._dragging = true; update(m) }
        onPositionChanged: (m) => { if (pressed) update(m) }
        onReleased: { slider._dragging = false; slider.moved(slider._v) }
        onCanceled: slider._dragging = false
    }
}
