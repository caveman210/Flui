import QtQuick
import "."

Item {
    id: root

    // When spawned by PluginService (plugin enabled in store):
    Component.onCompleted: {
        QuoteService.ensureToday()
    }

    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: QuoteService.ensureToday()
    }

    // When unmounted by PluginService (plugin disabled in store):
    // Qt automatically stops and destroys timer with root
}
