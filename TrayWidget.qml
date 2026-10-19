// TrayWidget.qml — the system tray.
//
// Quickshell resolves each item's icon into a ready-to-use image:// URL, so it
// is handed straight to Image (re-resolving it with iconPath() is what left the
// slots blank). Items that ask to stay passive are skipped, and a fallback glyph
// keeps a slot visible if an app ships no usable icon.

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

WidgetButton {
    id: tray
    padH: 4
    spacing: 2
    tooltip: ""

    property int revision: 0
    readonly property var shownItems: {
        revision
        var out = []
        var v = SystemTray.items.values
        for (var i = 0; i < v.length; i++)
            if (v[i] && v[i].status !== Status.Passive) out.push(v[i])
        return out
    }
    visible: tray.shownItems.length > 0

    Connections {
        target: SystemTray.items
        function onValuesChanged() { tray.revision++ }
    }

    Repeater {
        model: tray.shownItems

        delegate: Item {
            id: slot
            required property var modelData
            implicitWidth: 22
            implicitHeight: 22

            function tip() {
                return slot.modelData.tooltipTitle
                    || slot.modelData.title
                    || slot.modelData.id || ""
            }

            function iconSource() {
                var ic = slot.modelData.icon || ""
                if (ic === "") ic = slot.modelData.attentionIcon || ""
                return String(ic)
            }

            Rectangle {
                anchors.fill: parent
                radius: 4
                color: hover.hovered ? tray.theme.fillHover : "transparent"
            }

            HoverHandler {
                id: hover
                onHoveredChanged: {
                    if (hovered && slot.tip() !== "")
                        tray.theme.showTooltip(slot.tip(), slot.mapToItem(null, slot.width / 2, 0).x, 0)
                    else if (!hovered)
                        tray.theme.hideTooltip()
                }
            }

            Text {
                anchors.centerIn: parent
                visible: img.status !== Image.Ready
                text: "\uf0c9"
                color: tray.theme.muted
                font.family: tray.theme.mono
                font.pixelSize: tray.theme.fontSize
            }

            Image {
                id: img
                anchors.centerIn: parent
                sourceSize: Qt.size(16, 16)
                source: slot.iconSource()
                smooth: true
                opacity: 0.95
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    var item = slot.modelData
                    if (mouse.button === Qt.MiddleButton) {
                        item.secondaryActivate()
                    } else if (mouse.button === Qt.RightButton) {
                        if (item.hasMenu || item.menu)
                            tray.theme.openTrayMenu(item, slot.mapToItem(null, slot.width / 2, 0).x)
                        else
                            item.activate()
                    } else {
                        item.activate()
                    }
                }
                onWheel: (wheel) => slot.modelData.scroll(wheel.angleDelta.y > 0 ? 1 : -1, false)
            }
        }
    }
}
