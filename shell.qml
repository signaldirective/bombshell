// bombshell — a theme-aware Quickshell bar built for Omarchy.

import QtQuick
import Quickshell

ShellRoot {
    id: root

    // Only real outputs get a bar; QtWayland exposes a nameless 0x0 placeholder
    // while no monitor is attached.
    readonly property var barScreens: {
        var out = []
        for (var i = 0; i < Quickshell.screens.length; i++) {
            var s = Quickshell.screens[i]
            if (s.name !== "" && s.width > 0 && s.height > 0) out.push(s)
        }
        return out
    }

    Theme {
        id: themeRoot
    }

    Variants {
        model: root.barScreens

        delegate: Component {
            Bar {
                required property var modelData
                theme: themeRoot
                screen: modelData
            }
        }
    }

    // The stock Omarchy bar is stepped aside by the `bombshell` launcher
    // (`scripts/bombshell-toggle.sh bombshell`), not here, so running
    // `qs -p .` from this directory stays non-destructive.

    // ── panels (one overlay window each, shown on theme.activePanel) ──
    MenuPanel       { theme: themeRoot }
    CalendarPanel   { theme: themeRoot }
    WeatherPanel    { theme: themeRoot }
    VolumePanel     { theme: themeRoot }
    BatteryPanel    { theme: themeRoot }
    PowerPanel      { theme: themeRoot }
    NetworkPanel    { theme: themeRoot }
    BluetoothPanel  { theme: themeRoot }
    DisplayPanel    { theme: themeRoot }
    CpuPanel        { theme: themeRoot }
    MemoryPanel     { theme: themeRoot }
    TrayMenuPanel   { theme: themeRoot }
    TooltipOverlay  { theme: themeRoot }
}
