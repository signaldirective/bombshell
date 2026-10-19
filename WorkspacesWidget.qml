// WorkspacesWidget.qml — Hyprland workspaces with four display styles and
// three range modes. Each indicator is its own button: left click focuses that
// workspace, right click cycles the display style.

import QtQuick
import Quickshell
import Quickshell.Hyprland

WidgetButton {
    id: ws
    tooltip: "Workspaces"
    spacing: 3
    padH: 4
    highlight: false                  // each cell highlights itself instead

    readonly property string style: ws.theme.workspaceStyle

    readonly property var workspaceList: {
        var mode = ws.theme.workspaceMode
        var n = (mode === "5") ? 5 : 10
        if (mode === "active") {
            var ids = ({})
            var vals = Hyprland.workspaces.values
            for (var i = 0; i < vals.length; i++)
                if (vals[i].id > 0) ids[vals[i].id] = true
            if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0)
                ids[Hyprland.focusedWorkspace.id] = true
            return Object.keys(ids).map(Number).sort((a, b) => a - b)
        }
        var list = []
        for (var j = 1; j <= n; j++) list.push(j)
        var f = Hyprland.focusedWorkspace
        if (f && f.id > n) list.push(f.id)
        return list
    }

    function isFocused(id) {
        return Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === id
    }

    function isOccupied(id) {
        var vals = Hyprland.workspaces.values
        for (var i = 0; i < vals.length; i++)
            if (vals[i].id === id) return true
        return false
    }

    function cycleStyle() {
        var order = ["numbers", "roman", "kanji", "circles"]
        var i = order.indexOf(ws.style)
        ws.theme.workspaceStyle = order[(i + 1) % order.length]
    }

    Repeater {
        model: ws.workspaceList

        delegate: Item {
            id: cell
            required property int modelData
            readonly property int wid: cell.modelData
            readonly property bool focused: ws.isFocused(wid)
            readonly property bool occupied: ws.isOccupied(wid)

            implicitWidth: Math.max(ws.style === "circles" ? 16 : 20, glyph.implicitWidth + 8)
            implicitHeight: ws.theme.barHeight - 8

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 5
                color: hover.hovered ? ws.theme.fillHover : "transparent"
            }
            HoverHandler { id: hover }

            Text {
                id: glyph
                visible: ws.style !== "circles"
                anchors.centerIn: parent
                text: ws.theme.workspaceLabel(cell.wid)
                font.family: ws.style === "kanji" ? "Noto Sans CJK JP" : ws.theme.mono
                font.pixelSize: ws.theme.fontSize + (cell.focused ? 1 : 0)
                font.bold: cell.focused
                color: cell.focused ? ws.theme.barFg
                    : cell.occupied ? ws.theme.ink
                    : ws.theme.muted
                opacity: cell.focused || cell.occupied ? 1 : 0.6
            }

            Rectangle {
                visible: ws.style === "circles"
                anchors.centerIn: parent
                width: cell.focused ? 12 : 10
                height: cell.focused ? 12 : 10
                radius: width / 2
                color: cell.focused ? ws.theme.seal
                    : cell.occupied ? ws.theme.ink
                    : "transparent"
                border.width: cell.focused || cell.occupied ? 0 : 1.5
                border.color: ws.theme.muted
                opacity: cell.focused || cell.occupied ? 1 : 0.7
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: ws.theme.gotoWorkspace(cell.wid)
            }
        }
    }

    onPressed: (button) => {
        if (button === Qt.RightButton) ws.cycleStyle()
    }
}
