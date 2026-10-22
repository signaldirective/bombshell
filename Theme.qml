// Theme.qml — the single shared state object for the bombshell bar.
//
// It owns the palette read from the active Omarchy theme, the persisted bar
// settings (position, islands, foreground colour, workspace style, layout),
// the open-panel/anchor bookkeeping, tooltips, and the small amount of
// telemetry the bar needs that Quickshell does not provide as a service
// (CPU / RAM / indicator flags / weather).
//
// Widgets and panels receive this object as `theme` and read from it directly.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import "Palette.js" as Palette
import "Icons.js" as Icons

Item {
    id: theme

    // ───────────────────────────────── palette ─────────────────────────────────
    // Written by Palette.apply() from the active Omarchy theme's colors.toml.
    property color paper: "#101315"
    property color ink: "#cacccc"
    property color sumi: "#707880"
    property color color01: "#a55555"
    property color color02: "#8a9a73"
    property color color03: "#c4a25a"
    property color color04: "#209edb"
    property color color05: "#a98bd0"
    property color color06: "#66a8a8"
    property color color07: "#cacccc"
    property color accentHint: "#209edb"
    property color green: "#8a9a73"
    // The colour a widget uses to say "this wants attention". The Omarchy
    // plugin widgets read it off the bar object.
    readonly property color urgent: color01

    readonly property string home: Quickshell.env("HOME")
    readonly property string shellDir: Quickshell.shellDir
    readonly property string stateColorsPath: home + "/.local/state/omarchy/current/theme/colors.toml"
    readonly property string configColorsPath: home + "/.config/omarchy/current/theme/colors.toml"
    readonly property string themeNamePath: home + "/.local/state/omarchy/current/theme.name"

    // ───────────────────────────── persisted settings ──────────────────────────
    property string barPosition: "top"          // "top" | "bottom"
    property bool islands: false                // split the bar into 3 pills
    property string barColor: "accent"          // palette slot for bar foreground
    property bool clock12h: false
    property bool weatherImperial: false
    property string workspaceMode: "10"         // "5" | "10" | "active"
    property string workspaceStyle: "numbers"   // numbers | roman | kanji | circles
    property string menuIcon: "bomb"            // see menuIconOptions
    property string menuIconImage: shellDir + "/assets/menu/starfleet.png"
    property var layout: theme.defaultLayout()
    // Built-in widgets that are switched off. They keep their place in
    // `prefs` so switching them back on puts them where they were.
    property var hidden: []
    // entry -> island, for entries whose island has to survive being hidden.
    property var prefs: ({})
    property bool _loaded: false

    readonly property string stateDir: home + "/.cache/bombshell"
    readonly property string statePath: stateDir + "/state.json"

    // Entries in the layout are either a built-in widget id or a plugin,
    // written as "plugin:<plugin id>".
    readonly property string pluginPrefix: "plugin:"

    // The catalogue of Omarchy plugins that offer a bar widget. It fills in
    // asynchronously, so it is empty for the first moment of the run.
    readonly property var omarchyPlugins: pluginRegistry.plugins

    readonly property var allWidgets: [
        "menu", "workspaces", "weather", "clock", "cpu", "memory", "volume",
        "battery", "power", "network", "bluetooth", "display", "tray"
    ]
    readonly property var widgetDefaults: ({
        "menu": "left", "workspaces": "left",
        "weather": "center", "clock": "center",
        "cpu": "right", "memory": "right", "volume": "right", "battery": "right",
        "power": "right", "network": "right", "bluetooth": "right",
        "display": "right", "tray": "right"
    })
    // Readable names for the built-in widgets, used by the contents menu.
    readonly property var widgetLabels: ({
        "menu": "Menu", "workspaces": "Workspaces", "weather": "Weather",
        "clock": "Clock", "cpu": "CPU", "memory": "Memory", "volume": "Volume",
        "battery": "Battery", "power": "Power", "network": "Network",
        "bluetooth": "Bluetooth", "display": "Display", "tray": "Tray"
    })
    readonly property var paletteIds: [
        "accent", "color01", "color02", "color03", "color04", "color05",
        "color06", "color07", "foreground", "muted"
    ]

    function defaultLayout() {
        return {
            left: ["menu", "workspaces"],
            center: ["weather", "clock"],
            right: ["cpu", "memory", "network", "bluetooth", "volume",
                    "display", "power", "battery", "tray"]
        }
    }

    // A readable name for a built-in widget.
    function widgetLabel(id) {
        return theme.widgetLabels[id] || id
    }

    // ── layout entries ──────────────────────────────────────────────────
    function isPluginEntry(entry) {
        return String(entry).indexOf(theme.pluginPrefix) === 0
    }

    function pluginIdOf(entry) {
        return isPluginEntry(entry) ? String(entry).substring(theme.pluginPrefix.length) : ""
    }

    function pluginEntry(pluginId) {
        return theme.pluginPrefix + pluginId
    }

    function isKnownEntry(entry) {
        return theme.allWidgets.indexOf(entry) >= 0 || theme.isPluginEntry(entry)
    }

    // ── plugin catalogue ─────────────────────────────────────────────────
    // The plugin's entry point, as a file:// URL.
    function pluginUrl(pluginId) {
        return pluginRegistry.urlFor(pluginId)
    }

    // The settings Omarchy's shell.json keeps for the plugin.
    function pluginSettings(pluginId) {
        return pluginRegistry.settingsFor(pluginId)
    }

    // A readable name for a plugin.
    function pluginLabel(pluginId) {
        var plugin = pluginRegistry.pluginFor(pluginId)
        return plugin ? String(plugin.name || pluginId) : pluginId
    }

    // The live plugin widgets, per plugin id. A bar surface exists per
    // monitor, so a plugin usually has one instance per screen. The stock
    // bar's `moduleWidgets()` looks them up here.
    property var _pluginItems: ({})

    function registerPluginWidget(pluginId, item) {
        if (!pluginId || !item) return
        var map = theme._pluginItems
        var list = map[pluginId] ? map[pluginId].slice() : []
        if (list.indexOf(item) < 0) list.push(item)
        map[pluginId] = list
        theme._pluginItems = map
    }

    function unregisterPluginWidget(pluginId, item) {
        if (!pluginId) return
        var map = theme._pluginItems
        var list = map[pluginId] ? map[pluginId].slice() : []
        var at = list.indexOf(item)
        if (at >= 0) list.splice(at, 1)
        if (list.length > 0) map[pluginId] = list
        else delete map[pluginId]
        theme._pluginItems = map
    }

    function pluginWidgets(pluginId) {
        var map = theme._pluginItems
        return map[pluginId] ? map[pluginId] : []
    }

    // Keep only known ids, drop duplicates, and re-home anything missing.
    // The layout holds the entries that are shown; `hidden` holds the
    // built-in widgets that are switched off, and `prefs` remembers the
    // island of anything that has been moved.
    function normalizedLayout(raw, hiddenList, prefMap) {
        var out = { left: [], center: [], right: [] }
        var seen = ({})
        var sides = ["left", "center", "right"]
        var off = hiddenList || []
        for (var s = 0; s < sides.length; s++) {
            var arr = (raw && raw[sides[s]]) || []
            for (var i = 0; i < arr.length; i++) {
                var id = arr[i]
                if (!theme.isKnownEntry(id) || seen[id]) continue
                if (off.indexOf(id) >= 0) continue
                out[sides[s]].push(id)
                seen[id] = true
            }
        }
        // A built-in widget that is neither placed nor hidden is on by
        // default; a plugin is only on when it is in the layout.
        for (var j = 0; j < theme.allWidgets.length; j++) {
            var w = theme.allWidgets[j]
            if (seen[w] || off.indexOf(w) >= 0) continue
            var side = (prefMap && prefMap[w]) ? prefMap[w] : (theme.widgetDefaults[w] || "right")
            if (!out[side]) side = "right"
            out[side].push(w)
            seen[w] = true
        }
        return out
    }

    function sideOf(entry) {
        var sides = ["left", "center", "right"]
        for (var s = 0; s < sides.length; s++)
            if (theme.layout[sides[s]].indexOf(entry) >= 0) return sides[s]
        return ""
    }

    // The layout without the given entry, and the island it was on.
    function withoutEntry(entry) {
        var next = { left: theme.layout.left.slice(),
                     center: theme.layout.center.slice(),
                     right: theme.layout.right.slice() }
        var sides = ["left", "center", "right"]
        var found = ""
        for (var s = 0; s < sides.length; s++) {
            var at = next[sides[s]].indexOf(entry)
            if (at >= 0) {
                found = sides[s]
                next[sides[s]].splice(at, 1)
            }
        }
        return { layout: next, side: found }
    }

    function moveWidget(id, side, index) {
        var next = { left: layout.left.slice(), center: layout.center.slice(), right: layout.right.slice() }
        var sides = ["left", "center", "right"]
        for (var s = 0; s < sides.length; s++) {
            var at = next[sides[s]].indexOf(id)
            if (at >= 0) next[sides[s]].splice(at, 1)
        }
        var target = next[side] || next.right
        if (index < 0 || index > target.length) index = target.length
        target.splice(index, 0, id)
        layout = { left: next.left, center: next.center, right: next.right }
        var prefs = theme.prefs
        prefs[id] = side
        theme.prefs = prefs
        saveState()
    }

    // Show or hide a built-in widget.
    function setItemVisible(entry, visible) {
        var off = theme.hidden.slice()
        var at = off.indexOf(entry)
        if (visible) {
            if (at >= 0) off.splice(at, 1)
            if (theme.sideOf(entry) === "") {
                var side = (theme.prefs[entry] && theme.prefs[entry] !== "off")
                    ? theme.prefs[entry]
                    : (theme.widgetDefaults[entry] || "right")
                theme.placeEntry(entry, side)
            }
        } else {
            if (at < 0) off.push(entry)
            var where = theme.sideOf(entry)
            if (where !== "") {
                var prefs = theme.prefs
                prefs[entry] = where
                theme.prefs = prefs
                theme.layout = theme.withoutEntry(entry).layout
            }
        }
        theme.hidden = off
        saveState()
    }

    function widgetVisible(entry) {
        return theme.sideOf(entry) !== ""
    }

    // Put an entry at the end of an island.
    function placeEntry(entry, side) {
        var next = theme.withoutEntry(entry).layout
        var target = next[side] || next.right
        target.push(entry)
        theme.layout = { left: next.left, center: next.center, right: next.right }
        var prefs = theme.prefs
        prefs[entry] = side
        theme.prefs = prefs
    }

    // ── plugin widgets ──────────────────────────────────────────────────
    // Where a plugin widget sits: "off", "left", "center" or "right".
    function pluginSide(pluginId) {
        var where = theme.sideOf(theme.pluginEntry(pluginId))
        return where !== "" ? where : "off"
    }

    function setPluginSide(pluginId, side) {
        var entry = theme.pluginEntry(pluginId)
        if (side === "off") {
            var where = theme.sideOf(entry)
            var prefs = theme.prefs
            if (where !== "") {
                prefs[entry] = where
                theme.layout = theme.withoutEntry(entry).layout
            }
            theme.prefs = prefs
        } else {
            theme.placeEntry(entry, side)
        }
        saveState()
    }

    function resetLayout() {
        layout = defaultLayout()
        hidden = []
        prefs = ({})
        saveState()
    }

    // ───────────────────────── omarchy plugin catalogue ─────────────────────
    // The stock shell keeps its plugin registry inside its own process, so
    // bombshell reads the manifests from disk instead. The catalogue fills in
    // asynchronously; `theme.omarchyPlugins` stays empty until it does.
    OmarchyPlugins {
        id: pluginRegistry
        shellDir: theme.shellDir
    }

    // ─────────────────────────────── derived colours ───────────────────────────
    readonly property color seal: paletteColor(barColor)
    readonly property color fg: ink
    readonly property color muted: sumi
    readonly property real barOpacity: 0.94

    readonly property color barBg: Qt.rgba(paper.r, paper.g, paper.b, barOpacity)
    readonly property color barFg: seal
    readonly property color panelBg: Qt.rgba(paper.r, paper.g, paper.b, 0.98)
    readonly property color panelBorder: mixColor(paper, ink, 0.20)
    readonly property color sep: Qt.rgba(ink.r, ink.g, ink.b, 0.16)
    readonly property color fillHover: Qt.rgba(ink.r, ink.g, ink.b, 0.10)
    readonly property color fillActive: Qt.rgba(seal.r, seal.g, seal.b, 0.18)
    readonly property color trackBg: Qt.rgba(ink.r, ink.g, ink.b, 0.14)

    function mixColor(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t,
                       a.g + (b.g - a.g) * t,
                       a.b + (b.b - a.b) * t,
                       a.a + (b.a - a.a) * t)
    }

    function paletteColor(id) {
        switch (id) {
            case "accent": return accentHint
            case "foreground": return ink
            case "background": return paper
            case "muted": return sumi
            case "green": return green
            case "color01": return color01
            case "color02": return color02
            case "color03": return color03
            case "color04": return color04
            case "color05": return color05
            case "color06": return color06
            case "color07": return color07
        }
        return accentHint
    }

    function paletteLabel(id) {
        if (id === "accent") return "Accent"
        if (id === "foreground") return "Foreground"
        if (id === "muted") return "Muted"
        if (id.indexOf("color") === 0) return "Color " + parseInt(id.substring(5), 10)
        return id
    }

    // ───────────────────────────── menu icon ─────────────────────────────────
    readonly property var menuIconOptions:
        ["bomb", "omarchy", "arch", "hyprland", "gitkraken", "rebel",
         "cat", "rockstar", "mjolnir", "vaultboy", "image"]

    // Image-based menu icons. "image" is the user's own file (menuIconImage);
    // the rest ship with bombshell, trimmed to a centred 64x64 canvas.
    readonly property var menuIconImagePaths: ({
        "cat": shellDir + "/assets/menu/cat.png",
        "rockstar": shellDir + "/assets/menu/rockstar.png",
        "mjolnir": shellDir + "/assets/menu/mjolnir.png",
        "vaultboy": shellDir + "/assets/menu/vaultboy.png"
    })

    function menuIconIsImage(id) {
        return id === "image" || menuIconImagePaths.hasOwnProperty(id)
    }
    // The bundled artwork is a white mask, so it is tinted to the bar
    // foreground like the glyphs. A user-supplied "image" is left untouched.
    function menuIconIsTinted(id) {
        return menuIconImagePaths.hasOwnProperty(id)
    }
    function menuIconGlyphFor(id) { return Icons.menuGlyph(id) }
    function menuIconFontFor(id) { return id === "omarchy" ? logoFont : mono }
    function menuIconGlyph() { return Icons.menuGlyph(menuIcon) }
    function menuIconFont() { return menuIconFontFor(menuIcon) }
    function menuIconSourceFor(id) {
        var p = id === "image" ? String(menuIconImage || "")
                               : String(menuIconImagePaths[id] || "")
        if (p.indexOf("~/") === 0) p = home + p.substring(1)
        if (p.indexOf("/") === 0) return "file://" + p
        return p
    }
    function menuIconSource() { return menuIconSourceFor(menuIcon) }
    function menuIconLabel(id) {
        switch (id) {
            case "bomb": return "Bomb"
            case "omarchy": return "Omarchy"
            case "arch": return "Arch"
            case "hyprland": return "Hyprland"
            case "gitkraken": return "GitKraken"
            case "rebel": return "Rebel"
            case "cat": return "Cat"
            case "rockstar": return "Rockstar"
            case "mjolnir": return "Mjölnir"
            case "vaultboy": return "Vault Boy"
            case "image": return "Image"
        }
        return id
    }

    // ─────────────────────────────── geometry ─────────────────────────────────
    readonly property int barHeight: 30
    readonly property int barMargin: 6
    readonly property int barReserve: barHeight + 2 * barMargin
    readonly property int pillRadius: Math.round(barHeight / 2)
    readonly property int pillPad: 8
    readonly property int islandGap: 8
    readonly property int widgetSpacing: 6
    readonly property int panelRadius: 10
    readonly property int panelPad: 12
    readonly property int panelGap: 8
    readonly property int fontSize: 12
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string logoFont: "omarchy"

    // ─────────────────────────────── transient ────────────────────────────────
    property bool barHidden: false
    property bool editMode: false
    // The screen the edit overlay is drawn on: the one whose menu started
    // the edit.
    property var editScreen: null
    property var activePopupScreen: null
    readonly property var primaryScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    property string activePanel: ""
    readonly property bool anyPopupVisible: activePanel !== ""
    property real panelAnchorX: 0

    property string tooltipText: ""
    property real tooltipX: 0
    property real tooltipY: 0
    property bool tooltipVisible: false

    function activatePopupScreen(screen) {
        if (!screen) return
        if (!activePopupScreen || !anyPopupVisible) activePopupScreen = screen
    }

    function openPanel(name, x) {
        activePanel = name
        panelAnchorX = (x === undefined ? 0 : x)
        hideTooltip()
    }

    function togglePanel(name, x) {
        if (activePanel === name) closePopups()
        else openPanel(name, x)
    }

    function closePopups() {
        activePanel = ""
        hideTooltip()
    }

    function showTooltip(text, x, y) {
        if (!text) return
        tooltipText = text
        tooltipX = x
        tooltipY = y
        tooltipVisible = true
    }

    function hideTooltip() {
        tooltipVisible = false
        tooltipText = ""
    }

    function enterEditMode() {
        closePopups()
        editScreen = activePopupScreen || primaryScreen
        editMode = true
    }

    function exitEditMode() {
        editMode = false
        saveState()
    }

    // ─────────────────────────────── palette I/O ──────────────────────────────
    function loadPalette(text) {
        Palette.apply(theme, Palette.parse(text))
    }

    function reloadPalette() {
        paletteProc.running = false
        paletteProc.running = true
    }

    Process {
        id: paletteProc
        command: ["bash", "-c",
            "cat \"" + theme.stateColorsPath + "\" 2>/dev/null || cat \"" + theme.configColorsPath + "\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: theme.loadPalette(this.text)
        }
    }

    FileView {
        path: theme.stateColorsPath
        watchChanges: true
        onLoaded: theme.reloadPalette()
        onFileChanged: theme.reloadPalette()
    }
    FileView {
        path: theme.themeNamePath
        watchChanges: true
        onLoaded: theme.reloadPalette()
        onFileChanged: theme.reloadPalette()
    }

    // ─────────────────────────────── persistence ──────────────────────────────
    Process {
        id: stateDirProc
        command: ["mkdir", "-p", theme.stateDir]
        running: true
    }

    FileView {
        id: stateFile
        path: theme.statePath
        blockWrites: false
        atomicWrites: true
        onLoaded: theme.applyState(text())
        onLoadFailed: if (!theme._loaded) theme.applyState("")
        onFileChanged: if (!theme._loaded) theme.applyState(text())
    }

    function applyState(text) {
        var o = null
        try { o = JSON.parse(text) } catch (e) { o = null }
        if (o) {
            if (o.barPosition === "top" || o.barPosition === "bottom") barPosition = o.barPosition
            if (typeof o.islands === "boolean") islands = o.islands
            if (typeof o.barColor === "string" && paletteIds.indexOf(o.barColor) >= 0) barColor = o.barColor
            if (typeof o.clock12h === "boolean") clock12h = o.clock12h
            if (typeof o.weatherImperial === "boolean") weatherImperial = o.weatherImperial
            if (["5", "10", "active"].indexOf(o.workspaceMode) >= 0) workspaceMode = o.workspaceMode
            if (["numbers", "roman", "kanji", "circles"].indexOf(o.workspaceStyle) >= 0) workspaceStyle = o.workspaceStyle
            if (menuIconOptions.indexOf(o.menuIcon) >= 0) menuIcon = o.menuIcon
            if (typeof o.menuIconImage === "string" && o.menuIconImage !== "") menuIconImage = o.menuIconImage
            var off = (o.hidden && typeof o.hidden === "object") ? o.hidden : []
            var preferred = (o.prefs && typeof o.prefs === "object") ? o.prefs : ({})
            hidden = off
            prefs = preferred
            layout = normalizedLayout(o.layout, off, preferred)
        }
        _loaded = true
    }

    function saveState() {
        if (!_loaded) return
        var o = {
            barPosition: barPosition,
            islands: islands,
            barColor: barColor,
            clock12h: clock12h,
            weatherImperial: weatherImperial,
            workspaceMode: workspaceMode,
            workspaceStyle: workspaceStyle,
            menuIcon: menuIcon,
            menuIconImage: menuIconImage,
            layout: layout,
            hidden: hidden,
            prefs: prefs
        }
        stateFile.setText(JSON.stringify(o, null, 2))
    }

    onBarPositionChanged: saveState()
    onIslandsChanged: saveState()
    onBarColorChanged: saveState()
    onClock12hChanged: saveState()
    onWeatherImperialChanged: saveState()
    onWorkspaceModeChanged: saveState()
    onWorkspaceStyleChanged: saveState()
    onMenuIconChanged: saveState()
    onMenuIconImageChanged: saveState()

    // ─────────────────────────────── telemetry ────────────────────────────────
    property int cpuPercent: 0
    property int memPercent: 0
    property int memUsedMiB: 0
    property int memTotalMiB: 0
    property string loadAvg: ""
    property int cpuClockMHz: 0

    Process {
        id: statsProc
        command: ["bash", theme.shellDir + "/scripts/bombshell-stats.sh", "2"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    var o = JSON.parse(line)
                    theme.cpuPercent = Math.max(0, Math.min(100, Math.round(o.cpu)))
                    theme.memPercent = Math.max(0, Math.min(100, Math.round(o.mem)))
                    theme.memUsedMiB = o.memUsedMiB
                    theme.memTotalMiB = o.memTotalMiB
                    theme.loadAvg = o.load
                    theme.cpuClockMHz = o.clockMHz
                } catch (e) {}
            }
        }
    }

    // ───────────────────────────── indicator state ────────────────────────────
    property bool dnd: false
    property bool nightlight: false
    property bool stayAwake: false
    property bool recording: false
    property int reminders: 0
    property string voxState: "idle"
    property double recordingSince: 0
    readonly property int recordingElapsed: recording && recordingSince > 0
        ? Math.max(0, Math.floor(Date.now() / 1000 - recordingSince)) : 0

    Process {
        id: indicatorsProc
        command: ["bash", theme.shellDir + "/scripts/bombshell-indicators.sh", "2"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    var o = JSON.parse(line)
                    if (o.recording && !theme.recording) theme.recordingSince = Date.now() / 1000
                    if (!o.recording) theme.recordingSince = 0
                    theme.dnd = o.dnd === true
                    theme.nightlight = o.nightlight === true
                    theme.stayAwake = o.stayAwake === true
                    theme.recording = o.recording === true
                    theme.reminders = o.reminders || 0
                    theme.voxState = o.vox || "idle"
                } catch (e) {}
            }
        }
    }

    function run(cmd) {
        Quickshell.execDetached(["bash", "-lc", cmd])
    }

    // ─────────────────────────────── battery ──────────────────────────────────
    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool hasBattery: batteryDevice ? batteryDevice.isLaptopBattery : false
    readonly property bool onBattery: UPower.onBattery
    // Quickshell reports UPower percentage/health as 0..1 fractions.
    readonly property int batteryPercent: batteryDevice && batteryDevice.ready
        ? Math.round(batteryDevice.percentage <= 1
            ? batteryDevice.percentage * 100 : batteryDevice.percentage) : 0
    readonly property int batteryState: batteryDevice ? batteryDevice.state : 0
    readonly property bool batteryCharging:
        batteryState === UPowerDeviceState.Charging || batteryState === UPowerDeviceState.FullyCharged
    readonly property real batteryHealth: batteryDevice && batteryDevice.healthSupported
        ? (batteryDevice.healthPercentage <= 1
            ? batteryDevice.healthPercentage * 100 : batteryDevice.healthPercentage) : 0
    readonly property string batteryTimeText: {
        if (!batteryDevice || !batteryDevice.ready) return ""
        var secs = batteryCharging ? batteryDevice.timeToFull : batteryDevice.timeToEmpty
        if (!isFinite(secs) || secs <= 0) return ""
        var h = Math.floor(secs / 3600)
        var m = Math.floor((secs % 3600) / 60)
        return h > 0 ? (h + "h " + m + "m") : (m + "m")
    }
    function batteryIcon() {
        if (batteryCharging) return Icons.icon("charging")
        if (batteryPercent >= 90) return Icons.icon("batteryFull")
        if (batteryPercent >= 65) return Icons.icon("batteryThreeQuarter")
        if (batteryPercent >= 40) return Icons.icon("batteryHalf")
        if (batteryPercent >= 15) return Icons.icon("batteryQuarter")
        return Icons.icon("batteryEmpty")
    }

    // ───────────────────────────── power profile ──────────────────────────────
    readonly property int powerProfile: PowerProfiles.profile
    readonly property bool hasPerformanceProfile: PowerProfiles.hasPerformanceProfile
    function powerProfileName() {
        switch (powerProfile) {
            case PowerProfile.PowerSaver: return "power-saver"
            case PowerProfile.Performance: return "performance"
        }
        return "balanced"
    }
    function powerProfileLabel(name) {
        if (name === "power-saver") return "Saver"
        if (name === "performance") return "Performance"
        return "Balanced"
    }
    function powerProfileIcon(name) {
        if (name === "power-saver") return Icons.icon("powerSaver")
        if (name === "performance") return Icons.icon("performance")
        return Icons.icon("balanced")
    }
    function setPowerProfile(name) {
        run("powerprofilesctl set " + name)
    }

    // ─────────────────────────────── audio ────────────────────────────────────
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property int volume: (audioSink && audioSink.ready && audioSink.audio)
        ? Math.round(audioSink.audio.volume * 100) : 0
    readonly property bool audioMuted: (audioSink && audioSink.ready && audioSink.audio)
        ? audioSink.audio.muted : false
    readonly property string audioSinkName: audioSink ? (audioSink.description || audioSink.name) : ""
    PwObjectTracker { objects: theme.audioSink ? [theme.audioSink] : [] }

    function setVolume(pct) {
        var v = Math.max(0, Math.min(100, Math.round(pct)))
        run("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ " + v + "%")
    }
    function toggleMute() {
        run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
    }
    function volumeIcon() {
        if (audioMuted || volume <= 0) return Icons.icon("volumeMute")
        if (volume < 40) return Icons.icon("volumeLow")
        return Icons.icon("volumeHigh")
    }

    // ─────────────────────────────── network ──────────────────────────────────
    // netRevision / btRevision are bumped by the Connections below so the plain
    // JS array properties recompute when the underlying models change.
    property int netRevision: 0
    property int btRevision: 0

    readonly property var wifiDevice: {
        netRevision
        var d = Networking.devices.values
        for (var i = 0; i < d.length; i++)
            if (d[i].type === DeviceType.Wifi) return d[i]
        return null
    }
    readonly property var wiredDevice: {
        netRevision
        var d = Networking.devices.values
        for (var i = 0; i < d.length; i++)
            if (d[i].type === DeviceType.Wired) return d[i]
        return null
    }
    readonly property var wifiNetworks: {
        netRevision
        return wifiDevice ? wifiDevice.networks.values : []
    }
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool networkConnected:
        (wifiDevice !== null && wifiDevice.connected) || (wiredDevice !== null && wiredDevice.connected)
    function setWifiEnabled(on) { Networking.wifiEnabled = on }
    function connectedNetwork() {
        if (wifiDevice !== null && wifiDevice.connected) {
            var nets = wifiDevice.networks.values
            for (var i = 0; i < nets.length; i++)
                if (nets[i].connected) return nets[i]
        }
        if (wiredDevice !== null && wiredDevice.connected) return wiredDevice.network
        return null
    }
    function networkName() {
        var n = connectedNetwork()
        if (n) return n.name
        if (wifiDevice !== null && wifiDevice.connected) return "Wi-Fi"
        return ""
    }
    function networkIcon() {
        if (wiredDevice !== null && wiredDevice.connected) return Icons.icon("ethernet")
        if (wifiDevice !== null && wifiDevice.connected) return Icons.icon("wifi")
        if (wifiEnabled) return Icons.icon("wifi")
        return Icons.icon("wifiOff")
    }

    // ─────────────────────────────── bluetooth ────────────────────────────────
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btEnabled: btAdapter ? btAdapter.enabled : false
    readonly property var btDevices: {
        btRevision
        return btAdapter ? btAdapter.devices.values : []
    }
    readonly property int btConnectedCount: {
        var n = 0
        var d = btDevices
        for (var i = 0; i < d.length; i++) if (d[i].connected) n++
        return n
    }
    function setBtEnabled(on) { if (btAdapter) btAdapter.enabled = on }
    function bluetoothIcon() {
        if (!btAdapter || !btAdapter.enabled) return Icons.icon("bluetoothOff")
        if (btConnectedCount > 0) return Icons.icon("bluetoothConnected")
        return Icons.icon("bluetooth")
    }

    Connections {
        target: Networking.devices
        function onValuesChanged() { theme.netRevision++ }
    }
    Connections {
        target: theme.wifiDevice ? theme.wifiDevice.networks : null
        function onValuesChanged() { theme.netRevision++ }
    }
    Connections {
        target: theme.btAdapter ? theme.btAdapter.devices : null
        function onValuesChanged() { theme.btRevision++ }
    }

    // ─────────────────────────────── tray ─────────────────────────────────────
    property int trayRevision: 0
    readonly property var trayItems: {
        trayRevision
        var out = []
        var v = SystemTray.items.values
        for (var i = 0; i < v.length; i++)
            if (v[i] && v[i].status !== Status.Passive) out.push(v[i])
        return out
    }
    Connections {
        target: SystemTray.items
        function onValuesChanged() { theme.trayRevision++ }
    }

    // The item whose DBusMenu the tray menu panel is showing.
    property var trayMenuItem: null
    function openTrayMenu(item, x) {
        if (!item) return
        trayMenuItem = item
        openPanel("traymenu", x === undefined ? 0 : x)
    }
    function openTrayMenuAt(index) {
        var items = trayItems
        if (!items || items.length === 0) return
        var i = Math.max(0, Math.min(items.length - 1, index || 0))
        var w = primaryScreen ? primaryScreen.width : 0
        openTrayMenu(items[i], w / 2)
    }

    // ─────────────────────────────── weather ──────────────────────────────────
    property int weatherCode: -1
    property string weatherDesc: ""
    property int weatherTempC: 0
    property string weatherLocation: ""
    property int weatherHumidity: 0
    property int weatherWindKph: 0
    property var weatherDays: []
    property bool weatherReady: false

    readonly property int weatherTemp: weatherImperial
        ? Math.round(weatherTempC * 9 / 5 + 32) : weatherTempC
    readonly property string weatherUnit: weatherImperial ? "°F" : "°C"
    function weatherIcon() { return Icons.weatherGlyph(weatherCode) }

    // Location comes from Omarchy's own weather.json so bombshell and the
    // stock bar agree. Blank means wttr.in auto-detects from the IP.
    readonly property string weatherSettingsPath:
        home + "/.local/state/omarchy/settings/weather.json"
    property string weatherPlaceName: ""
    property string weatherLat: ""
    property string weatherLon: ""
    readonly property bool weatherLocationIsAuto:
        weatherPlaceName === "" && weatherLat === ""
    property bool _weatherLocationLoaded: false
    readonly property string weatherLocationLabel:
        weatherPlaceName !== "" ? weatherPlaceName : weatherLocation

    readonly property string weatherUrl: {
        if (weatherLat !== "" && weatherLon !== "")
            return "https://wttr.in/" + weatherLat + "," + weatherLon + "?format=j1"
        if (weatherPlaceName !== "")
            return "https://wttr.in/" + encodeURIComponent(weatherPlaceName) + "?format=j1"
        return "https://wttr.in/?format=j1"
    }

    function loadWeatherLocation(text) {
        var name = "", lat = "", lon = ""
        try {
            var o = JSON.parse(text || "{}")
            if (o && typeof o.name === "string") name = o.name
            if (o && o.latitude !== undefined && o.latitude !== null) lat = String(o.latitude)
            if (o && o.longitude !== undefined && o.longitude !== null) lon = String(o.longitude)
        } catch (e) {}
        if (name !== weatherPlaceName || lat !== weatherLat || lon !== weatherLon) {
            weatherPlaceName = name
            weatherLat = lat
            weatherLon = lon
            refreshWeather()
        } else if (!_weatherLocationLoaded) {
            refreshWeather()
        }
        _weatherLocationLoaded = true
    }

    function setWeatherLocation(name) {
        var n = String(name || "").trim()
        // Update local state immediately; don't depend on the file watcher.
        weatherPlaceName = n
        weatherLat = ""
        weatherLon = ""
        _weatherLocationLoaded = true
        if (n === "")
            run("omarchy-weather-location --clear")
        else
            run("omarchy-weather-location --set '" + n.replace(/'/g, "'\\''") + "'")
        refreshWeather()
    }

    FileView {
        id: weatherLocationFile
        path: theme.weatherSettingsPath
        watchChanges: true
        onLoaded: theme.loadWeatherLocation(text())
        onLoadFailed: theme.loadWeatherLocation("")
        onFileChanged: theme.loadWeatherLocation(text())
    }

    function refreshWeather() {
        weatherProc.running = false
        weatherProc.running = true
    }

    Process {
        id: weatherProc
        command: ["bash", "-c",
            "curl -fsS --max-time 12 '" + theme.weatherUrl + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text
                if (!t) return
                try {
                    var o = JSON.parse(t)
                    var cur = (o.current_condition && o.current_condition[0]) || null
                    if (!cur) return
                    theme.weatherCode = parseInt(cur.weatherCode, 10) || 0
                    theme.weatherDesc = (cur.weatherDesc && cur.weatherDesc[0].value) || ""
                    theme.weatherTempC = parseInt(cur.temp_C, 10) || 0
                    theme.weatherHumidity = parseInt(cur.humidity, 10) || 0
                    theme.weatherWindKph = parseInt(cur.windspeedKmph, 10) || 0
                    if (o.nearest_area && o.nearest_area[0])
                        theme.weatherLocation = o.nearest_area[0].areaName[0].value || ""
                    var days = []
                    var wd = o.weather || []
                    for (var i = 0; i < Math.min(3, wd.length); i++) {
                        days.push({
                            date: wd[i].date,
                            maxC: parseInt(wd[i].maxtempC, 10),
                            minC: parseInt(wd[i].mintempC, 10),
                            code: parseInt(wd[i].hourly && wd[i].hourly[4] ? wd[i].hourly[4].weatherCode : 0, 10)
                        })
                    }
                    theme.weatherDays = days
                    theme.weatherReady = true
                } catch (e) {}
            }
        }
    }

    // Reconcile external location changes: the stock shell or the CLI can
    // rewrite weather.json, and a file created after startup is not watched.
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: weatherLocationRead.running = true
    }

    Process {
        id: weatherLocationRead
        command: ["bash", "-c",
            "cat \"" + theme.weatherSettingsPath + "\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: theme.loadWeatherLocation(this.text)
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        onTriggered: theme.refreshWeather()
    }

    // Right-align numbers in a fixed-width, space-padded field so a changing
    // digit count never resizes a widget (and thus the island).
    function pad(value, width) {
        var s = String(value)
        while (s.length < width) s = " " + s
        return s
    }

    // ───────────────────────────── workspace helpers ──────────────────────────
    function workspaceLabel(id) {
        if (workspaceStyle === "kanji") {
            var kanji = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
            return id >= 1 && id <= 10 ? kanji[id - 1] : String(id)
        }
        if (workspaceStyle === "roman") {
            var roman = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
            return id >= 1 && id <= 10 ? roman[id - 1] : String(id)
        }
        if (id === 10) return "0"
        return String(id)
    }

    function gotoWorkspace(id) {
        run("hyprctl dispatch " + (theme.hyprLua
            ? "'hl.dsp.focus({ workspace = \"" + id + "\" })'"
            : "workspace " + id))
    }

    property bool hyprLua: true
    Process {
        id: hyprProbe
        // Omarchy ships the config as hyprland.lua (Lua) or hyprland.conf
        // (classic). The dispatch syntax differs, so detect which.
        command: ["bash", "-c",
            "if [ -f \"$HOME/.config/hypr/hyprland.lua\" ]; then echo lua; " +
            "elif [ -f \"$HOME/.config/hypr/hyprland.conf\" ]; then echo classic; " +
            "else echo lua; fi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                theme.hyprLua = (this.text.trim() !== "classic")
                console.log("[bombshell] Hyprland config:", theme.hyprLua ? "lua" : "classic")
            }
        }
    }

    // ─────────────────────────────── IPC ──────────────────────────────────────
    IpcHandler {
        target: "bombshell"

        function ping(): string { return "ok" }
        function showBar(): string {
            theme.barHidden = false
            return "ok"
        }
        function hideBar(): string {
            theme.closePopups()
            theme.barHidden = true
            return "ok"
        }
        function toggleBar(): string {
            theme.barHidden = !theme.barHidden
            return "ok"
        }
        function omarchy(): string {
            theme.run("bash " + theme.shellDir + "/scripts/bombshell-toggle.sh omarchy")
            return "ok"
        }
        function reload(): string {
            theme.reloadPalette()
            return "ok"
        }
        function panel(name: string): string {
            var w = theme.primaryScreen ? theme.primaryScreen.width : 0
            theme.openPanel(name, w / 2)
            return "ok"
        }
        function closePanels(): string {
            theme.closePopups()
            return "ok"
        }
        function edit(): string {
            theme.enterEditMode()
            return "ok"
        }
        function exitEdit(): string {
            theme.exitEditMode()
            return "ok"
        }
        function move(widget: string, side: string): string {
            theme.moveWidget(widget, side, -1)
            return "ok"
        }
        function trayMenu(): string {
            theme.openTrayMenuAt(0)
            return "ok"
        }
        function workspace(id: string): string {
            var n = parseInt(id, 10)
            if (!isNaN(n)) theme.gotoWorkspace(n)
            return "ok"
        }
    }

    IpcHandler {
        target: "theme"
        function reload(): string {
            theme.reloadPalette()
            return "ok"
        }
    }
}
