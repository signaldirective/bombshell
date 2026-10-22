// OmarchyBarShim.qml — the `bar` object that Omarchy's plugin widgets expect.
//
// The stock Omarchy bar injects itself into every widget slot. bombshell
// loads those widgets inside its own process, so it has to stand in for the
// bar: the colours and metrics they read, the commands they run, the tooltip
// and popout bookkeeping they drive, and the handful of shell services they
// may ask for.

import QtQuick

QtObject {
    id: shim

    required property var theme

    // ── geometry and palette ─────────────────────────────────────────────
    readonly property string fontFamily: shim.theme.mono
    readonly property color barForeground: shim.theme.barFg
    readonly property color foreground: shim.theme.ink
    readonly property color urgent: shim.theme.urgent
    readonly property color background: shim.theme.paper
    readonly property bool vertical: false
    readonly property int barSize: shim.theme.barHeight
    readonly property bool foregroundAnimationEnabled: true
    readonly property string position: shim.theme.barPosition

    // The stock bar's own layout, for widgets that read it. bombshell keeps
    // its layout elsewhere, so this is empty.
    readonly property var layoutConfig: ({})

    // ── popout coordination ──────────────────────────────────────────────
    // Only one popout may be open at a time; opening a second closes the
    // first, exactly as the stock bar does.
    property var activePopout: null

    // Items a click in the bar strip should be forwarded to. bombshell does
    // not need this: its own panels live on their own surface.
    property var clickTargets: []

    function requestPopout(owner) {
        if (shim.activePopout === owner) return
        if (shim.activePopout) {
            if ("closeForPopoutSwitch" in shim.activePopout)
                shim.activePopout.closeForPopoutSwitch()
            else if ("close" in shim.activePopout)
                shim.activePopout.close()
        }
        shim.activePopout = owner
    }

    function releasePopout(owner) {
        if (shim.activePopout === owner) shim.activePopout = null
    }

    // ── tooltips ─────────────────────────────────────────────────────────
    function showTooltip(target, text) {
        if (!text) return
        shim.theme.showTooltip(String(text), shim.tooltipX(target), 0)
    }

    function hideTooltip(target) {
        shim.theme.hideTooltip()
    }

    function tooltipX(target) {
        if (!target) return 0
        try {
            return target.mapToItem(null, target.width / 2, 0).x
        } catch (e) {
            return 0
        }
    }

    // ── commands ─────────────────────────────────────────────────────────
    function run(command) {
        if (!command) return
        shim.theme.run(String(command))
    }

    // ── the same widget on every screen ──────────────────────────────────
    // A bar surface exists per monitor, so a widget that wants to reach its
    // peers asks for them by plugin id.
    function moduleWidgets(pluginId) {
        return shim.theme.pluginWidgets(pluginId)
    }

    function targetBelongsToWindow(target, window) {
        if (!target || !window) return false
        try {
            return target.QsWindow.window === window
        } catch (e) {
            return false
        }
    }

    // The shell services a widget may ask for. bombshell does not run the
    // Omarchy shell's service registry, so this is a stub and a widget that
    // needs a real service will not find one.
    readonly property var shell: ({
        serviceFor: function () { return null },
        pluginRegistry: null,
        updateEntryInline: function () {}
    })
}
