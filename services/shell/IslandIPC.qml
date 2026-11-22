import QtQuick
import Quickshell
import Quickshell.Io

import "../../core"
import "../../island"
import "../../services"

Scope {
    id: root

    IpcHandler {
        target: "flui"

        function focusToggle() {
            FocusService.toggle()
        }

        function openPowerMenu() {
            IslandController.openPowerMenu()
        }

        function openExpandedHome() {
            IslandController.openExpanded()
        }

        function openControlCenter() {
            IslandController.openControlCenter()
        }

        function reset() {
            IslandController.reset()
        }

        function openWallpaperSelector() {
            IslandController.openWallpaperSelector()
        }

        function openThemeSelector() {
            IslandController.openThemeSelector()
        }

        function openWifiMenu() {
            IslandController.openWifiMenu()
        }

        function openBluetoothMenu() {
            IslandController.openBluetoothMenu()
        }

        function openMedia() {
            IslandController.openMediaFromLeftSection()
        }

        function openNotifications() {
            IslandController.openNotifications()
        }

        function openPluginsMenu() {
            IslandController.openPluginsMenu()
        }

        function cycleLayout() {
            IslandController.cycleLayout()
        }

        function togglePlacement() {
            Placement.toggle()
            console.log("Placement now:", Placement.subtitle, "dockBottom:", IslandState.dockBottom)
        }

        function testOsd() {
            StatusManager.show({
                mode: "volume",
                icon: "󰕾",
                title: "Volume",
                value: 42
            })
        }

        // Generic IPC router: `quickshell ipc call flui plugins [action] [pluginId]`
        function plugins(action: string) {
            var act = action ? action.trim() : "list"
            var parts = act.split(/\s+/)
            var cmd = parts[0]
            var arg = parts.length > 1 ? parts[1] : ""

            if (cmd === "list") {
                pluginsIpc.list()
            } else if (cmd === "open") {
                pluginsIpc.open(arg)
            } else if (cmd === "toggle") {
                pluginsIpc.toggle(arg)
            } else if (cmd === "menu") {
                pluginsIpc.menu()
            } else if (cmd === "scan" || cmd === "refresh") {
                pluginsIpc.scan()
            } else {
                pluginsIpc.open(cmd)
            }
        }
    }

    IpcHandler {
        id: pluginsIpc
        target: "plugins"

        function list() {
            var lines = ["Loaded Plugins:"]
            for (var i = 0; i < PluginService.plugins.length; i++) {
                var p = PluginService.plugins[i]
                var state = PluginService.isPluginEnabled(p.id) ? "enabled" : "disabled"
                lines.push("  - " + p.id + " [" + state + "] (" + (p.name || p.id) + " v" + (p.version || "1.0.0") + ")")
            }
            var result = lines.join("\n")
            console.log(result)
            return result
        }

        function open(pluginId: string) {
            var pid = pluginId ? pluginId.trim() : ""
            if (!pid) return
            PluginService.openView(pid)
        }

        function toggle(pluginId: string) {
            var pid = pluginId ? pluginId.trim() : ""
            if (!pid) return
            PluginService.togglePlugin(pid)
            console.log("Toggled plugin:", pid, "enabled:", PluginService.isPluginEnabled(pid))
        }

        function menu() {
            IslandController.openPluginsMenu()
        }

        function scan() {
            PluginService.scan()
        }
    }
}
