// ContentsPanel.qml — the "bar contents" submenu.
//
// Two lists live here. The first is bombshell's own widgets: each one can be
// switched off, which is how a plugin is prevented from showing up twice.
// The second is the Omarchy plugins that offer a bar widget: each one picks
// the island it lands in, or is switched off.
//
// Plugins are off until they are picked, because bombshell already ships
// equivalents for most of them.

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: panel
    required property var theme

    screen: panel.theme.activePopupScreen || panel.theme.primaryScreen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bombshell-contents"
    visible: panel.theme.activePanel === "contents"

    readonly property int listHeight: Math.max(120, Math.min(
        340, (panel.screen ? panel.screen.height : 800) - panel.theme.barReserve - 140))

    // The filter for the plugin list.
    property string filter: ""

    readonly property var shownPlugins: {
        var q = panel.filter.trim().toLowerCase()
        var all = panel.theme.omarchyPlugins
        if (q === "") return all
        var out = []
        for (var i = 0; i < all.length; i++) {
            var p = all[i]
            var name = String(p.name || "").toLowerCase()
            var id = String(p.id || "").toLowerCase()
            var category = String(p.category || "").toLowerCase()
            if (name.indexOf(q) >= 0 || id.indexOf(q) >= 0 || category.indexOf(q) >= 0)
                out.push(p)
        }
        return out
    }

    PanelSurface {
        theme: panel.theme
        anchorX: panel.theme.panelAnchorX
        cardWidth: 340
        cardHeight: panel.theme.panelPad * 2 + 26 + 8 + panel.listHeight

        UiHeader {
            theme: panel.theme
            title: "Bar contents"
        }

        Item {
            id: scrollHost
            width: parent.width
            height: panel.listHeight

            Flickable {
                id: flick
                anchors.fill: parent
                contentWidth: width
                contentHeight: list.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: list
                    width: flick.width
                    spacing: 2

                    UiSection { theme: panel.theme; title: "Bombshell widgets" }

                    Repeater {
                        model: panel.theme.allWidgets

                        delegate: Item {
                            id: widgetRow
                            required property string modelData
                            readonly property bool on: panel.theme.widgetVisible(widgetRow.modelData)

                            width: flick.width
                            height: 26

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 4
                                anchors.right: sw.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: panel.theme.widgetLabel(widgetRow.modelData)
                                color: widgetRow.on ? panel.theme.ink : panel.theme.muted
                                font.family: panel.theme.mono
                                font.pixelSize: panel.theme.fontSize
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                id: sw
                                anchors.right: parent.right
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                height: 16
                                radius: 8
                                color: widgetRow.on ? panel.theme.barFg : panel.theme.trackBg

                                Rectangle {
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: panel.theme.paper
                                    y: 2
                                    x: widgetRow.on ? sw.width - width - 2 : 2
                                    Behavior on x {
                                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: panel.theme.setItemVisible(widgetRow.modelData, !widgetRow.on)
                                }
                            }
                        }
                    }

                    UiDivider { theme: panel.theme }

                    UiSection { theme: panel.theme; title: "Omarchy plugins" }

                    // A filter, because most installations have a lot of them.
                    Rectangle {
                        width: flick.width
                        height: 26
                        radius: 6
                        color: panel.theme.trackBg

                        TextInput {
                            id: filterInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            text: panel.filter
                            onTextChanged: panel.filter = text
                            color: panel.theme.ink
                            selectionColor: panel.theme.fillActive
                            selectedTextColor: panel.theme.ink
                            font.family: panel.theme.mono
                            font.pixelSize: panel.theme.fontSize - 1
                            selectByMouse: true

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: filterInput.text === ""
                                text: "Filter plugins"
                                color: panel.theme.muted
                                font.family: panel.theme.mono
                                font.pixelSize: panel.theme.fontSize - 1
                            }
                        }
                    }

                    Text {
                        width: flick.width
                        visible: panel.theme.omarchyPlugins.length === 0
                        height: visible ? implicitHeight : 0
                        text: "No plugin widgets found."
                        color: panel.theme.muted
                        font.family: panel.theme.mono
                        font.pixelSize: panel.theme.fontSize - 1
                    }

                    Text {
                        width: flick.width
                        visible: panel.theme.omarchyPlugins.length > 0
                            && panel.shownPlugins.length === 0
                        height: visible ? implicitHeight : 0
                        text: "Nothing matches the filter."
                        color: panel.theme.muted
                        font.family: panel.theme.mono
                        font.pixelSize: panel.theme.fontSize - 1
                    }

                    Repeater {
                        model: panel.shownPlugins

                        delegate: Item {
                            id: pluginRow
                            required property var modelData

                            width: flick.width
                            height: 26

                            // A mark for the plugins that are live in the
                            // stock Omarchy bar as well.
                            Item {
                                id: liveMark
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: pluginRow.modelData.enabled === true ? 12 : 0
                                height: 12

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 5
                                    height: 5
                                    radius: 3
                                    color: panel.theme.green
                                }

                                HoverHandler {
                                    onHoveredChanged: {
                                        if (hovered)
                                            panel.theme.showTooltip(
                                                "Also live in the Omarchy bar",
                                                liveMark.mapToItem(null, 0, 0).x, 0)
                                        else
                                            panel.theme.hideTooltip()
                                    }
                                }
                            }

                            Text {
                                anchors.left: liveMark.right
                                anchors.right: seg.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: panel.theme.pluginLabel(pluginRow.modelData.id)
                                elide: Text.ElideRight
                                color: panel.theme.ink
                                font.family: panel.theme.mono
                                font.pixelSize: panel.theme.fontSize
                            }

                            UiSegment {
                                id: seg
                                anchors.right: parent.right
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                theme: panel.theme
                                current: panel.theme.pluginSide(pluginRow.modelData.id)
                                segments: [
                                    { v: "off", l: "off" },
                                    { v: "left", l: "L" },
                                    { v: "center", l: "C" },
                                    { v: "right", l: "R" }
                                ]
                                onPicked: (v) => panel.theme.setPluginSide(pluginRow.modelData.id, v)
                            }
                        }
                    }
                }
            }

            // A scroll indicator, so it is clear the list goes on.
            Rectangle {
                visible: flick.contentHeight > flick.height
                anchors.right: parent.right
                anchors.rightMargin: 1
                width: 3
                radius: 1.5
                color: panel.theme.sep
                height: Math.max(24, flick.height * (flick.height / flick.contentHeight))
                y: flick.contentY * (flick.height / flick.contentHeight)
                z: 10
            }
        }
    }
}
