pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    property var plugins: []
    property var slotRegistry: ({})
    property var activeHooks: []
    property bool loading: false

    // Fast lookup for enabled plugin IDs
    property var enabledPluginIds: {
        var map = {}
        var list = ConfigStore.enabledPlugins || []
        for (var i = 0; i < list.length; i++) {
            map[list[i]] = true
        }
        return map
    }

    // Active background services declared by enabled plugins
    readonly property var activeServiceEntries: {
        var res = []
        for (var i = 0; i < root.plugins.length; i++) {
            var p = root.plugins[i]
            if (p && p.id && root.isPluginEnabled(p.id) && p.service_entry && p.is_valid) {
                res.push("file://" + p.service_entry)
            }
        }
        return res
    }

    Repeater {
        model: root.activeServiceEntries
        delegate: Loader {
            required property var modelData
            source: modelData
            active: true
        }
    }

    Connections {
        target: ConfigStore
        function onEnabledPluginsChanged() {
            root.rebuildSlotRegistry()
        }
    }

    function isPluginEnabled(id) {
        return !!root.enabledPluginIds[id]
    }

    function togglePlugin(id) {
        var current = ConfigStore.enabledPlugins ? ConfigStore.enabledPlugins.slice() : []
        var idx = current.indexOf(id)
        if (idx >= 0) {
            current.splice(idx, 1)
        } else {
            // Check missing deps before enabling
            for (var i = 0; i < root.plugins.length; i++) {
                var p = root.plugins[i]
                if (p.id === id && p.missing_deps && p.missing_deps.length > 0) {
                    console.warn("PluginService: enabling", id, "with missing deps:", p.missing_deps.join(", "))
                    missingDepsNotif.pluginName = p.name || id
                    missingDepsNotif.deps = p.missing_deps.join(", ")
                    missingDepsNotif.running = false
                    missingDepsNotif.running = true
                    // Still enable — plugin may work partially or user chose to proceed
                }
            }
            current.push(id)
        }
        ConfigStore.enabledPlugins = current
        ConfigStore.save()
        rebuildSlotRegistry()
    }

    // Returns array of component sources targeting a specific slot:
    // [{ source: "...", position: "append"|"prepend"|"replace", pluginId: "..." }]
    function getSlotInjections(slotName) {
        if (!root.slotRegistry || !root.slotRegistry[slotName]) {
            return []
        }
        return root.slotRegistry[slotName]
    }

    // Check if a slot has a replacement override active
    function getSlotReplacement(slotName) {
        var items = getSlotInjections(slotName)
        for (var i = 0; i < items.length; i++) {
            if (items[i].position === "replace") {
                return items[i].source
            }
        }
        return ""
    }

    // Returns file:// path to a plugin's panel view component
    function getPluginViewSource(pluginId) {
        for (var i = 0; i < root.plugins.length; i++) {
            var p = root.plugins[i]
            if (p && p.id === pluginId && root.isPluginEnabled(pluginId)) {
                return p.view_entry ? ("file://" + p.view_entry) : ""
            }
        }
        return ""
    }

    // Middleware filter pipeline: passes data through active plugin filters
    function filter(topic, data) {
        var currentData = data
        for (var i = 0; i < root.activeHooks.length; i++) {
            var hook = root.activeHooks[i]
            if (hook && typeof hook.filter === "function") {
                try {
                    currentData = hook.filter(topic, currentData)
                } catch (e) {
                    console.warn("PluginService: Error running filter for", topic, e)
                }
            }
        }
        return currentData
    }

    function emitEvent(eventName, payload) {
        for (var i = 0; i < root.activeHooks.length; i++) {
            var hook = root.activeHooks[i]
            if (hook && typeof hook.emit === "function") {
                try {
                    hook.emit(eventName, payload)
                } catch (e) {
                    console.warn("PluginService: Error emitting", eventName, e)
                }
            }
        }
    }

    function rebuildSlotRegistry() {
        var registry = {}
        for (var i = 0; i < root.plugins.length; i++) {
            var p = root.plugins[i]
            if (!p || !p.id || !root.isPluginEnabled(p.id)) continue
            if (!p.is_valid) {
                console.warn("PluginService: Skipping invalid plugin", p.id)
                continue
            }

            if (p.extensions && p.extensions.length > 0) {
                for (var j = 0; j < p.extensions.length; j++) {
                    var ext = p.extensions[j]
                    if (!ext.slot || !ext.resolved_source) continue

                    if (!registry[ext.slot]) {
                        registry[ext.slot] = []
                    }
                    registry[ext.slot].push({
                        pluginId: p.id,
                        source: "file://" + ext.resolved_source,
                        position: ext.position || "append"
                    })
                }
            }
        }
        root.slotRegistry = registry
    }

    Process {
        id: scannerProc
        command: [
            Quickshell.env("HOME") + "/.config/quickshell/helpers/target/release/flui-helper",
            "plugins"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false
                try {
                    var raw = JSON.parse(text.trim())
                    root.plugins = Array.isArray(raw) ? raw : []
                    root.rebuildSlotRegistry()
                } catch (e) {
                    console.warn("PluginService: failed to parse plugins output", e)
                }
            }
        }
    }

    // Notify when a plugin has missing system deps on enable
    Process {
        id: missingDepsNotif
        property string pluginName: ""
        property string deps: ""
        command: [
            "notify-send",
            "--urgency=normal",
            "--icon=dialog-warning",
            "Plugin: " + pluginName,
            "Missing system dependencies: " + deps
        ]
    }

    function scan() {
        if (!root.loading) {
            root.loading = true
            scannerProc.running = false
            scannerProc.running = true
        }
    }

    Component.onCompleted: {
        root.scan()
    }
}
