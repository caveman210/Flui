pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configPath: "settings.json"

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
            "nightLightTargetTemp": root.nightLightTargetTemp
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
