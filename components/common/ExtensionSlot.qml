import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../config"
import "../../island"

// Declarative slot injection & replacement component
// Dynamically resizes to available space wrt space harness and layout constraints.
// Zero-cost when empty: implicit width/height collapse to 0
Item {
    id: root

    property string slotName: ""
    property string positionFilter: "append" // "append", "prepend", or "all"
    property string orientation: "vertical" // "vertical" or "horizontal"
    property bool cycle: false
    property int cycleIntervalMs: 1800000 // 30 minutes
    property int currentIndex: 0
    property SpaceHarness spaceHarness: null
    property real availableWidth: -1
    default property alias defaultContent: defaultContainer.children

    // Space adaptation & privacy cluster awareness
    readonly property bool isBar: IslandState.layoutIsBar || ConfigStore.layout === 2
    readonly property int privacyCount: !isBar
        ? ((PrivacyService.micActive ? 1 : 0) + (PrivacyService.cameraActive ? 1 : 0) + (PrivacyService.screenSharingActive ? 1 : 0))
        : 0
    readonly property bool privacyActive: privacyCount > 0

    // Internal fallback harness if no external SpaceHarness is provided by container
    SpaceHarness {
        id: internalHarness
        totalWidth: root.availableWidth >= 0 ? root.availableWidth : 260
        isBar: root.isBar
        privacyCount: root.privacyCount
        privacyActive: root.privacyActive
    }

    readonly property SpaceHarness activeHarness: spaceHarness ? spaceHarness : internalHarness
    readonly property alias slotHarness: root.activeHarness
    readonly property alias harness: root.activeHarness

    function _bindHarness(targetItem) {
        if (!targetItem) return
        try {
            if ("slotHarness" in targetItem) targetItem.slotHarness = activeHarness
            if ("harness" in targetItem) targetItem.harness = activeHarness
        } catch (e) {}
    }

    // Automatic 1-frame remap on layout switch (Pill <-> Notch <-> Bar) to flush stale geometry
    property bool _mounted: true

    Connections {
        target: IslandState
        function onLayoutChanged() {
            root._mounted = false
            remountTimer.restart()
        }
    }

    Timer {
        id: remountTimer
        interval: 16
        repeat: false
        onTriggered: root._mounted = true
    }

    readonly property var injections: (PluginService.slotRegistry && PluginService.slotRegistry[slotName]) ? PluginService.slotRegistry[slotName] : []
    readonly property string replacementSource: {
        for (var i = 0; i < root.injections.length; i++) {
            if (root.injections[i].position === "replace") return root.injections[i].source
        }
        return ""
    }
    readonly property bool isReplaced: replacementSource.length > 0

    Timer {
        id: cycleTimer
        interval: root.cycleIntervalMs
        running: root.cycle && root.injections.length > 1
        repeat: true
        onTriggered: {
            root.currentIndex = (root.currentIndex + 1) % root.injections.length
        }
    }

    readonly property var effectiveInjections: {
        if (!root.cycle || root.injections.length <= 1)
            return root.injections
        var idx = root.currentIndex % root.injections.length
        return [root.injections[idx]]
    }

    readonly property string currentPluginId: {
        if (effectiveInjections.length > 0 && effectiveInjections[0]) {
            return effectiveInjections[0].pluginId || ""
        }
        return ""
    }

    visible: isReplaced || injections.length > 0 || defaultContainer.children.length > 0
    Layout.fillWidth: (orientation === "horizontal" && activeHarness.remainingWidth > 0) || (orientation === "vertical" && visible)
    implicitHeight: visible ? (orientation === "horizontal" ? rowLayout.implicitHeight : colLayout.implicitHeight) : 0
    implicitWidth: visible ? (orientation === "horizontal"
        ? (activeHarness.totalWidth > 0 ? Math.min(rowLayout.implicitWidth, activeHarness.remainingWidth) : rowLayout.implicitWidth)
        : colLayout.implicitWidth) : 0

    width: (orientation === "horizontal" && activeHarness.totalWidth > 0)
        ? Math.min(rowLayout.implicitWidth, activeHarness.remainingWidth)
        : implicitWidth
    height: implicitHeight

    Layout.preferredWidth: implicitWidth
    Layout.maximumWidth: (orientation === "horizontal" && activeHarness.totalWidth > 0) ? activeHarness.remainingWidth : -1
    clip: orientation === "horizontal" && activeHarness.totalWidth > 0

    // Vertical layout mode (default for panels, calendars, etc.)
    ColumnLayout {
        id: colLayout
        visible: root.orientation === "vertical"
        anchors.fill: root.orientation === "vertical" ? parent : undefined
        spacing: 8

        Loader {
            id: replacementLoader
            visible: root.isReplaced
            Layout.fillWidth: true
            source: root.replacementSource
            active: root.isReplaced && root.orientation === "vertical" && root._mounted
            asynchronous: true
            onLoaded: root._bindHarness(item)
        }

        Item {
            id: defaultContainer
            visible: !root.isReplaced
            Layout.fillWidth: true
            implicitHeight: childrenRect.height
            implicitWidth: childrenRect.width
        }

        Repeater {
            model: (root.orientation === "vertical" && !root.isReplaced) ? root.effectiveInjections : 0
            delegate: Loader {
                id: vertLoader
                required property var modelData
                readonly property bool pluginActive: (ConfigStore.disabledPlugins, ConfigStore.enabledPlugins, PluginService.isPluginEnabled(modelData.pluginId))

                visible: pluginActive && (root.positionFilter === "all" || modelData.position === root.positionFilter) && (!item || item.visible)
                active: pluginActive && root._mounted
                Layout.fillWidth: visible
                source: pluginActive ? modelData.source : ""
                asynchronous: true
                onLoaded: root._bindHarness(item)
            }
        }
    }

    // Horizontal layout mode (for bar slots, left clusters, etc.)
    RowLayout {
        id: rowLayout
        visible: root.orientation === "horizontal"
        anchors.verticalCenter: root.orientation === "horizontal" ? parent.verticalCenter : undefined
        anchors.left: root.orientation === "horizontal" ? parent.left : undefined
        spacing: 12

        Repeater {
            model: (root.orientation === "horizontal" && !root.isReplaced) ? root.effectiveInjections : 0
            delegate: Loader {
                id: horizLoader
                required property var modelData
                readonly property bool pluginActive: (ConfigStore.disabledPlugins, ConfigStore.enabledPlugins, PluginService.isPluginEnabled(modelData.pluginId))

                visible: pluginActive && (root.positionFilter === "all" || modelData.position === root.positionFilter) && (!item || item.visible)
                active: pluginActive && root._mounted
                Layout.alignment: Qt.AlignVCenter
                source: pluginActive ? modelData.source : ""
                asynchronous: true
                onLoaded: root._bindHarness(item)
            }
        }
    }
}
