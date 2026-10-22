// PluginWidget.qml — hosts one Omarchy plugin bar widget inside bombshell.
//
// The widget is loaded from the plugin's own entry point, so it brings its
// own imports with it. bombshell hands it the three things the stock bar
// hands every widget: the `bar` object, the plugin id, and the settings the
// shell keeps for it in shell.json.
//
// A plugin that cannot be loaded shows a small warning mark instead of
// nothing at all, so a widget that was asked for but did not arrive is
// visible rather than mysterious.

import QtQuick

Item {
    id: host

    required property var theme
    required property string pluginId

    // The plugin's entry point, as a file:// URL.
    property string sourceUrl: ""
    // The plugin's settings from shell.json.
    property var settings: ({})
    // The `bar` object the widget is handed.
    property var barShim: null
    // A readable name, used in the warning mark's tooltip.
    property string label: ""

    property var loadedItem: null

    readonly property bool failed: loader.status === Loader.Error
    readonly property bool ready: loader.status === Loader.Ready

    implicitWidth: host.ready
        ? Math.max(0, loader.item.implicitWidth)
        : (host.failed ? 18 : 0)
    implicitHeight: host.ready
        ? Math.max(0, loader.item.implicitHeight)
        : host.theme.barHeight - 8

    Loader {
        id: loader
        active: host.sourceUrl !== ""
        source: host.sourceUrl
        onLoaded: {
            var item = loader.item
            if (!item) return
            host.loadedItem = item
            if ("bar" in item) item.bar = host.barShim
            if ("moduleName" in item) item.moduleName = host.pluginId
            if ("settings" in item) item.settings = host.settings
            host.theme.registerPluginWidget(host.pluginId, item)
            console.log("[bombshell] plugin widget loaded:", host.pluginId, "w=" + item.implicitWidth, "h=" + item.implicitHeight)
        }
        onStatusChanged: {
            if (loader.status === Loader.Error)
                console.warn("[bombshell] plugin widget failed to load:", host.pluginId, loader.source)
        }
    }

    // The placeholder for a plugin that would not load.
    Rectangle {
        id: warn
        visible: host.failed
        anchors.centerIn: parent
        width: 16
        height: 16
        radius: 4
        color: host.theme.fillHover
        border.width: 1
        border.color: host.theme.urgent
        Text {
            anchors.centerIn: parent
            text: "!"
            color: host.theme.urgent
            font.family: host.theme.mono
            font.bold: true
            font.pixelSize: host.theme.fontSize
        }
        HoverHandler {
            onHoveredChanged: {
                if (!hovered) {
                    host.theme.hideTooltip()
                    return
                }
                var label = host.label !== "" ? host.label : host.pluginId
                host.theme.showTooltip(label + " could not be loaded",
                                       warn.mapToItem(null, warn.width / 2, 0).x, 0)
            }
        }
    }

    Component.onDestruction: {
        if (host.loadedItem)
            host.theme.unregisterPluginWidget(host.pluginId, host.loadedItem)
    }
}
