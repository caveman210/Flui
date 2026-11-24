import QtQuick

// Dynamic Space Allocation Harness
// Coordinates available space amongst coexisting processes, clusters, and plugins.
QtObject {
    id: root

    property real totalWidth: 0
    property var allotments: ({})
    property bool isBar: false
    property int privacyCount: 0
    property bool privacyActive: false

    signal spaceChanged(real remainingWidth, real allottedWidth)

    // Sum of all space requested and allotted to other processes
    readonly property real allottedWidth: {
        var sum = 0
        for (var p in allotments) {
            sum += (Number(allotments[p]) || 0)
        }
        return sum
    }

    // Remaining space available to be occupied by the plugin system
    readonly property real remainingWidth: Math.max(0, totalWidth - allottedWidth)
    readonly property real availableWidth: remainingWidth

    readonly property bool compact: !isBar && (privacyActive || remainingWidth < 80)
    readonly property bool iconOnly: !isBar && (privacyCount >= 2 || remainingWidth < 45)

    onRemainingWidthChanged: spaceChanged(remainingWidth, allottedWidth)

    function requestSpace(processId, width) {
        if (!processId) return
        var next = Object.assign({}, allotments)
        var w = Math.max(0, Number(width) || 0)
        if (w === 0) {
            delete next[processId]
        } else {
            next[processId] = w
        }
        allotments = next
    }

    function releaseSpace(processId) {
        requestSpace(processId, 0)
    }

    function getAllotment(processId) {
        return (processId && allotments[processId]) ? Number(allotments[processId]) : 0
    }
}
