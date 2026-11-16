import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../styles"
import "../config"
import "../services/appearance"

FloatingWindow {
    id: root

    visible: ConfigStore.loaded && !ConfigStore.firstRunCompleted

    title: "Flui Setup"
    color: "transparent"

    // Compact, jewel-like floating dialog rather than a full screen expanse
    implicitWidth: 440
    implicitHeight: 490

    // Step navigation: 0 = Wallpaper, 1 = Theming & Permissions
    property int currentStep: 0

    // Auto-detection state
    property string detectedDir: ""
    property int detectedCount: 0
    property string customPath: ""
    property int customPathCount: -1
    property bool matugenInstalled: true

    // Check count whenever custom path changes
    Process {
        id: customPathVerifier
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                root.customPathCount = parseInt(text.trim()) || 0
            }
        }
    }

    function verifyCustomPath(path) {
        if (!path || path.trim().length === 0) {
            root.customPathCount = 0
            return
        }
        var expanded = path.replace("~", Quickshell.env("HOME"))
        customPathVerifier.command = [
            "bash", "-c",
            "if [ -d \"" + expanded + "\" ]; then \
                find \"" + expanded + "\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null | wc -l; \
            else \
                echo '0'; \
            fi"
        ]
        customPathVerifier.running = true
    }
    property var selectedApps: ({
        "quickshell": true,
        "kitty": false,
        "gtk": false,
        "cava": false,
        "zen": false,
        "nvim": false,
        "yazi": false,
        "hyprlock": false
    })

    // Detect wallpapers
    Process {
        id: dirScanner
        command: [
            "bash", "-c",
            "for d in \"$HOME/Pictures/Wallpapers\" \"$HOME/Wallpapers\" \"$HOME/Pictures\"; do \
                if [ -d \"$d\" ]; then \
                    cnt=$(find \"$d\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null | wc -l); \
                    if [ \"$cnt\" -gt 0 ]; then echo \"$d:$cnt\"; exit 0; fi; \
                fi; \
            done; \
            echo \":0\""
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var out = text.trim()
                if (out.indexOf(":") !== -1) {
                    var parts = out.split(":")
                    if (parts[0].length > 0) {
                        root.detectedDir = parts[0]
                        root.detectedCount = parseInt(parts[1]) || 0
                        root.customPath = parts[0]
                    }
                }
            }
        }
    }

    // Detect matugen binary
    Process {
        id: matugenChecker
        command: ["bash", "-c", "command -v matugen >/dev/null 2>&1 && echo 'yes' || echo 'no'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.matugenInstalled = (text.trim() === "yes")
                ConfigStore.matugenEnabled = root.matugenInstalled
            }
        }
    }

    Component.onCompleted: {
        dirScanner.running = true
        matugenChecker.running = true
    }

    // Main Floating Card Container
    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Theme.card
        border.width: 1
        border.color: Theme.border

        // Subtle top ambient glow
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 40
            height: 1
            color: Qt.rgba(1, 1, 1, 0.08)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 16

            // Top Header: Flui brand badge + Step indicator
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 32
                    height: 32
                    radius: 10
                    color: Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "󰄛"
                        font.family: Theme.iconFont
                        font.pixelSize: 16
                        color: Theme.background
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true

                    Text {
                        text: "Flui Setup"
                        font.pixelSize: 15
                        font.bold: true
                        color: Theme.textPrimary
                    }
                    Text {
                        text: root.currentStep === 0 ? "Step 1 of 2: Wallpapers" : "Step 2 of 2: Matugen & Theming"
                        font.pixelSize: 11
                        color: Theme.textSecondary
                    }
                }

                // Step progress pills
                Row {
                    spacing: 6
                    Rectangle {
                        width: root.currentStep === 0 ? 18 : 6
                        height: 6
                        radius: 3
                        color: root.currentStep === 0 ? Theme.accent : Theme.surfaceVariant
                        Behavior on width { NumberAnimation { duration: 200 } }
                    }
                    Rectangle {
                        width: root.currentStep === 1 ? 18 : 6
                        height: 6
                        radius: 3
                        color: root.currentStep === 1 ? Theme.accent : Theme.surfaceVariant
                        Behavior on width { NumberAnimation { duration: 200 } }
                    }
                }
            }

            // Divider
            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.borderSubtle }

            // ==========================================
            // STEP 0: WALLPAPER DISCOVERY
            // ==========================================
            ColumnLayout {
                visible: root.currentStep === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14

                // Playful discovery status capsule
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: 12
                    color: Theme.surface
                    border.width: 1
                    border.color: (root.customPathCount > 0 || (root.customPathCount === -1 && root.detectedCount > 0))
                        ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.3)
                        : Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: (root.customPathCount > 0 || (root.customPathCount === -1 && root.detectedCount > 0))
                                ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.15)
                                : Theme.surfaceVariant

                            Text {
                                anchors.centerIn: parent
                                text: (root.customPathCount > 0 || (root.customPathCount === -1 && root.detectedCount > 0)) ? "󰸉" : "󰅙"
                                font.family: Theme.iconFont
                                font.pixelSize: 14
                                color: (root.customPathCount > 0 || (root.customPathCount === -1 && root.detectedCount > 0)) ? Theme.success : Theme.warning
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                text: {
                                    var count = root.customPathCount !== -1 ? root.customPathCount : root.detectedCount
                                    if (count > 0) return "Ready (" + count + " wallpapers found)"
                                    return "No wallpapers found in directory"
                                }
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: (root.customPath || root.detectedDir || "No folder selected").replace(Quickshell.env("HOME"), "~")
                                font.pixelSize: 10
                                color: Theme.textSecondary
                                elide: Text.ElideMiddle
                            }
                        }
                    }
                }

                Text {
                    text: "Directory Path"
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.textSecondary
                }

                // Interactive path field
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 10
                    color: Theme.surface
                    border.width: 1
                    border.color: dirInput.activeFocus ? Theme.accent : Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: "󰉋"
                            font.family: Theme.iconFont
                            font.pixelSize: 14
                            color: Theme.textMuted
                        }

                        TextInput {
                            id: dirInput
                            Layout.fillWidth: true
                            text: root.customPath || (Quickshell.env("HOME") + "/Pictures/Wallpapers")
                            color: Theme.textPrimary
                            font.pixelSize: 12
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            onTextChanged: {
                                root.customPath = text.trim()
                                root.verifyCustomPath(text.trim())
                            }
                        }
                    }
                }

                // Quick candidate pills
                RowLayout {
                    spacing: 6
                    Layout.fillWidth: true

                    Text {
                        text: "Quick set:"
                        font.pixelSize: 10
                        color: Theme.textMuted
                    }

                    Repeater {
                        model: [
                            { label: "~/Pictures/Wallpapers", path: Quickshell.env("HOME") + "/Pictures/Wallpapers" },
                            { label: "~/Wallpapers", path: Quickshell.env("HOME") + "/Wallpapers" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            height: 22
                            width: pillTxt.implicitWidth + 14
                            radius: 6
                            color: pillHover.hovered ? Theme.surfaceVariant : Theme.surface
                            border.width: 1
                            border.color: Theme.border

                            Text {
                                id: pillTxt
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: 10
                                color: Theme.textSecondary
                            }

                            HoverHandler { id: pillHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    root.customPath = modelData.path
                                    dirInput.text = modelData.path
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // ==========================================
            // STEP 1: MATUGEN & THEME PERMISSIONS
            // ==========================================
            ColumnLayout {
                visible: root.currentStep === 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // Matugen Master Toggle Row
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 12
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            color: ConfigStore.matugenEnabled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Theme.surfaceVariant
                            Text {
                                anchors.centerIn: parent
                                text: "󰏘"
                                font.family: Theme.iconFont
                                font.pixelSize: 13
                                color: ConfigStore.matugenEnabled ? Theme.accent : Theme.textMuted
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                text: "Matugen Dynamic Theming"
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: root.matugenInstalled ? "Active wallpaper extracts color palette" : "Matugen not installed (fallback active)"
                                font.pixelSize: 10
                                color: root.matugenInstalled ? Theme.textSecondary : Theme.warning
                            }
                        }

                        Rectangle {
                            width: 40
                            height: 20
                            radius: 10
                            color: ConfigStore.matugenEnabled ? Theme.accent : Theme.surfaceVariant

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                x: ConfigStore.matugenEnabled ? parent.width - width - 2 : 2
                                width: 16
                                height: 16
                                radius: 8
                                color: ConfigStore.matugenEnabled ? Theme.background : Theme.textSecondary
                                Behavior on x { NumberAnimation { duration: 150 } }
                            }

                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: ConfigStore.matugenEnabled = !ConfigStore.matugenEnabled
                            }
                        }
                    }
                }

                Text {
                    text: "Permitted Apps to Theme"
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.textSecondary
                }

                // Compact App Tag Matrix
                Flow {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { id: "quickshell", name: "Flui Shell", icon: "󰄛" },
                            { id: "kitty", name: "Kitty", icon: "󰄛" },
                            { id: "gtk", name: "GTK Apps", icon: "󰗃" },
                            { id: "cava", name: "Cava", icon: "󰎈" },
                            { id: "zen", name: "Zen Browser", icon: "󰈹" },
                            { id: "nvim", name: "Neovim", icon: "󰅳" },
                            { id: "yazi", name: "Yazi", icon: "󰉋" },
                            { id: "hyprlock", name: "Lockscreen", icon: "󰌾" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            height: 28
                            width: tagRow.implicitWidth + 18
                            radius: 8
                            color: (root.selectedApps[modelData.id] || false)
                                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                                : Theme.surface
                            border.width: 1
                            border.color: (root.selectedApps[modelData.id] || false) ? Theme.accent : Theme.border

                            Row {
                                id: tagRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (root.selectedApps[modelData.id] || false) ? "✓" : "+"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: (root.selectedApps[modelData.id] || false) ? Theme.accent : Theme.textMuted
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    font.pixelSize: 11
                                    font.bold: root.selectedApps[modelData.id] || false
                                    color: (root.selectedApps[modelData.id] || false) ? Theme.accent : Theme.textPrimary
                                }
                            }

                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    var updated = Object.assign({}, root.selectedApps)
                                    updated[modelData.id] = !updated[modelData.id]
                                    root.selectedApps = updated
                                }
                            }
                        }
                    }
                }

                Text {
                    text: "Only checked apps will have config files touched."
                    font.pixelSize: 9
                    color: Theme.textMuted
                }

                Item { Layout.fillHeight: true }
            }

            // Divider
            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.borderSubtle }

            // Footer Navigation Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Back button (Step 1 only)
                Rectangle {
                    visible: root.currentStep === 1
                    width: 70
                    height: 34
                    radius: 17
                    color: backHov.hovered ? Theme.surfaceVariant : Theme.surface
                    border.width: 1
                    border.color: Theme.border

                    Text {
                        anchors.centerIn: parent
                        text: "Back"
                        font.pixelSize: 12
                        color: Theme.textPrimary
                    }

                    HoverHandler { id: backHov; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.currentStep = 0 }
                }

                Item { Layout.fillWidth: true }

                // Next or Finish Button
                Rectangle {
                    width: root.currentStep === 0 ? 90 : 120
                    height: 34
                    radius: 17
                    color: nextHov.hovered ? Qt.lighter(Theme.accent, 1.15) : Theme.accent

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.currentStep === 0 ? "Next" : "Finish"
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.background
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.currentStep === 0 ? "󰅂" : "󰄬"
                            font.family: Theme.iconFont
                            font.pixelSize: 11
                            color: Theme.background
                        }
                    }

                    HoverHandler { id: nextHov; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            if (root.currentStep === 0) {
                                root.currentStep = 1
                            } else {
                                ConfigStore.wallpaperDir = root.customPath || (Quickshell.env("HOME") + "/Pictures/Wallpapers")
                                ConfigStore.themedApps = root.selectedApps
                                ConfigStore.firstRunCompleted = true
                                ConfigStore.save()
                                WallpaperService.reload()
                                root.visible = false
                            }
                        }
                    }
                }
            }
        }
    }
}
