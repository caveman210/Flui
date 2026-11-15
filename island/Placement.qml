pragma Singleton

import QtQuick
import Quickshell
import "../config"

// Which screen edge the island docks to. The preference itself is
// edge-agnostic; layouts opt in to bottom docking through
// IslandState.dockBottom. Persisted in settings.json.
Singleton {
    id: root

    readonly property int top: 0
    readonly property int bottomEdge: 1

    property int edge: ConfigStore.barEdgePosition

    Connections {
        target: ConfigStore
        function onBarEdgePositionChanged() {
            root.edge = ConfigStore.barEdgePosition
        }
    }

    readonly property bool bottom: edge === bottomEdge
    readonly property string subtitle: bottom ? "Bottom" : "Top"
    readonly property string icon: bottom ? "󰁅" : "󰁝"

    function toggle() {
        edge = bottom ? top : bottomEdge
        ConfigStore.barEdgePosition = edge
        ConfigStore.save()
    }

    Component.onCompleted: {
        edge = ConfigStore.barEdgePosition
        console.log("Placement debug:", edge, bottom, subtitle)
    }
}
