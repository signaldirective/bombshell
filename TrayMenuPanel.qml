// TrayMenuPanel.qml — the tray item's own DBusMenu, rendered in bombshell's
// style. Quickshell cannot show a *native* tray menu (its platform-menu path is
// refused outside QApplication mode), so — like the stock Omarchy bar and
// quickshell-dots — the menu is drawn from the DBusMenu model instead. Nested
// submenus are supported via an opener stack.

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: panel
    required property var theme

    // Stack of QsMenuHandle (root menu + any opened submenu).
    property var menuStack: []
    readonly property var currentHandle:
        panel.menuStack.length > 0 ? panel.menuStack[panel.menuStack.length - 1] : null
    readonly property int maxListHeight: Math.round(panel.height * 0.55)

    function strip(t) { return String(t || "").replace(/_([^_])/g, "$1") }

    screen: panel.theme.activePopupScreen || panel.theme.primaryScreen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bombshell-traymenu"
    WlrLayershell.keyboardFocus:
        visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: panel.theme.activePanel === "traymenu" && panel.screen !== null
    onVisibleChanged: {
        var item = panel.theme.trayMenuItem
        panel.menuStack = (visible && item && item.menu) ? [item.menu] : []
    }

    // PanelWindow is not a focusable Item, so Escape is handled on an inner item.
    Item {
        anchors.fill: parent
        focus: panel.visible
        Keys.onEscapePressed: panel.theme.closePopups()
    }

    QsMenuOpener {
        id: opener
        menu: panel.currentHandle
    }

    MouseArea {
        anchors.fill: parent
        onClicked: panel.theme.closePopups()
    }

    Rectangle {
        id: card
        width: 250
        height: col.implicitHeight + 16
        radius: panel.theme.panelRadius
        color: panel.theme.panelBg
        border.width: 1
        border.color: panel.theme.panelBorder
        x: Math.round(Math.max(6, Math.min(panel.theme.panelAnchorX - width / 2, panel.width - width - 6)))
        y: panel.theme.barPosition === "bottom"
            ? (panel.height - panel.theme.barReserve - 8 - height)
            : (panel.theme.barReserve + 8)

        // Swallow clicks on the card so they don't hit the dismiss layer.
        MouseArea { anchors.fill: parent }

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 2

            Item {
                width: parent.width
                height: 26

                Image {
                    id: appIcon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: source !== ""
                    source: panel.theme.trayMenuItem ? (panel.theme.trayMenuItem.icon || "") : ""
                    sourceSize: Qt.size(16, 16)
                    width: visible ? 16 : 0
                    height: 16
                    smooth: true
                }

                Text {
                    anchors.left: appIcon.right
                    anchors.leftMargin: appIcon.visible ? 8 : 0
                    anchors.right: closeText.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        var it = panel.theme.trayMenuItem
                        if (!it) return "Menu"
                        return it.tooltipTitle || it.title || it.id || "Menu"
                    }
                    color: panel.theme.ink
                    font.family: panel.theme.mono
                    font.pixelSize: panel.theme.fontSize
                    elide: Text.ElideRight
                }

                Text {
                    id: closeText
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u2715"
                    color: panel.theme.muted
                    font.family: panel.theme.mono
                    font.pixelSize: panel.theme.fontSize
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: panel.theme.closePopups()
                    }
                }
            }

            UiDivider { theme: panel.theme }

            UiRow {
                theme: panel.theme
                visible: panel.menuStack.length > 1
                icon: "\u2039"
                label: "Back"
                onClicked: panel.menuStack = panel.menuStack.slice(0, -1)
            }

            Flickable {
                id: flick
                width: parent.width
                height: Math.min(listCol.implicitHeight, panel.maxListHeight)
                contentHeight: listCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                Column {
                    id: listCol
                    width: flick.width
                    spacing: 1

                    Repeater {
                        model: opener.children

                        delegate: Item {
                            id: entry
                            required property var modelData
                            width: listCol.width
                            height: entry.modelData.isSeparator ? 7 : 26

                            Rectangle {
                                visible: entry.modelData.isSeparator
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 1
                                color: panel.theme.sep
                            }

                            Rectangle {
                                visible: !entry.modelData.isSeparator
                                anchors.fill: parent
                                radius: 5
                                color: (entryMa.containsMouse && entry.modelData.enabled)
                                    ? panel.theme.fillHover : "transparent"

                                Text {
                                    id: check
                                    anchors.left: parent.left
                                    anchors.leftMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 12
                                    text: entry.modelData.checkState === Qt.Checked ? "\uf00c" : ""
                                    color: panel.theme.barFg
                                    font.family: panel.theme.mono
                                    font.pixelSize: panel.theme.fontSize - 1
                                }

                                Image {
                                    id: entryIcon
                                    anchors.left: check.right
                                    anchors.leftMargin: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: (entry.modelData.icon || "") !== ""
                                    source: entry.modelData.icon || ""
                                    sourceSize: Qt.size(14, 14)
                                    width: visible ? 14 : 0
                                    height: 14
                                    smooth: true
                                }

                                Text {
                                    anchors.left: entryIcon.right
                                    anchors.leftMargin: 6
                                    anchors.right: arrow.left
                                    anchors.rightMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: panel.strip(entry.modelData.text)
                                    color: entry.modelData.enabled ? panel.theme.ink : panel.theme.muted
                                    font.family: panel.theme.mono
                                    font.pixelSize: panel.theme.fontSize
                                    elide: Text.ElideRight
                                }

                                Text {
                                    id: arrow
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: entry.modelData.hasChildren
                                    text: "\u203a"
                                    color: panel.theme.muted
                                    font.family: panel.theme.mono
                                    font.pixelSize: panel.theme.fontSize + 1
                                }

                                MouseArea {
                                    id: entryMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: entry.modelData.enabled
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (entry.modelData.hasChildren) {
                                            panel.menuStack = panel.menuStack.concat([entry.modelData])
                                        } else {
                                            entry.modelData.triggered()
                                            panel.theme.closePopups()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
