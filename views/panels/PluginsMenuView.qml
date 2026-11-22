import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 2.15

import Quickshell
import Quickshell.Io

import "../../core"
import "../../services"
import "../../styles"
import "../../config"

FocusScope {
    id: root

    implicitWidth: 540
    // Card height is 68px + 8px spacing = 76px per item
    readonly property int visibleItemCount: Math.min(4, Math.max(1, root.filteredPlugins.length))
    readonly property int listHeight: root.filteredPlugins.length === 0 ? 80 : (visibleItemCount * 74)

    // Dynamically resize window height: expands to fit plugin settings, or caps with scrollbar if tall
    implicitHeight: root.activeConfigPlugin !== null
        ? Math.min(600, settingsFlickable.Layout.preferredHeight + 72)
        : (layout.implicitHeight + 36)

    property string searchQuery: ""
    property string activeCategory: "all"
    property var activeConfigPlugin: null

    readonly property var filteredPlugins: {
        var list = PluginService.plugins || []
        var res = []
        var query = searchQuery.trim().toLowerCase()

        for (var i = 0; i < list.length; i++) {
            var p = list[i]
            if (activeCategory !== "all" && (p.category || "").toLowerCase() !== activeCategory) {
                continue
            }
            if (query.length > 0) {
                var name = (p.name || p.id || "").toLowerCase()
                var desc = (p.description || "").toLowerCase()
                var author = (p.author || "").toLowerCase()
                if (name.indexOf(query) === -1 && desc.indexOf(query) === -1 && author.indexOf(query) === -1) {
                    continue
                }
            }
            res.push(p)
        }
        return res
    }

    Component.onCompleted: {
        PluginService.scan()
        forceActiveFocus()
    }

    ColumnLayout {
        id: layout
        visible: root.activeConfigPlugin === null
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // -----------------------------------------------------
        // HEADER: Title, Count, and "Open Folder" Action
        // -----------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "Plugins"
                color: Theme.textPrimary
                font.pixelSize: 18
                font.bold: true
            }

            Rectangle {
                implicitWidth: countText.implicitWidth + 12
                implicitHeight: 20
                radius: 10
                color: Theme.surfaceVariant

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: root.filteredPlugins.length + " installed"
                    color: Theme.textSecondary
                    font.pixelSize: 10
                }
            }

            Item { Layout.fillWidth: true }

            // Open Plugins Folder Button
            Rectangle {
                implicitWidth: openFolderRow.implicitWidth + 16
                implicitHeight: 28
                radius: 6
                color: openFolderHover.hovered ? Theme.buttonHover : Theme.buttonBackground
                border.color: Theme.border
                border.width: 1

                HoverHandler { id: openFolderHover }
                TapHandler {
                    onTapped: {
                        openDirProc.command = ["xdg-open", Quickshell.env("HOME") + "/.config/quickshell/plugins"]
                        openDirProc.running = false
                        openDirProc.running = true
                    }
                }

                RowLayout {
                    id: openFolderRow
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "󰝰"
                        color: Theme.textSecondary
                        font.family: Theme.iconFontMono
                        font.pixelSize: 12
                    }
                    Text {
                        text: "Open Folder"
                        color: Theme.textPrimary
                        font.pixelSize: 11
                    }
                }
            }
        }

        // -----------------------------------------------------
        // SEARCH INPUT
        // -----------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 34
            radius: 8
            color: Theme.surface
            border.color: searchInput.activeFocus ? Theme.accent : Theme.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "󰍉"
                    color: Theme.textMuted
                    font.family: Theme.iconFontMono
                    font.pixelSize: 13
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Theme.textPrimary
                    font.pixelSize: 12
                    clip: true
                    text: root.searchQuery
                    onTextChanged: root.searchQuery = text

                    Text {
                        visible: !searchInput.text && !searchInput.activeFocus
                        text: "Search plugins..."
                        color: Theme.textMuted
                        font.pixelSize: 12
                    }
                }

                Text {
                    visible: searchInput.text.length > 0
                    text: "󰅖"
                    color: clearHover.hovered ? Theme.textPrimary : Theme.textMuted
                    font.family: Theme.iconFontMono
                    font.pixelSize: 12
                    HoverHandler { id: clearHover }
                    TapHandler { onTapped: searchInput.text = "" }
                }
            }
        }

        // -----------------------------------------------------
        // CATEGORY CHIPS
        // -----------------------------------------------------
        RowLayout {
            spacing: 6
            Layout.fillWidth: true

            Repeater {
                model: [
                    { id: "all", label: "All" },
                    { id: "productivity", label: "Productivity" },
                    { id: "system", label: "System" },
                    { id: "networking", label: "Network" },
                    { id: "ui", label: "UI / Themes" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool isSelected: root.activeCategory === modelData.id
                    implicitWidth: catText.implicitWidth + 16
                    implicitHeight: 24
                    radius: 12
                    color: isSelected ? Theme.accent : (catHover.hovered ? Theme.buttonHover : Theme.surfaceVariant)

                    HoverHandler { id: catHover }
                    TapHandler { onTapped: root.activeCategory = modelData.id }

                    Text {
                        id: catText
                        anchors.centerIn: parent
                        text: modelData.label
                        color: isSelected ? Theme.background : Theme.textSecondary
                        font.pixelSize: 11
                        font.bold: isSelected
                    }
                }
            }
        }

        // -----------------------------------------------------
        // PLUGINS LIST VIEW (Max 4 visible at once, resizes cleanly)
        // -----------------------------------------------------
        Text {
            visible: root.filteredPlugins.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "No plugins installed in ~/.config/quickshell/plugins"
            color: Theme.textMuted
            font.pixelSize: 12
        }

        ListView {
            id: listView
            visible: root.filteredPlugins.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: root.listHeight
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            model: root.filteredPlugins

            ScrollBar.vertical: ScrollBar {
                policy: root.filteredPlugins.length > 4 ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
            }

            delegate: Rectangle {
                id: card
                required property var modelData
                readonly property bool isEnabled: (ConfigStore.disabledPlugins, ConfigStore.enabledPlugins, PluginService.isPluginEnabled(modelData.id))
                readonly property bool isValid: modelData.is_valid !== false

                width: listView.width
                implicitHeight: cardLayout.implicitHeight + 20
                radius: 10
                color: Theme.surface
                border.color: isEnabled ? Theme.borderHover : Theme.border
                border.width: 1

                ColumnLayout {
                    id: cardLayout
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Icon Capsule
                        Rectangle {
                            implicitWidth: 32
                            implicitHeight: 32
                            radius: 8
                            color: Theme.surfaceVariant

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon || "󰏖"
                                color: isEnabled ? Theme.accent : Theme.textSecondary
                                font.family: Theme.iconFontMono
                                font.pixelSize: 16
                            }
                        }

                        // Title, Version & Author
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                spacing: 6
                                Text {
                                    text: modelData.name || modelData.id
                                    color: Theme.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                                Text {
                                    text: "v" + (modelData.version || "1.0.0")
                                    color: Theme.textMuted
                                    font.pixelSize: 10
                                }
                            }

                            Text {
                                text: (modelData.description || "External Flui plugin")
                                color: Theme.textSecondary
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Individual Plugin Settings Button
                        // STRICT RULE: Visible ONLY when the plugin is enabled AND provides settings
                        Rectangle {
                            visible: isEnabled && !!modelData.settings_entry
                            implicitWidth: settingsBtnRow.implicitWidth + 16
                            implicitHeight: 26
                            radius: 13
                            color: gearHover.hovered ? Theme.buttonHover : Theme.surfaceVariant
                            border.color: Theme.border
                            border.width: 1

                            RowLayout {
                                id: settingsBtnRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: "󰒓"
                                    color: Theme.accent
                                    font.family: Theme.iconFont
                                    font.pixelSize: 12
                                }

                                Text {
                                    text: "Settings"
                                    color: Theme.textPrimary
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            HoverHandler { id: gearHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    root.activeConfigPlugin = modelData
                                }
                            }
                        }

                        // Toggle Switch
                        Rectangle {
                            implicitWidth: 38
                            implicitHeight: 20
                            radius: 10
                            color: isEnabled ? Theme.accent : Theme.buttonBackground
                            border.color: Theme.border
                            border.width: 1

                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                anchors.verticalCenter: parent.verticalCenter
                                x: isEnabled ? parent.width - width - 3 : 3
                                color: isEnabled ? Theme.background : Theme.textSecondary
                                Behavior on x {
                                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                                }
                            }

                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    PluginService.togglePlugin(modelData.id)
                                    // If this plugin was currently open in settings, immediately close it
                                    if (root.activeConfigPlugin && root.activeConfigPlugin.id === modelData.id) {
                                        root.activeConfigPlugin = null
                                    }
                                }
                            }
                        }
                    }

                    // Metadata & Extension badges
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: (modelData.extensions && modelData.extensions.length > 0) || modelData.hooks || !isValid

                        // Error badge if files are missing
                        Rectangle {
                            visible: !isValid
                            implicitWidth: errText.implicitWidth + 8
                            implicitHeight: 18
                            radius: 4
                            color: Theme.danger
                            Text {
                                id: errText
                                anchors.centerIn: parent
                                text: "Missing Files"
                                color: Theme.background
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }

                        Repeater {
                            model: modelData.extensions || []
                            delegate: Rectangle {
                                required property var modelData
                                implicitWidth: extText.implicitWidth + 8
                                implicitHeight: 18
                                radius: 4
                                color: Theme.surfaceVariant

                                Text {
                                    id: extText
                                    anchors.centerIn: parent
                                    text: "Slot: " + modelData.slot
                                    color: Theme.textMuted
                                    font.pixelSize: 9
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: modelData.author ? ("by " + modelData.author) : ""
                            color: Theme.textMuted
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }

    // -----------------------------------------------------
    // INLINE PLUGIN SETTINGS VIEW
    // Rendered ONLY for an individual enabled plugin with settings
    // Dynamically sized with scrollbar when content exceeds bounds
    // -----------------------------------------------------
    ColumnLayout {
        id: settingsContainer
        visible: root.activeConfigPlugin !== null && PluginService.isPluginEnabled(root.activeConfigPlugin.id)
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: backGearHover.hovered ? Theme.buttonHover : Theme.surface
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "󰁍"
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: 14
                }

                HoverHandler { id: backGearHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.activeConfigPlugin = null }
            }

            Text {
                text: root.activeConfigPlugin ? (root.activeConfigPlugin.name || root.activeConfigPlugin.id) + " Settings" : "Plugin Settings"
                color: Theme.textPrimary
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
            }
        }

        Flickable {
            id: settingsFlickable
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(500, pluginSettingsLoader.item ? pluginSettingsLoader.item.implicitHeight : 260)
            contentWidth: width
            contentHeight: pluginSettingsLoader.item ? pluginSettingsLoader.item.implicitHeight : 0
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: settingsFlickable.contentHeight > settingsFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
            }

            Loader {
                id: pluginSettingsLoader
                width: settingsFlickable.width - (settingsFlickable.contentHeight > settingsFlickable.height ? 8 : 0)
                active: root.activeConfigPlugin !== null && PluginService.isPluginEnabled(root.activeConfigPlugin.id)
                source: (root.activeConfigPlugin && root.activeConfigPlugin.settings_entry && PluginService.isPluginEnabled(root.activeConfigPlugin.id))
                    ? ("file://" + root.activeConfigPlugin.settings_entry)
                    : ""
            }
        }
    }

    Process {
        id: openDirProc
    }
}
