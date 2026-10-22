// Bar.qml — one bar surface per monitor. Holds the three islands (left,
// centre, right), the widget registry, edit-mode drag and drop, and the
// tooltip/panel anchor plumbing.

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar
    required property var theme

    readonly property string screenName: bar.screen ? bar.screen.name : ""
    readonly property bool bottom: bar.theme.barPosition === "bottom"
    readonly property bool editing: bar.theme.editMode

    color: "transparent"
    visible: !bar.theme.barHidden
    anchors {
        left: true
        right: true
        top: !bar.bottom
        bottom: bar.bottom
    }
    // The bar is a strip, not a full-height surface. Omarchy's plugin
    // popouts (qs.Ui/KeyboardPanel) read the bar window's height to work out
    // where to put the card, so a full-height bar would push every popup to
    // the bottom of the screen.
    implicitHeight: bar.theme.barReserve
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: bar.theme.barReserve
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "bombshell-bar"
    // Grab the keyboard while editing so Escape can finish the edit.
    WlrLayershell.keyboardFocus: bar.editing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // Only the strip takes input, so clicks below reach the desktop.
    mask: Region {
        x: 0
        y: 0
        width: bar.width
        height: bar.height
    }

    HoverHandler {
        onHoveredChanged: if (hovered && !bar.theme.anyPopupVisible) bar.theme.activatePopupScreen(bar.screen)
    }

    // The `bar` object every Omarchy plugin widget expects. Each monitor has
    // its own bar surface, so each one gets its own shim.
    OmarchyBarShim {
        id: shim
        theme: bar.theme
    }

    // Keyboard handling lives on an inner item because PanelWindow is not a
    // focusable Item.
    Item {
        anchors.fill: parent
        focus: bar.editing
        Keys.onEscapePressed: (event) => {
            if (bar.editing) { bar.theme.exitEditMode(); event.accepted = true }
            else if (bar.theme.anyPopupVisible) { bar.theme.closePopups(); event.accepted = true }
        }
    }

    // ── merged single-surface background ──
    Rectangle {
        id: mergedBg
        visible: !bar.theme.islands
        x: bar.theme.barMargin
        width: parent.width - 2 * bar.theme.barMargin
        y: bar.bottom
            ? parent.height - bar.theme.barMargin - height
            : bar.theme.barMargin
        height: bar.theme.barHeight
        radius: bar.theme.pillRadius
        color: bar.theme.barBg
        border.color: bar.theme.panelBorder
        border.width: 1

        RectangularShadow {
            anchors.fill: parent
            radius: parent.radius
            blur: 10
            spread: 0
            offset: Qt.vector2d(0, bar.bottom ? -2 : 2)
            color: Qt.rgba(0, 0, 0, 0.45)
            z: -1
        }
    }

    // ── islands ──
    component BarIsland: Rectangle {
        id: island
        required property string side
        required property var ids
        property alias row: innerRow

        readonly property bool empty: island.ids.length === 0

        y: bar.bottom
            ? parent.height - bar.theme.barMargin - height
            : bar.theme.barMargin
        height: bar.theme.barHeight
        width: innerRow.implicitWidth + 2 * bar.theme.pillPad
        radius: bar.theme.pillRadius
        visible: !island.empty || bar.editing
        color: bar.theme.islands ? bar.theme.barBg : "transparent"
        border.width: bar.theme.islands ? 1 : 0
        border.color: bar.theme.panelBorder

        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Row {
            id: innerRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: bar.theme.pillPad
            spacing: bar.theme.widgetSpacing

            Repeater {
                model: island.ids

                delegate: WidgetChip {
                    required property string modelData
                    widgetId: modelData
                }
            }

            Text {
                visible: island.empty && bar.editing
                text: "⠿"
                font.family: bar.theme.mono
                font.pixelSize: bar.theme.fontSize + 2
                color: bar.theme.muted
                opacity: 0.55
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    BarIsland {
        id: leftIsland
        side: "left"
        ids: bar.theme.layout.left
        x: bar.theme.barMargin
    }

    BarIsland {
        id: centerIsland
        side: "center"
        ids: bar.theme.layout.center
        x: Math.round((parent.width - width) / 2)
    }

    BarIsland {
        id: rightIsland
        side: "right"
        ids: bar.theme.layout.right
        x: parent.width - bar.theme.barMargin - width
    }

    // ── widget registry ──
    Component { id: cMenu;      MenuWidget      { theme: bar.theme } }
    Component { id: cWorkspaces; WorkspacesWidget { theme: bar.theme } }
    Component { id: cWeather;   WeatherWidget   { theme: bar.theme } }
    Component { id: cClock;     ClockWidget     { theme: bar.theme } }
    Component { id: cCpu;       CpuWidget       { theme: bar.theme } }
    Component { id: cMemory;    MemoryWidget    { theme: bar.theme } }
    Component { id: cVolume;    VolumeWidget    { theme: bar.theme } }
    Component { id: cBattery;   BatteryWidget   { theme: bar.theme } }
    Component { id: cPower;     PowerWidget     { theme: bar.theme } }
    Component { id: cNetwork;   NetworkWidget   { theme: bar.theme } }
    Component { id: cBluetooth; BluetoothWidget { theme: bar.theme } }
    Component { id: cDisplay;   DisplayWidget   { theme: bar.theme } }
    Component { id: cTray;      TrayWidget      { theme: bar.theme } }

    readonly property var registry: ({
        "menu": cMenu,
        "workspaces": cWorkspaces,
        "weather": cWeather,
        "clock": cClock,
        "cpu": cCpu,
        "memory": cMemory,
        "volume": cVolume,
        "battery": cBattery,
        "power": cPower,
        "network": cNetwork,
        "bluetooth": cBluetooth,
        "display": cDisplay,
        "tray": cTray
    })

    function widgetComponent(id) {
        return registry.hasOwnProperty(id) ? registry[id] : null
    }

    // ── widget chip + drag and drop ──
    // A chip holds either one of bombshell's own widgets or an Omarchy
    // plugin widget. Both are the same thing to the bar: a draggable item
    // with an id, so the drag and drop code does not care which it is.
    component WidgetChip: Item {
        id: chip
        required property string widgetId
        readonly property string dragId: chip.widgetId
        readonly property bool isPlugin: bar.theme.isPluginEntry(chip.widgetId)
        readonly property string pluginId: bar.theme.pluginIdOf(chip.widgetId)

        implicitWidth: chip.isPlugin ? pluginLoader.implicitWidth : loader.implicitWidth
        implicitHeight: chip.isPlugin ? pluginLoader.implicitHeight : loader.implicitHeight
        width: implicitWidth
        height: implicitHeight
        // A row lines its children up along its top edge, so a widget shorter
        // than the bar would sit high in it. Centre every chip in the row
        // instead, so bombshell's own widgets and Omarchy's plugin widgets
        // share one line through the middle of the bar.
        anchors.verticalCenter: parent.verticalCenter

        Loader {
            id: loader
            visible: !chip.isPlugin
            anchors.fill: parent
            enabled: !bar.editing
            active: !chip.isPlugin
            sourceComponent: bar.widgetComponent(chip.widgetId)
        }

        // An Omarchy plugin widget, loaded from the plugin's own entry
        // point and handed the bar object it expects. It is only built for
        // the chips that are actually plugins.
        Loader {
            id: pluginLoader
            visible: chip.isPlugin
            anchors.fill: parent
            enabled: !bar.editing
            active: chip.isPlugin
            sourceComponent: Component {
                PluginWidget {
                    theme: bar.theme
                    pluginId: chip.pluginId
                    sourceUrl: bar.theme.pluginUrl(chip.pluginId)
                    settings: bar.theme.pluginSettings(chip.pluginId)
                    barShim: shim
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: bar.editing
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onPressed: (mouse) => {
                var g = chip.mapToItem(null, mouse.x, mouse.y)
                bar.beginDrag(chip, g.x, g.y)
            }
            onPositionChanged: (mouse) => {
                var g = chip.mapToItem(null, mouse.x, mouse.y)
                bar.moveDrag(g.x, g.y)
            }
            onReleased: bar.endDrag()
            onCanceled: bar.cancelDrag()
        }
    }

    property bool dragActive: false
    property bool dragging: false
    property Item dragItem: null
    property string dragId: ""
    property real ghostW: 0
    property real ghostH: 0
    property real ghostX: 0
    property real ghostY: 0
    property string dropSide: "center"

    function beginDrag(item, gx, gy) {
        dragItem = item
        dragId = item.dragId
        ghostW = item.width
        ghostH = item.height
        ghostX = gx - ghostW / 2
        ghostY = gy - ghostH / 2
        clampGhost()
        dropSide = sideAt(gx)
        dragActive = true
        dragging = true
        item.opacity = 0.35
    }

    function moveDrag(gx, gy) {
        ghostX = gx - ghostW / 2
        ghostY = gy - ghostH / 2
        clampGhost()
        dropSide = sideAt(gx)
    }

    // The bar is a strip, so the ghost never leaves it.
    function clampGhost() {
        ghostX = Math.max(0, Math.min(bar.width - ghostW, ghostX))
        ghostY = Math.max(0, Math.min(bar.height - ghostH, ghostY))
    }

    function sideAt(x) {
        var half = bar.width / 2
        if (x < half - bar.width / 6) return "left"
        if (x > half + bar.width / 6) return "right"
        return "center"
    }

    function rowFor(side) {
        if (side === "left") return leftIsland.row
        if (side === "right") return rightIsland.row
        return centerIsland.row
    }

    function indexAt(side, x) {
        var row = bar.rowFor(side)
        var idx = 0
        var kids = row.children
        for (var i = 0; i < kids.length; i++) {
            var c = kids[i]
            if (!c || c.dragId === undefined || c.dragId === bar.dragId) continue
            var cp = c.mapToItem(null, 0, 0)
            if (x > cp.x + c.width / 2) idx++
        }
        return idx
    }

    function endDrag() {
        if (!bar.dragActive) return
        bar.dragActive = false
        if (bar.dragItem) bar.dragItem.opacity = 1
        var centerX = bar.ghostX + bar.ghostW / 2
        var side = bar.dropSide || bar.sideAt(centerX)
        var idx = bar.indexAt(side, centerX)
        var id = bar.dragId
        bar.dragItem = null
        bar.theme.moveWidget(id, side, idx)
        snapTimer.restart()
    }

    function cancelDrag() {
        snapTimer.stop()
        if (bar.dragItem) bar.dragItem.opacity = 1
        bar.dragActive = false
        bar.dragging = false
        bar.dragItem = null
        bar.dragId = ""
    }

    Timer { id: snapTimer; interval: 200; onTriggered: bar.dragging = false }

    Connections {
        target: bar.theme
        function onEditModeChanged() {
            if (!bar.theme.editMode && bar.dragActive) bar.cancelDrag()
        }
    }

    ShaderEffectSource {
        id: ghost
        sourceItem: bar.dragItem
        width: bar.ghostW
        height: bar.ghostH
        x: bar.ghostX
        y: bar.ghostY
        visible: bar.dragging
        z: 500
        opacity: bar.dragActive ? 0.95 : 0.9
        Behavior on x { enabled: !bar.dragActive; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: !bar.dragActive; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }
}
