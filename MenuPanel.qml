// MenuPanel.qml — the settings menu opened by the bar's menu button.

import QtQuick
import Qt5Compat.GraphicalEffects
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
    WlrLayershell.namespace: "bombshell-menu"
    visible: panel.theme.activePanel === "menu" && panel.screen !== null

    PanelSurface {
        theme: panel.theme
        anchorX: panel.theme.panelAnchorX
        cardWidth: 300

        UiHeader { theme: panel.theme; title: "bombshell" }

        UiSection { theme: panel.theme; title: "Bar" }

        UiRow {
            theme: panel.theme
            icon: "↕"
            label: "Position"
            value: panel.theme.barPosition === "top" ? "Top" : "Bottom"
            onClicked: panel.theme.barPosition = (panel.theme.barPosition === "top" ? "bottom" : "top")
        }
        UiToggle {
            theme: panel.theme
            label: "Islands (three pills)"
            checked: panel.theme.islands
            onToggled: (v) => panel.theme.islands = v
        }
        UiRow {
            theme: panel.theme
            icon: Icons.icon("edit")
            label: "Edit bar"
            value: "drag widgets"
            onClicked: {
                panel.theme.closePopups()
                panel.theme.enterEditMode()
            }
        }
        UiRow {
            theme: panel.theme
            icon: Icons.icon("contents")
            label: "Bar contents"
            value: Icons.icon("chevronRight")
            onClicked: panel.theme.openPanel("contents", panel.theme.panelAnchorX)
        }
        UiRow {
            theme: panel.theme
            icon: Icons.icon("refresh")
            label: "Reset layout"
            onClicked: panel.theme.resetLayout()
        }
        UiRow {
            theme: panel.theme
            label: "Foreground colour"
            value: panel.theme.paletteLabel(panel.theme.barColor)
            clickable: false
        }
        Row {
            width: parent.width
            spacing: 5
            Repeater {
                model: panel.theme.paletteIds
                delegate: Rectangle {
                    required property string modelData
                    width: 20
                    height: 20
                    radius: 5
                    color: panel.theme.paletteColor(modelData)
                    border.width: panel.theme.barColor === modelData ? 2 : 1
                    border.color: panel.theme.barColor === modelData ? panel.theme.ink : panel.theme.sep
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: panel.theme.barColor = modelData
                    }
                }
            }
        }

        UiRow {
            theme: panel.theme
            label: "Menu icon"
            value: panel.theme.menuIconLabel(panel.theme.menuIcon)
            clickable: false
        }
        Flow {
            width: parent.width
            spacing: 4
            Repeater {
                model: panel.theme.menuIconOptions
                delegate: Rectangle {
                    id: cell
                    required property string modelData
                    readonly property bool sel: panel.theme.menuIcon === modelData
                    readonly property bool isImage: panel.theme.menuIconIsImage(modelData)
                    width: 34
                    height: 30
                    radius: 6
                    color: sel ? panel.theme.fillActive
                        : (iconHover.hovered ? panel.theme.fillHover : "transparent")
                    border.width: sel ? 1 : 0
                    border.color: panel.theme.barFg

                    HoverHandler { id: iconHover; cursorShape: Qt.PointingHandCursor }

                    Text {
                        visible: !parent.isImage
                        anchors.centerIn: parent
                        text: panel.theme.menuIconGlyphFor(parent.modelData)
                        font.family: panel.theme.menuIconFontFor(parent.modelData)
                        font.pixelSize: panel.theme.fontSize + 3
                        color: parent.sel ? panel.theme.barFg : panel.theme.ink
                    }
                    Image {
                        id: iconImage
                        anchors.centerIn: parent
                        source: panel.theme.menuIconSourceFor(cell.modelData)
                        sourceSize: Qt.size(64, 64)
                        height: Math.round(panel.theme.fontSize * 1.5)
                        width: height
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        // The bundled icons are white alpha masks. Hide the raw
                        // image and let ColorOverlay paint the theme colour
                        // through its alpha, so they read like the glyphs. A
                        // user-supplied "image" is shown untouched.
                        readonly property bool tint: cell.isImage
                            && panel.theme.menuIconIsTinted(cell.modelData)
                        visible: cell.isImage && !tint
                        layer.enabled: tint
                    }
                    ColorOverlay {
                        visible: cell.isImage
                            && panel.theme.menuIconIsTinted(cell.modelData)
                        anchors.fill: iconImage
                        source: iconImage
                        color: cell.sel ? panel.theme.barFg : panel.theme.ink
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: panel.theme.menuIcon = parent.modelData
                    }
                }
            }
        }

        UiDivider { theme: panel.theme }
        UiSection { theme: panel.theme; title: "Workspaces" }

        Text {
            width: parent.width
            text: "Style"
            color: panel.theme.muted
            font.family: panel.theme.mono
            font.pixelSize: panel.theme.fontSize - 1
        }
        Row {
            width: parent.width
            spacing: 6
            Repeater {
                model: [
                    { v: "numbers", l: "1–0" },
                    { v: "roman", l: "I–X" },
                    { v: "kanji", l: "一–十" },
                    { v: "circles", l: "●" }
                ]
                delegate: UiButton {
                    required property var modelData
                    theme: panel.theme
                    label: modelData.l
                    active: panel.theme.workspaceStyle === modelData.v
                    onClicked: panel.theme.workspaceStyle = modelData.v
                }
            }
        }
        Text {
            width: parent.width
            text: "Range"
            color: panel.theme.muted
            font.family: panel.theme.mono
            font.pixelSize: panel.theme.fontSize - 1
        }
        Row {
            width: parent.width
            spacing: 6
            Repeater {
                model: [
                    { v: "5", l: "1–5" },
                    { v: "10", l: "1–10" },
                    { v: "active", l: "Active only" }
                ]
                delegate: UiButton {
                    required property var modelData
                    theme: panel.theme
                    label: modelData.l
                    active: panel.theme.workspaceMode === modelData.v
                    onClicked: panel.theme.workspaceMode = modelData.v
                }
            }
        }

        UiDivider { theme: panel.theme }
        UiSection { theme: panel.theme; title: "Clock & weather" }
        UiToggle {
            theme: panel.theme
            label: "12-hour clock"
            checked: panel.theme.clock12h
            onToggled: (v) => panel.theme.clock12h = v
        }
        UiToggle {
            theme: panel.theme
            label: "Imperial units"
            checked: panel.theme.weatherImperial
            onToggled: (v) => panel.theme.weatherImperial = v
        }

        UiDivider { theme: panel.theme }
        UiSection { theme: panel.theme; title: "Shell" }
        UiRow {
            theme: panel.theme
            icon: Icons.icon("menu")
            iconFont: panel.theme.logoFont
            label: "Omarchy bar"
            value: "switch"
            onClicked: {
                panel.theme.closePopups()
                panel.theme.run("bash \"" + panel.theme.shellDir + "/scripts/bombshell-toggle.sh\" omarchy")
            }
        }
        UiRow {
            theme: panel.theme
            icon: Icons.icon("power")
            label: "Quit bombshell"
            onClicked: {
                panel.theme.closePopups()
                panel.theme.run("quickshell kill -p \"" + panel.theme.shellDir + "\" --any-display >/dev/null 2>&1 || true")
            }
        }
    }
}
