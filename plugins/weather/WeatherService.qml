pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string temp: "--"
    property string feelsLike: "--"
    property string tempHigh: "--"
    property string tempLow: "--"
    property string pressure: "--"
    property string uvIndex: "--"
    property string precipitation: "--"
    property string condition: "Loading..."
    property string icon: "󰖐"
    property string humidity: "--"
    property string wind: "--"
    property string city: ""
    property string providerName: "Open-Meteo"
    property string currentProvider: "openmeteo"
    property string locationOverride: ""
    property int pollIntervalMins: 5
    property string lastUpdated: ""
    property double lastUpdatedTimestamp: 0 // ms since epoch
    property string errorMessage: ""
    property bool loading: false
    property bool loaded: false

    readonly property string configDir: Quickshell.env("HOME") + "/.cache/quickshell/weather"
    readonly property string configFile: configDir + "/config.json"

    // Stale check: true if never loaded successfully or > 1 hour since last successful update
    readonly property bool isStale: !loaded || (lastUpdatedTimestamp > 0 && (Date.now() - lastUpdatedTimestamp) > 3600000)

    readonly property var providers: [
        { id: "openmeteo", name: "Open-Meteo", desc: "Fast & realtime", icon: "󱘖" },
        { id: "wttr", name: "wttr.in", desc: "Lightweight", icon: "󰖐" },
        { id: "metno", name: "MET Norway", desc: "yr.no forecast", icon: "󰼳" },
        { id: "aggregator", name: "Aggregator", desc: "Consensus", icon: "󰖑" }
    ]

    function setProvider(providerId) {
        if (!providerId) return
        root.currentProvider = providerId
        saveConfig()
        root.refresh()
    }

    function setLocation(loc) {
        root.locationOverride = loc ? loc.trim() : ""
        saveConfig()
        root.refresh()
    }

    function setPollInterval(mins) {
        root.pollIntervalMins = Math.max(1, Math.min(60, mins || 5))
        if (pollTimer) pollTimer.interval = root.pollIntervalMins * 60 * 1000
        saveConfig()
    }

    function saveConfig() {
        var data = {
            "provider": root.currentProvider,
            "location": root.locationOverride,
            "pollIntervalMins": root.pollIntervalMins
        }
        var jsonStr = JSON.stringify(data, null, 2)
        saveProc.command = [
            "python3", "-c",
            "import sys, os, pathlib\np = pathlib.Path(sys.argv[1]); p.parent.mkdir(parents=True, exist_ok=True)\ntmp = sys.argv[1] + '.tmp'\nwith open(tmp, 'w') as f: f.write(sys.argv[2])\nos.replace(tmp, sys.argv[1])",
            root.configFile,
            jsonStr
        ]
        saveProc.running = false
        saveProc.running = true
    }

    function loadConfig() {
        loadProc.command = [
            "python3", "-c",
            "import sys, os, json\np = sys.argv[1]\nif os.path.exists(p):\n    with open(p, 'r') as f: print(f.read())\nelse: print('{}')",
            root.configFile
        ]
        loadProc.running = false
        loadProc.running = true
    }

    Process {
        id: loadProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim())
                    if (data.provider) root.currentProvider = data.provider
                    if (data.location !== undefined) root.locationOverride = data.location
                    if (data.pollIntervalMins) {
                        root.pollIntervalMins = data.pollIntervalMins
                        if (pollTimer) pollTimer.interval = root.pollIntervalMins * 60 * 1000
                    }
                } catch (e) {
                    // Default config will be used
                }
                root.refresh()
            }
        }
    }

    Process {
        id: saveProc
    }

    function refresh() {
        if (loading) return
        loading = true
        errorMessage = ""

        var prov = root.currentProvider || "openmeteo"
        var loc = root.locationOverride ? root.locationOverride.trim() : ""
        fetchProc.command = [
            Quickshell.env("HOME") + "/.config/quickshell/helpers/target/release/flui-helper",
            "plugins",
            "run",
            "weather",
            prov,
            loc
        ]
        fetchProc.running = false
        fetchProc.running = true
    }

    Timer {
        id: pollTimer
        interval: root.pollIntervalMins * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: fetchProc
        stdout: StdioCollector {
            id: outCollector
            waitForEnd: true
            onStreamFinished: {
                root.loading = false
                try {
                    var data = JSON.parse(outCollector.text.trim())
                    if (data.success) {
                        root.temp = data.temp || "--"
                        root.feelsLike = data.feels_like || "--"
                        root.tempHigh = data.temp_high || "--"
                        root.tempLow = data.temp_low || "--"
                        root.pressure = data.pressure || "--"
                        root.uvIndex = data.uv_index || "--"
                        root.precipitation = data.precip || "--"
                        root.humidity = data.humidity || "--"
                        root.wind = data.wind || "--"
                        root.condition = data.condition || "Unknown"
                        root.icon = data.icon || "󰖐"
                        root.city = data.city || ""
                        root.providerName = data.providerName || data.provider || "Weather"
                        root.lastUpdated = data.updated || Qt.formatTime(new Date(), "h:mm ap")
                        root.lastUpdatedTimestamp = Date.now()
                        root.loaded = true
                        root.errorMessage = ""
                    } else {
                        root.errorMessage = data.error || "Failed to load weather"
                    }
                } catch (e) {
                    console.log("WeatherService parse error:", e, "output was:", outCollector.text)
                    root.errorMessage = "Parse error"
                }
            }
        }

        onExited: function(exitCode, exitStatus) {
            root.loading = false
        }
    }

    Component.onCompleted: {
        root.loadConfig()
    }
}
