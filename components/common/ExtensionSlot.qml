import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../config"

// Declarative slot injection & replacement component
// Zero-cost when empty: implicit width/height collapse to 0
Item {
    id: root

    property string slotName: ""
    property string positionFilter: "append" // "append", "prepend", or "all"
    property string orientation: "vertical" // "vertical" or "horizontal"
    property bool cycle: false
    property int cycleIntervalMs: 1800000 // 30 minutes
    property int currentIndex: 0
    default property alias defaultContent: defaultContainer.children

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
    Layout.fillWidth: orientation === "vertical" && visible
    implicitHeight: visible ? (orientation === "horizontal" ? rowLayout.implicitHeight : colLayout.implicitHeight) : 0
    implicitWidth: visible ? (orientation === "horizontal" ? rowLayout.implicitWidth : colLayout.implicitWidth) : 0

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
            active: root.isReplaced && root.orientation === "vertical"
            asynchronous: true
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
                required property var modelData
                readonly property bool pluginActive: (ConfigStore.disabledPlugins, ConfigStore.enabledPlugins, PluginService.isPluginEnabled(modelData.pluginId))

                visible: pluginActive && (root.positionFilter === "all" || modelData.position === root.positionFilter)
                active: pluginActive
                Layout.fillWidth: visible
                source: pluginActive ? modelData.source : ""
                asynchronous: true
            }
        }
    }

    // Horizontal layout mode (for bar slots, left clusters, etc.)
    RowLayout {
        id: rowLayout
        visible: root.orientation === "horizontal"
        anchors.verticalCenter: root.orientation === "horizontal" ? parent.verticalCenter : undefined
        spacing: 12

        Repeater {
            model: (root.orientation === "horizontal" && !root.isReplaced) ? root.effectiveInjections : 0
            delegate: Loader {
                required property var modelData
                readonly property bool pluginActive: (ConfigStore.disabledPlugins, ConfigStore.enabledPlugins, PluginService.isPluginEnabled(modelData.pluginId))

                visible: pluginActive && (root.positionFilter === "all" || modelData.position === root.positionFilter)
                active: pluginActive
                Layout.alignment: Qt.AlignVCenter
                source: pluginActive ? modelData.source : ""
                asynchronous: true
            }
        }
    }
}
