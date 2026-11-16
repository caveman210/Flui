pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME") !== ""
        ? (Quickshell.env("XDG_CONFIG_HOME") + "/quickshell")
        : (Quickshell.env("HOME") + "/.config/quickshell")
    readonly property string configPath: configDir + "/settings.json"
    readonly property string envPath: configDir + "/.env"

    // Weather Settings
    property string weatherProvider: "openmeteo" // "openmeteo", "wttr", "metno", "aggregator"
    property string weatherLocation: ""
    property string weatherApiKey: ""
    property int weatherPollIntervalMins: 5

    // Bar / Island Display
    property string barInfoMode: "cycle" // "cycle", "weather", "motivation"
    property int layout: 0 // 0 = Pill, 1 = Notch, 2 = Bar
    property int barEdgePosition: 0 // 0 = Top, 1 = Bottom
    property bool autoHideBar: false

    // Control Center & Notification
    property bool dnd: false

    // Night Light Settings
    property bool nightLightSchedule: true
    property string nightLightStart: "20:00"
    property string nightLightEnd: "07:00"
    property int nightLightTransitionMins: 15
    property string nightLightCurveType: "scurve" // "scurve", "linear", "ease_in", "ease_out", "custom"
    property var nightLightControlPoints: [
        {"x": 0.0, "y": 0.0},
        {"x": 0.35, "y": 0.08},
        {"x": 0.65, "y": 0.92},
        {"x": 1.0, "y": 1.0}
    ]
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

    property bool loaded: false
    property bool isSaving: false

    function save() {
        var data = {
            "weatherProvider": root.weatherProvider,
            "weatherLocation": root.weatherLocation,
            "weatherApiKey": root.weatherApiKey,
            "weatherPollIntervalMins": root.weatherPollIntervalMins,
            "barInfoMode": root.barInfoMode,
            "layout": root.layout,
            "barEdgePosition": root.barEdgePosition,
            "autoHideBar": root.autoHideBar,
            "dnd": root.dnd,
            "nightLightSchedule": root.nightLightSchedule,
            "nightLightStart": root.nightLightStart,
            "nightLightEnd": root.nightLightEnd,
            "nightLightTransitionMins": root.nightLightTransitionMins,
            "nightLightCurveType": root.nightLightCurveType,
            "nightLightControlPoints": root.nightLightControlPoints,
            "nightLightTargetTemp": root.nightLightTargetTemp,
            "wallpaperShuffle": root.wallpaperShuffle,
            "wallpaperShuffleInterval": root.wallpaperShuffleInterval,
            "wallpaperTransitionType": root.wallpaperTransitionType,
            "wallpaperTransitionDuration": root.wallpaperTransitionDuration,
            "currentWallpaper": root.currentWallpaper,
            "wallpaperDir": root.wallpaperDir,
            "firstRunCompleted": root.firstRunCompleted,
            "matugenEnabled": root.matugenEnabled,
            "themedApps": root.themedApps
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

        if (json.weatherProvider !== undefined) root.weatherProvider = json.weatherProvider
        if (json.weatherLocation !== undefined) root.weatherLocation = json.weatherLocation
        if (json.weatherApiKey !== undefined) root.weatherApiKey = json.weatherApiKey
        if (json.weatherPollIntervalMins !== undefined) root.weatherPollIntervalMins = json.weatherPollIntervalMins
        if (json.barInfoMode !== undefined) root.barInfoMode = json.barInfoMode
        if (json.layout !== undefined) root.layout = json.layout
        if (json.barEdgePosition !== undefined) root.barEdgePosition = json.barEdgePosition
        if (json.autoHideBar !== undefined) root.autoHideBar = json.autoHideBar
        if (json.dnd !== undefined) root.dnd = json.dnd

        if (json.nightLightSchedule !== undefined) root.nightLightSchedule = json.nightLightSchedule
        if (json.nightLightStart !== undefined) root.nightLightStart = json.nightLightStart
        if (json.nightLightEnd !== undefined) root.nightLightEnd = json.nightLightEnd
        if (json.nightLightTransitionMins !== undefined) root.nightLightTransitionMins = json.nightLightTransitionMins
        if (json.nightLightCurveType !== undefined) root.nightLightCurveType = json.nightLightCurveType
        if (json.nightLightControlPoints !== undefined) root.nightLightControlPoints = json.nightLightControlPoints
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

        root.loaded = true
    }

    // Parse KEY=VALUE from .env
    function applyEnv(text) {
        if (!text) return
        var lines = text.split("\n")
        var map = {}
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (!line || line.startsWith("#")) continue
            var eq = line.indexOf("=")
            if (eq === -1) continue
            var key = line.substring(0, eq).trim()
            var val = line.substring(eq + 1).trim()
            if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
                val = val.substring(1, val.length - 1)
            }
            map[key] = val
        }

        if (map.FLUI_WEATHER_PROVIDER !== undefined) root.weatherProvider = map.FLUI_WEATHER_PROVIDER
        if (map.FLUI_WEATHER_LOCATION !== undefined) root.weatherLocation = map.FLUI_WEATHER_LOCATION
        if (map.FLUI_WEATHER_API_KEY !== undefined) root.weatherApiKey = map.FLUI_WEATHER_API_KEY
        if (map.FLUI_WEATHER_POLL_INTERVAL !== undefined) root.weatherPollIntervalMins = parseInt(map.FLUI_WEATHER_POLL_INTERVAL) || 5
        if (map.FLUI_LAYOUT !== undefined) root.layout = parseInt(map.FLUI_LAYOUT) || 0
        if (map.FLUI_BAR_EDGE_POSITION !== undefined) root.barEdgePosition = parseInt(map.FLUI_BAR_EDGE_POSITION) || 0
        if (map.FLUI_BAR_INFO_MODE !== undefined) root.barInfoMode = map.FLUI_BAR_INFO_MODE
        if (map.FLUI_AUTOHIDE !== undefined) root.autoHideBar = (map.FLUI_AUTOHIDE === "true")
        if (map.FLUI_DND !== undefined) root.dnd = (map.FLUI_DND === "true")
        if (map.FLUI_NIGHTLIGHT_SCHEDULE !== undefined) root.nightLightSchedule = (map.FLUI_NIGHTLIGHT_SCHEDULE === "true")
        if (map.FLUI_NIGHTLIGHT_START !== undefined) root.nightLightStart = map.FLUI_NIGHTLIGHT_START
        if (map.FLUI_NIGHTLIGHT_END !== undefined) root.nightLightEnd = map.FLUI_NIGHTLIGHT_END
        if (map.FLUI_NIGHTLIGHT_TRANSITION_MINS !== undefined) root.nightLightTransitionMins = parseInt(map.FLUI_NIGHTLIGHT_TRANSITION_MINS) || 15
        if (map.FLUI_NIGHTLIGHT_TARGET_TEMP !== undefined) root.nightLightTargetTemp = parseInt(map.FLUI_NIGHTLIGHT_TARGET_TEMP) || 4500
        if (map.FLUI_NIGHTLIGHT_CURVE !== undefined) root.nightLightCurveType = map.FLUI_NIGHTLIGHT_CURVE

        if (map.FLUI_WALLPAPER_DIR !== undefined) root.wallpaperDir = map.FLUI_WALLPAPER_DIR.replace("$HOME", Quickshell.env("HOME"))
        if (map.FLUI_CURRENT_WALLPAPER !== undefined) root.currentWallpaper = map.FLUI_CURRENT_WALLPAPER.replace("$HOME", Quickshell.env("HOME"))
        if (map.FLUI_WALLPAPER_SHUFFLE !== undefined) root.wallpaperShuffle = (map.FLUI_WALLPAPER_SHUFFLE === "true")
        if (map.FLUI_WALLPAPER_SHUFFLE_INTERVAL !== undefined) root.wallpaperShuffleInterval = map.FLUI_WALLPAPER_SHUFFLE_INTERVAL
        if (map.FLUI_WALLPAPER_TRANSITION_TYPE !== undefined) root.wallpaperTransitionType = map.FLUI_WALLPAPER_TRANSITION_TYPE
        if (map.FLUI_WALLPAPER_TRANSITION_DURATION !== undefined) root.wallpaperTransitionDuration = parseInt(map.FLUI_WALLPAPER_TRANSITION_DURATION) || 2
        if (map.FLUI_FIRST_RUN_COMPLETED !== undefined) root.firstRunCompleted = (map.FLUI_FIRST_RUN_COMPLETED === "true")
        if (map.FLUI_MATUGEN_ENABLED !== undefined) root.matugenEnabled = (map.FLUI_MATUGEN_ENABLED === "true")

        if (map.FLUI_THEMED_APPS !== undefined) {
            var apps = map.FLUI_THEMED_APPS.split(",")
            var appObj = {}
            for (var a = 0; a < apps.length; a++) {
                var name = apps[a].trim()
                if (name) appObj[name] = true
            }
            root.themedApps = Object.assign({}, root.themedApps, appObj)
        }

        root.loaded = true
    }

    FileView {
        id: envFile
        path: root.envPath
        watchChanges: true
        onLoaded: {
            root.applyEnv(text())
        }
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
