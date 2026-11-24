pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME")
        ? (Quickshell.env("XDG_CONFIG_HOME") + "/quickshell")
        : (Quickshell.env("HOME") + "/.config/quickshell")
    readonly property string configPath: configDir + "/settings.json"

    // Bar / Island Display
    property int layout: 0 // 0 = Pill, 1 = Notch, 2 = Bar
    property int barEdgePosition: 0 // 0 = Top, 1 = Bottom
    property bool autoHideBar: false

    // Control Center & Notification
    property bool dnd: false

    // Night Light Settings
    property bool nightLightSchedule: true
    property string nightLightStart: "20:00"
    property string nightLightEnd: "07:00"
    property int nightLightTargetTemp: 4500

    // Wallpaper & Shuffle Settings
    property bool wallpaperShuffle: false
    property string wallpaperShuffleInterval: "3h" // 15m, 30m, 1h, 3h, 6h, 12h, 1d
    property string wallpaperTransitionType: "grow" // grow, fade, simple, wipe, wave, center, outer, random
    property int wallpaperTransitionDuration: 2
    property string currentWallpaper: ""
    property string wallpaperDir: ""

    // First-Run & App Theming Permissions
    property bool firstRunCompleted: true
    property bool matugenEnabled: true
    property var themedApps: ({
        "quickshell": true,
        "kitty": false,
        "gtk": false,
        "cava": false,
        "zen": false,
        "nvim": false,
        "yazi": false,
        "hyprlock": false
    })

    // Plugins Settings
    property var enabledPlugins: ["weather", "quote", "gcal-sync"]
    property var disabledPlugins: []

    property bool loaded: false
    property bool isSaving: false

    function save() {
        var data = {
            "layout": root.layout,
            "barEdgePosition": root.barEdgePosition,
            "autoHideBar": root.autoHideBar,
            "dnd": root.dnd,
            "nightLightSchedule": root.nightLightSchedule,
            "nightLightStart": root.nightLightStart,
            "nightLightEnd": root.nightLightEnd,
            "nightLightTargetTemp": root.nightLightTargetTemp,
            "wallpaperShuffle": root.wallpaperShuffle,
            "wallpaperShuffleInterval": root.wallpaperShuffleInterval,
            "wallpaperTransitionType": root.wallpaperTransitionType,
            "wallpaperTransitionDuration": root.wallpaperTransitionDuration,
            "currentWallpaper": root.currentWallpaper,
            "wallpaperDir": root.wallpaperDir,
            "firstRunCompleted": root.firstRunCompleted,
            "matugenEnabled": root.matugenEnabled,
            "themedApps": root.themedApps,
            "enabledPlugins": root.enabledPlugins,
            "disabledPlugins": root.disabledPlugins
        }

        var jsonStr = JSON.stringify(data, null, 2)
        saveProcess.command = [
            "python3", "-c",
            "import sys, os\ntmp = sys.argv[1] + '.tmp'\nwith open(tmp, 'w') as f: f.write(sys.argv[2])\nos.replace(tmp, sys.argv[1])",
            root.configPath,
            jsonStr
        ]
        saveProcess.running = false
        saveProcess.running = true
    }

    Process {
        id: saveProcess
    }

    function applyJson(json) {
        if (!json || typeof json !== "object") return

        if (json.layout !== undefined) root.layout = json.layout
        if (json.barEdgePosition !== undefined) root.barEdgePosition = json.barEdgePosition
        if (json.autoHideBar !== undefined) root.autoHideBar = json.autoHideBar
        if (json.dnd !== undefined) root.dnd = json.dnd

        if (json.nightLightSchedule !== undefined) root.nightLightSchedule = json.nightLightSchedule
        if (json.nightLightStart !== undefined) root.nightLightStart = json.nightLightStart
        if (json.nightLightEnd !== undefined) root.nightLightEnd = json.nightLightEnd
        if (json.nightLightTargetTemp !== undefined) root.nightLightTargetTemp = json.nightLightTargetTemp

        if (json.wallpaperShuffle !== undefined) root.wallpaperShuffle = json.wallpaperShuffle
        if (json.wallpaperShuffleInterval !== undefined) root.wallpaperShuffleInterval = json.wallpaperShuffleInterval
        if (json.wallpaperTransitionType !== undefined) root.wallpaperTransitionType = json.wallpaperTransitionType
        if (json.wallpaperTransitionDuration !== undefined) root.wallpaperTransitionDuration = json.wallpaperTransitionDuration
        if (json.currentWallpaper !== undefined) root.currentWallpaper = json.currentWallpaper
        if (json.wallpaperDir !== undefined) root.wallpaperDir = json.wallpaperDir
        if (json.firstRunCompleted !== undefined) root.firstRunCompleted = json.firstRunCompleted
        if (json.matugenEnabled !== undefined) root.matugenEnabled = json.matugenEnabled
        if (json.themedApps !== undefined && typeof json.themedApps === "object") {
            root.themedApps = Object.assign({}, root.themedApps, json.themedApps)
        }
        if (json.enabledPlugins !== undefined && Array.isArray(json.enabledPlugins)) {
            root.enabledPlugins = json.enabledPlugins
        }
        if (json.disabledPlugins !== undefined && Array.isArray(json.disabledPlugins)) {
            root.disabledPlugins = json.disabledPlugins
        }

        root.loaded = true
    }

    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true

        onLoaded: {
            try {
                var json = JSON.parse(text())
                root.applyJson(json)
            } catch (e) {
                console.log("ConfigStore parse error:", e)
                root.save()
            }
        }

        onLoadFailed: {
            root.save()
            root.loaded = true
        }
    }
}
