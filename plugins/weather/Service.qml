import QtQuick
import "."

Item {
    id: root

    // When spawned by PluginService (plugin enabled in store):
    Component.onCompleted: {
        WeatherService.refresh()
    }

    Timer {
        id: pollTimer
        interval: WeatherService.pollIntervalMins * 60 * 1000
        running: true
        repeat: true
        onTriggered: WeatherService.refresh()
    }

    // When unmounted by PluginService (plugin disabled in store):
    // Qt automatically stops and destroys pollTimer with root
}
