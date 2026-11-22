pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import ".."
import "../compositor"
import "../../config"

Singleton {
    id: root

    readonly property string backend: {
        if (CompositorService.isHyprland)
            return "hyprsunset"
        if (CompositorService.isNiri)
            return "gammastep"
        return ""
    }

    readonly property string probeScript: "pgrep " + root.backend + " >/dev/null && echo on || echo off"

    readonly property string killScript: root.backend === "gammastep"
        ? "pkill -9 gammastep 2>/dev/null; " +
          "i=0; while [ $i -lt 16 ] && pgrep gammastep >/dev/null; do sleep 0.1; i=$((i+1)); done; " +
          "setsid --fork gammastep -x >/dev/null 2>&1; sleep 0.5; " +
          "pkill -9 gammastep 2>/dev/null"
        : "pkill hyprsunset"

    property bool gammastepInstalled: false

    onGammastepInstalledChanged: {
        if (gammastepInstalled)
            root.update()
    }

    property bool available: backend === "hyprsunset"
        || (backend === "gammastep" && gammastepInstalled)

    property bool enabled: false
    property string subtitle: !available ? "N/A" : (enabled ? "On" : "Off")
    property string icon: enabled ? "󰔎" : "󰃞"

    property int currentTemp: 6500

    property bool wantOn: false
    property bool hasWant: false
    property bool probing: false
    property bool acting: false
    property int retries: 0

    // Schedule: Simple start and end time check
    function isInSchedule(startStr, endStr) {
        var now = new Date()
        var curMin = now.getHours() * 60 + now.getMinutes()

        var s = (startStr || "20:00").split(":")
        var e = (endStr || "07:00").split(":")
        var startMin = parseInt(s[0], 10) * 60 + parseInt(s[1] || "0", 10)
        var endMin = parseInt(e[0], 10) * 60 + parseInt(e[1] || "0", 10)

        if (startMin <= endMin) {
            return curMin >= startMin && curMin < endMin
        } else {
            return curMin >= startMin || curMin < endMin
        }
    }

    Timer {
        id: scheduleTimer
        interval: 60000
        repeat: true
        running: ConfigStore.nightLightSchedule && root.available
        triggeredOnStart: true
        onTriggered: root.checkSchedule()
    }

    function checkSchedule() {
        if (!ConfigStore.nightLightSchedule || !root.available)
            return

        var shouldBeOn = isInSchedule(ConfigStore.nightLightStart, ConfigStore.nightLightEnd)
        var targetTemp = ConfigStore.nightLightTargetTemp || 4500

        if (shouldBeOn) {
            if (!root.enabled || root.currentTemp !== targetTemp) {
                root.wantOn = true
                root.hasWant = true
                root.retries = 0
                root.enabled = true
                root.currentTemp = targetTemp
                root.reconcile()
            }
        } else {
            if (root.enabled || root.currentTemp !== 6500) {
                root.wantOn = false
                root.hasWant = true
                root.retries = 0
                root.enabled = false
                root.currentTemp = 6500
                root.reconcile()
            }
        }
    }

    Process {
        id: whichProcess
        command: ["bash", "-c", "command -v gammastep >/dev/null 2>&1"]
        onExited: (exitCode, exitStatus) => {
            root.gammastepInstalled = exitCode === 0
        }
    }

    Process {
        id: stateProcess
        command: ["bash", "-c", root.probeScript]
        stdout: StdioCollector {
            onStreamFinished: {
                root.probing = false
                root.handleActual(text.trim() === "on")
            }
        }
    }

    Process {
        id: actProcess
        onExited: (exitCode, exitStatus) => {
            root.acting = false
            settleTimer.restart()
        }
    }

    Timer {
        id: settleTimer
        interval: 350
        repeat: false
        onTriggered: root.reconcile()
    }

    function update() {
        root.reconcile()
    }

    function toggle() {
        if (!root.available)
            return

        root.wantOn = root.hasWant ? !root.wantOn : !root.enabled
        root.hasWant = true
        root.retries = 0
        root.enabled = root.wantOn
        root.currentTemp = root.wantOn ? (ConfigStore.nightLightTargetTemp || 4500) : 6500
        root.reconcile()
    }

    function reconcile() {
        if (!root.available || root.probing || root.acting)
            return

        root.probing = true
        stateProcess.running = false
        stateProcess.running = true
    }

    function handleActual(actual) {
        if (!root.hasWant) {
            root.enabled = actual
            return
        }

        if (actual === root.wantOn && (!actual || root.currentTemp === (ConfigStore.nightLightTargetTemp || 4500))) {
            root.enabled = actual
            root.hasWant = false
            return
        }

        if (root.retries >= 3) {
            root.enabled = actual
            root.hasWant = false
            return
        }

        root.retries += 1

        if (root.wantOn) {
            var temp = root.currentTemp || (ConfigStore.nightLightTargetTemp || 4500)
            actProcess.command = root.backend === "gammastep"
                ? ["bash", "-c", "pkill -9 gammastep 2>/dev/null; setsid --fork gammastep -m wayland -t " + temp + ":" + temp + " -l 0:0 >/dev/null 2>&1"]
                : ["bash", "-c", "pkill hyprsunset 2>/dev/null; setsid --fork hyprsunset --temperature " + temp + " >/dev/null 2>&1"]
        } else {
            actProcess.command = ["bash", "-c", root.killScript]
        }

        root.acting = true
        actProcess.running = true
    }

    Component.onCompleted: {
        if (root.backend === "gammastep")
            whichProcess.running = true

        update()
        if (ConfigStore.nightLightSchedule)
            checkSchedule()
    }
}
