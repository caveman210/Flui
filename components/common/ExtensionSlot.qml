import QtQuick
import QtQuick.Layouts
import "../../services"

// Declarative slot injection & replacement component
// Zero-cost when empty: implicit width/height collapse to 0
ColumnLayout {
    id: root

    property string slotName: ""
    property string positionFilter: "append" // "append", "prepend", or "all"
    default property alias defaultContent: defaultContainer.children

    readonly property string replacementSource: PluginService.getSlotReplacement(slotName)
    readonly property bool isReplaced: replacementSource.length > 0
    readonly property var injections: PluginService.getSlotInjections(slotName)

    spacing: 8
    visible: isReplaced || injections.length > 0 || defaultContainer.children.length > 0

    // Full component replacement mode
    Loader {
        id: replacementLoader
        visible: root.isReplaced
        Layout.fillWidth: true
        source: root.replacementSource
        active: root.isReplaced
        asynchronous: true
    }

    // Native content (visible ONLY when not replaced by a plugin)
    Item {
        id: defaultContainer
        visible: !root.isReplaced
        Layout.fillWidth: true
        implicitHeight: childrenRect.height
        implicitWidth: childrenRect.width
    }

    // Injected plugin components (appended or prepended)
    Repeater {
        model: root.isReplaced ? 0 : root.injections
        delegate: Loader {
            required property var modelData
            visible: root.positionFilter === "all" || modelData.position === root.positionFilter
            Layout.fillWidth: true
            source: modelData.source
            asynchronous: true
        }
    }
}
