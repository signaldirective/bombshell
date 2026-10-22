// OmarchyPlugins.qml — the catalogue of Omarchy shell plugins that can put a
// widget on the bar.
//
// The stock shell keeps its plugin registry inside its own process, so
// bombshell asks the filesystem instead: a small script walks the plugin
// manifests and prints what it found as JSON, and `omarchy plugin list
// --json` answers the "is it enabled in the stock bar?" half.
//
// Finding the plugins needs a couple of child processes: one to point the
// QML module names at the Omarchy shell, and one to do the walk.

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: registry

    // This is a data holder, not something that is drawn.
    visible: false
    width: 0
    height: 0

    // Where bombshell's own scripts live.
    required property string shellDir

    readonly property string home: Quickshell.env("HOME")

    // The Omarchy shell tree the plugin widgets come from. Filled in by the
    // module script, which also points `Ui` and `Commons` at the same tree.
    property string shellRoot: "/usr/share/omarchy/shell"
    readonly property string userPluginsDir: registry.home + "/.config/omarchy/plugins"
    readonly property string shellJson: registry.home + "/.config/omarchy/shell.json"

    // The catalogue: one entry per plugin that offers a bar widget.
    property var plugins: []
    property bool ready: false
    property string error: ""

    function scan() {
        if (registry.shellDir === "") return
        scanProc.running = false
        scanProc.running = true
    }

    function pluginFor(id) {
        var list = registry.plugins
        for (var i = 0; i < list.length; i++)
            if (list[i].id === id) return list[i]
        return null
    }

    function urlFor(id) {
        var plugin = registry.pluginFor(id)
        return plugin ? String(plugin.url || "") : ""
    }

    function settingsFor(id) {
        var plugin = registry.pluginFor(id)
        return plugin && plugin.settings ? plugin.settings : ({})
    }

    function apply(text) {
        var parsed = null
        try { parsed = JSON.parse(text || "[]") } catch (e) { parsed = null }
        if (!parsed || !parsed.length) {
            registry.plugins = []
            registry.ready = true
            return
        }
        registry.plugins = parsed
        registry.ready = true
    }

    // ── the module symlinks come first ─────────────────────────────────────
    // `qs.Ui` and `qs.Commons` have to resolve before any plugin widget can
    // be loaded, so the scan waits for this to finish.
    Process {
        id: modulesProc
        command: ["bash", registry.shellDir + "/scripts/bombshell-omarchy-modules.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var dir = String(this.text || "").trim()
                if (dir !== "") registry.shellRoot = dir
            }
        }
        onExited: (exitCode, exitStatus) => registry.scan()
    }

    // ── the catalogue ──────────────────────────────────────────────────────
    Process {
        id: scanProc
        command: [
            "bash",
            registry.shellDir + "/scripts/bombshell-plugins.sh",
            registry.shellRoot,
            registry.userPluginsDir,
            registry.shellJson
        ]
        stdout: StdioCollector {
            onStreamFinished: registry.apply(this.text)
        }
    }

    // The stock shell rewrites shell.json when a plugin is enabled, disabled
    // or reconfigured, so the catalogue is refreshed when it does.
    FileView {
        id: shellJsonFile
        path: registry.shellJson
        watchChanges: true
        onFileChanged: registry.scan()
    }
}
