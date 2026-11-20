pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

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
    property string currentProvider: ConfigStore.weatherProvider || "openmeteo"
    property string lastUpdated: ""
    property double lastUpdatedTimestamp: 0 // ms since epoch
    property string errorMessage: ""
    property bool loading: false
    property bool loaded: false

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
        ConfigStore.weatherProvider = providerId
        ConfigStore.save()
        root.currentProvider = providerId
        root.refresh()
    }

    function refresh() {
        if (loading) return
        loading = true
        errorMessage = ""

        var prov = ConfigStore.weatherProvider || "aggregator"
        var loc = ConfigStore.weatherLocation ? ConfigStore.weatherLocation.trim() : ""
        fetchProc.command = [
            Quickshell.env("HOME") + "/.config/quickshell/helpers/target/release/flui-helper",
            "weather",
            prov,
            loc
        ]
        fetchProc.running = false
        fetchProc.running = true
    }

    Timer {
        id: pollTimer
        interval: Math.max(1, ConfigStore.weatherPollIntervalMins || 5) * 60 * 1000 // 5 minutes default
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Connections {
        target: ConfigStore
        function onWeatherLocationChanged() {
            root.refresh()
        }
        function onWeatherProviderChanged() {
            root.currentProvider = ConfigStore.weatherProvider || "openmeteo"
            root.refresh()
        }
        function onWeatherPollIntervalMinsChanged() {
            pollTimer.interval = Math.max(1, ConfigStore.weatherPollIntervalMins || 5) * 60 * 1000
        }
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
                        root.lastUpdated = data.updated || ""
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
    }
}
