import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Quickshell

import "../../components/sections"
import "../../core"
import "../../island"
import "../../services"
import "../../services/appearance"
import "../../config"
import "../../styles"

FocusScope {
    id: root
    implicitWidth: 560
    implicitHeight: 520
    focus: true

    // Navigation subview: "" is Grid View, non-empty is Detail/Theme Submenu
    property string activeWallpaperPath: ""

    // Settings drawer toggle for Shuffle & Transitions
    property bool showSettings: false

    // Custom Color Palette state (ephemeral editing)
    property string customHexInput: ""
    property var activePaletteColors: ({
        background: String(Theme.background),
        surface: String(Theme.surface),
        surfaceVariant: String(Theme.surfaceVariant),
        primary: String(Theme.accent),
        secondary: String(Theme.accentPressed),
        tertiary: String(Theme.accentHover),
        text: String(Theme.textPrimary)
    })

    readonly property int count: WallpaperService.wallpapers.count

    readonly property var intervalOptions: ["15m", "30m", "1h", "3h", "6h", "12h", "1d"]
    readonly property var transitionOptions: ["grow", "fade", "simple", "wipe", "wave", "center", "outer", "random"]

    Component.onCompleted: {
        forceActiveFocus()
        WallpaperService.reload()
    }

    onActiveWallpaperPathChanged: {
        if (activeWallpaperPath.length > 0) {
            WallpaperService.extractPalette(activeWallpaperPath)
        }
    }

    // Main Column
    Column {
        anchors.fill: parent
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 12

        // ==========================================
        // HEADER BAR
        // ==========================================
        Item {
            id: header
            width: parent.width
            height: 30

            // Back button (visible in detail view)
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                visible: root.activeWallpaperPath.length > 0

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: backHover.hovered ? Theme.surfaceVariant : Theme.surface

                    Text {
                        anchors.centerIn: parent
                        text: "󰁍"
                        font.family: Theme.iconFont
                        font.pixelSize: 14
                        color: Theme.textPrimary
                    }

                    HoverHandler {
                        id: backHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            if (WallpaperService.isPreviewing) {
                                WallpaperService.cancelPreview()
                            }
                            root.activeWallpaperPath = ""
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Back to Wallpapers"
                    font.pixelSize: 14
                    color: Theme.textSecondary
                }
            }

            // Title (visible in grid view)
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: root.activeWallpaperPath.length === 0
                text: "Wallpapers"
                font.pixelSize: 18
                font.bold: true
                color: Theme.textPrimary
            }

            // Right header controls (Settings toggle & count)
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                // Shuffle indicator / quick toggle
                Rectangle {
                    visible: root.activeWallpaperPath.length === 0
                    width: shuffleRow.implicitWidth + 14
                    height: 26
                    radius: 13
                    color: ConfigStore.wallpaperShuffle ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Theme.surface
                    border.width: 1
                    border.color: ConfigStore.wallpaperShuffle ? Theme.accent : Theme.border

                    Row {
                        id: shuffleRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰒝"
                            font.family: Theme.iconFont
                            font.pixelSize: 12
                            color: ConfigStore.wallpaperShuffle ? Theme.accent : Theme.textSecondary
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ConfigStore.wallpaperShuffle ? ConfigStore.wallpaperShuffleInterval : "Off"
                            font.pixelSize: 11
                            font.bold: ConfigStore.wallpaperShuffle
                            color: ConfigStore.wallpaperShuffle ? Theme.accent : Theme.textSecondary
                        }
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            ConfigStore.wallpaperShuffle = !ConfigStore.wallpaperShuffle
                            ConfigStore.save()
                        }
                    }
                }

                // Settings button (cog)
                Rectangle {
                    visible: root.activeWallpaperPath.length === 0
                    width: 28
                    height: 28
                    radius: 14
                    color: root.showSettings || cogHover.hovered ? Theme.surfaceVariant : Theme.surface
                    border.width: 1
                    border.color: root.showSettings ? Theme.accent : Theme.border

                    Text {
                        anchors.centerIn: parent
                        text: "󰒓"
                        font.family: Theme.iconFont
                        font.pixelSize: 14
                        color: root.showSettings ? Theme.accent : Theme.textPrimary
                    }

                    HoverHandler {
                        id: cogHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: root.showSettings = !root.showSettings
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.count > 0 && root.activeWallpaperPath.length === 0
                    text: root.count + " images"
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }
            }
        }

        // ==========================================
        // SETTINGS DRAWER (Shuffle & Transition)
        // ==========================================
        Rectangle {
            id: settingsDrawer
            width: parent.width
            height: visible ? settingsCol.implicitHeight + 20 : 0
            visible: root.showSettings && root.activeWallpaperPath.length === 0
            radius: 14
            color: Theme.surface
            border.width: 1
            border.color: Theme.border
            clip: true

            Column {
                id: settingsCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 12

                // Row 1: Auto Shuffle Toggle & Frequency
                RowLayout {
                    width: parent.width
                    spacing: 12

                    Row {
                        spacing: 8
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰒝"
                            font.family: Theme.iconFont
                            font.pixelSize: 13
                            color: ConfigStore.wallpaperShuffle ? Theme.accent : Theme.textMuted
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Shuffle"
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.textPrimary
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        width: 40
                        height: 20
                        radius: 10
                        color: ConfigStore.wallpaperShuffle ? Theme.accent : Theme.surfaceVariant

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            anchors.verticalCenter: parent.verticalCenter
                            x: ConfigStore.wallpaperShuffle ? parent.width - width - 2 : 2
                            color: ConfigStore.wallpaperShuffle ? Theme.background : Theme.textSecondary
                            Behavior on x { NumberAnimation { duration: 150 } }
                        }

                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                ConfigStore.wallpaperShuffle = !ConfigStore.wallpaperShuffle
                                ConfigStore.save()
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Row {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4
                        opacity: ConfigStore.wallpaperShuffle ? 1 : 0.35

                        Repeater {
                            model: root.intervalOptions
                            delegate: Rectangle {
                                required property string modelData
                                width: 34
                                height: 22
                                radius: 6
                                color: ConfigStore.wallpaperShuffleInterval === modelData
                                    ? Theme.accent
                                    : (intHover.hovered ? Theme.surfaceVariant : Theme.background)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: 10
                                    font.bold: ConfigStore.wallpaperShuffleInterval === modelData
                                    color: ConfigStore.wallpaperShuffleInterval === modelData
                                        ? Theme.background
                                        : Theme.textPrimary
                                }

                                HoverHandler { id: intHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    enabled: ConfigStore.wallpaperShuffle
                                    onTapped: {
                                        ConfigStore.wallpaperShuffleInterval = modelData
                                        ConfigStore.save()
                                    }
                                }
                            }
                        }
                    }
                }

                // Divider line
                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.05) }

                // Row 2: Transitions & Duration
                ColumnLayout {
                    width: parent.width
                    spacing: 6

                    // Sub-row 1: Transition type
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Effect:"
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textSecondary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Row {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            Repeater {
                                model: root.transitionOptions
                                delegate: Rectangle {
                                    required property string modelData
                                    width: 42
                                    height: 22
                                    radius: 6
                                    color: ConfigStore.wallpaperTransitionType === modelData
                                        ? Theme.accent
                                        : (transHover.hovered ? Theme.surfaceVariant : Theme.background)

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.pixelSize: 10
                                        font.bold: ConfigStore.wallpaperTransitionType === modelData
                                        color: ConfigStore.wallpaperTransitionType === modelData
                                            ? Theme.background
                                            : Theme.textPrimary
                                    }

                                    HoverHandler { id: transHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: {
                                            ConfigStore.wallpaperTransitionType = modelData
                                            ConfigStore.save()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Sub-row 2: Transition duration
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Speed:"
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textSecondary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Row {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            Repeater {
                                model: [1, 2, 3, 5]
                                delegate: Rectangle {
                                    required property int modelData
                                    width: 32
                                    height: 22
                                    radius: 6
                                    color: ConfigStore.wallpaperTransitionDuration === modelData
                                        ? Theme.accent
                                        : (durHover.hovered ? Theme.surfaceVariant : Theme.background)

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData + "s"
                                        font.pixelSize: 10
                                        font.bold: ConfigStore.wallpaperTransitionDuration === modelData
                                        color: ConfigStore.wallpaperTransitionDuration === modelData
                                            ? Theme.background
                                            : Theme.textPrimary
                                    }

                                    HoverHandler { id: durHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: {
                                            ConfigStore.wallpaperTransitionDuration = modelData
                                            ConfigStore.save()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Divider line
                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.05) }

                // Row 3: Wallpaper Directory Folder
                RowLayout {
                    width: parent.width
                    spacing: 10

                    Text {
                        text: "Directory"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textSecondary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 26
                        radius: 7
                        color: Theme.background
                        border.width: 1
                        border.color: wpDirInput.activeFocus ? Theme.accent : Theme.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 6

                            Text {
                                text: "󰉋"
                                font.family: Theme.iconFont
                                font.pixelSize: 11
                                color: Theme.textMuted
                            }

                            TextInput {
                                id: wpDirInput
                                Layout.fillWidth: true
                                text: (ConfigStore.wallpaperDir || "~/Pictures/Wallpapers").replace(Quickshell.env("HOME"), "~")
                                color: Theme.textPrimary
                                font.pixelSize: 11
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                onEditingFinished: {
                                    var cleaned = text.trim().replace("~", Quickshell.env("HOME"))
                                    ConfigStore.wallpaperDir = cleaned
                                    ConfigStore.save()
                                    WallpaperService.reload()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // VIEW 1: 3-COLUMN TILED SCROLLABLE GRID
        // ==========================================
        Item {
            id: gridContainer
            width: parent.width
            height: root.activeWallpaperPath.length === 0
                ? (root.showSettings ? parent.height - header.height - settingsDrawer.height - 30 : parent.height - header.height - 12)
                : 0
            visible: root.activeWallpaperPath.length === 0
            clip: true

            Text {
                anchors.centerIn: parent
                visible: root.count === 0
                text: "No wallpapers found in ~/Pictures/Wallpapers"
                font.pixelSize: 13
                color: Theme.textSecondary
            }

            GridView {
                id: wallpaperGrid
                anchors.fill: parent
                cellWidth: Math.floor(parent.width / 3)
                cellHeight: 116
                model: WallpaperService.wallpapers
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                delegate: Item {
                    id: cardItem
                    required property int index
                    required property string path

                    width: wallpaperGrid.cellWidth
                    height: wallpaperGrid.cellHeight

                    readonly property bool isCurrent: WallpaperService.currentWallpaper === path

                    WallpaperCard {
                        id: wpCard
                        anchors.centerIn: parent
                        width: parent.width - 10
                        height: parent.height - 10
                        imageSource: cardItem.path
                        selected: cardItem.isCurrent
                        isHovered: cardHover.hovered
                    }

                    HoverHandler {
                        id: cardHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            root.activeWallpaperPath = cardItem.path
                        }
                    }
                }
            }
        }

        // ==========================================
        // VIEW 2: THEME & PALETTE SUBMENU
        // ==========================================
        Item {
            id: detailContainer
            width: parent.width
            height: root.activeWallpaperPath.length > 0 ? parent.height - header.height - 12 : 0
            visible: root.activeWallpaperPath.length > 0

            Column {
                anchors.fill: parent
                spacing: 10

                // Wallpaper preview card & Info
                Item {
                    width: parent.width
                    height: 140

                    WallpaperCard {
                        anchors.centerIn: parent
                        width: parent.width - 20
                        height: 140
                        imageSource: root.activeWallpaperPath
                        selected: true
                    }

                    // Name overlay
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(parent.width - 40, nameText.implicitWidth + 20)
                        height: 22
                        radius: 11
                        color: Qt.rgba(0, 0, 0, 0.72)

                        Text {
                            id: nameText
                            anchors.centerIn: parent
                            text: String(root.activeWallpaperPath).split("/").pop()
                            font.pixelSize: 11
                            color: "#ffffff"
                            elide: Text.ElideMiddle
                        }
                    }
                }

                // Palettes Section
                Item {
                    width: parent.width
                    height: 106

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: WallpaperService.palettes.count > 0
                                ? "Choose Matugen Palette"
                                : "Extracting palettes…"
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textSecondary
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8

                            Repeater {
                                model: WallpaperService.palettes
                                delegate: Item {
                                    id: paletteCard
                                    required property int index
                                    required property string background
                                    required property string surface
                                    required property string surfaceVariant
                                    required property string primary
                                    required property string secondary
                                    required property string tertiary
                                    required property string text
                                    required property string error
                                    required property string source
                                    required property string mode
                                    required property string scheme

                                    readonly property bool selected: WallpaperService.sourceColor === source
                                        && WallpaperService.matugenMode === mode
                                        && WallpaperService.matugenScheme === scheme

                                    width: 88
                                    height: 82

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 10
                                        color: background
                                        border.width: paletteCard.selected ? 2 : 1
                                        border.color: paletteCard.selected ? primary : Theme.border
                                    }

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Grid {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            columns: 4
                                            rowSpacing: 2
                                            columnSpacing: 2

                                            Repeater {
                                                model: [
                                                    paletteCard.background,
                                                    paletteCard.surface,
                                                    paletteCard.surfaceVariant,
                                                    paletteCard.primary,
                                                    paletteCard.secondary,
                                                    paletteCard.tertiary,
                                                    paletteCard.text,
                                                    paletteCard.error
                                                ]

                                                delegate: Rectangle {
                                                    required property string modelData
                                                    width: 14
                                                    height: 14
                                                    radius: 7
                                                    color: modelData
                                                    border.color: paletteCard.background
                                                    border.width: 1
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: paletteCard.scheme.replace("scheme-", "")
                                            font.pixelSize: 8
                                            font.bold: paletteCard.selected
                                            color: paletteCard.text
                                        }
                                    }

                                    HoverHandler { cursorShape: Qt.PointingHandCursor }

                                    TapHandler {
                                        onTapped: {
                                            WallpaperService.sourceColor = paletteCard.source
                                            WallpaperService.matugenMode = paletteCard.mode
                                            WallpaperService.matugenScheme = paletteCard.scheme
                                            root.activePaletteColors = {
                                                background: paletteCard.background,
                                                surface: paletteCard.surface,
                                                surfaceVariant: paletteCard.surfaceVariant,
                                                primary: paletteCard.primary,
                                                secondary: paletteCard.secondary,
                                                tertiary: paletteCard.tertiary,
                                                text: paletteCard.text
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Custom Color & Wallpaper Swatch Picker (Ephemeral Live Editing)
                Rectangle {
                    width: parent.width - 20
                    height: 98
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 10
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.border

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        // Wallpaper dominant colors swatches
                        Row {
                            spacing: 8
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Wallpaper Colors:"
                                font.pixelSize: 11
                                color: Theme.textSecondary
                            }

                            Row {
                                spacing: 6
                                anchors.verticalCenter: parent.verticalCenter
                                Repeater {
                                    model: WallpaperService.extractedColors
                                    delegate: Rectangle {
                                        required property string modelData
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: modelData
                                        border.width: WallpaperService.sourceColor === modelData ? 2 : 1
                                        border.color: WallpaperService.sourceColor === modelData ? Theme.accent : Theme.border

                                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                                        TapHandler {
                                            onTapped: {
                                                WallpaperService.sourceColor = modelData
                                                root.customHexInput = modelData
                                                var colors = Object.assign({}, root.activePaletteColors)
                                                colors.primary = modelData
                                                colors.accent = modelData
                                                root.activePaletteColors = colors
                                                if (WallpaperService.isPreviewing) {
                                                    WallpaperService.applyColorsLive(colors)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Custom Hex Input & Editable Slot Swatches
                        Row {
                            spacing: 10
                            anchors.horizontalCenter: parent.horizontalCenter

                            // Editable active swatches
                            Row {
                                spacing: 4
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Palette Slots:"
                                    font.pixelSize: 11
                                    color: Theme.textSecondary
                                }
                                Repeater {
                                    model: ["primary", "secondary", "background", "surface", "text"]
                                    delegate: Rectangle {
                                        required property string modelData
                                        width: 18
                                        height: 18
                                        radius: 4
                                        color: root.activePaletteColors[modelData] || "#888888"
                                        border.width: 1
                                        border.color: Theme.border

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.charAt(0).toUpperCase()
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: modelData === "background" || modelData === "surface" ? "#ffffff" : "#000000"
                                        }

                                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                                        TapHandler {
                                            onTapped: {
                                                root.customHexInput = String(root.activePaletteColors[modelData])
                                            }
                                        }
                                    }
                                }
                            }

                            // Hex Input Field
                            Row {
                                spacing: 4
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: 80
                                    height: 24
                                    radius: 6
                                    color: Theme.inputBackground
                                    border.width: 1
                                    border.color: hexInput.activeFocus ? Theme.accent : Theme.inputBorder

                                    TextInput {
                                        id: hexInput
                                        anchors.centerIn: parent
                                        width: parent.width - 8
                                        text: root.customHexInput || WallpaperService.sourceColor || "#"
                                        color: Theme.textPrimary
                                        font.pixelSize: 11
                                        maximumLength: 7
                                        selectByMouse: true
                                        onTextChanged: {
                                            if (text.startsWith("#") && text.length === 7) {
                                                WallpaperService.sourceColor = text
                                                var colors = Object.assign({}, root.activePaletteColors)
                                                colors.primary = text
                                                colors.accent = text
                                                root.activePaletteColors = colors
                                                if (WallpaperService.isPreviewing) {
                                                    WallpaperService.applyColorsLive(colors)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Custom color edits are ephemeral and will not overwrite defaults unless applied"
                            font.pixelSize: 9
                            color: Theme.textMuted
                        }
                    }
                }

                // Action Buttons Row: Preview (5s) & Apply
                Item {
                    width: parent.width
                    height: 40

                    Row {
                        anchors.centerIn: parent
                        spacing: 16

                        // Preview 5s Button
                        Rectangle {
                            id: previewButton
                            width: 140
                            height: 36
                            radius: 18
                            color: WallpaperService.isPreviewing
                                ? Theme.accent
                                : (previewHover.hovered ? Theme.surfaceVariant : Theme.surface)
                            border.width: 1
                            border.color: WallpaperService.isPreviewing ? Theme.accent : Theme.border

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: WallpaperService.isPreviewing ? "󰅐" : "󰍉"
                                    font.family: Theme.iconFont
                                    font.pixelSize: 13
                                    color: WallpaperService.isPreviewing ? Theme.background : Theme.textPrimary
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: WallpaperService.isPreviewing
                                        ? "Reverting in " + WallpaperService.previewSecondsLeft + "s"
                                        : "Preview (5s)"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: WallpaperService.isPreviewing ? Theme.background : Theme.textPrimary
                                }
                            }

                            HoverHandler { id: previewHover; cursorShape: Qt.PointingHandCursor }

                            TapHandler {
                                onTapped: {
                                    if (WallpaperService.isPreviewing) {
                                        WallpaperService.cancelPreview()
                                    } else {
                                        WallpaperService.startPreview(
                                            root.activeWallpaperPath,
                                            root.activePaletteColors
                                        )
                                    }
                                }
                            }
                        }

                        // Apply Button
                        Rectangle {
                            id: applyButton
                            width: 140
                            height: 36
                            radius: 18
                            color: applyHover.hovered ? Qt.lighter(Theme.accent, 1.15) : Theme.accent

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰄬"
                                    font.family: Theme.iconFont
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.background
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Apply"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.background
                                }
                            }

                            HoverHandler { id: applyHover; cursorShape: Qt.PointingHandCursor }

                            TapHandler {
                                onTapped: {
                                    WallpaperService.commitPreview(root.activeWallpaperPath)
                                    IslandController.reset()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Keyboard navigation & ESC handler
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            if (WallpaperService.isPreviewing) {
                WallpaperService.cancelPreview()
                event.accepted = true
                return
            }
            if (root.activeWallpaperPath.length > 0) {
                root.activeWallpaperPath = ""
                event.accepted = true
                return
            }
            if (root.showSettings) {
                root.showSettings = false
                event.accepted = true
                return
            }
            IslandController.reset()
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.activeWallpaperPath.length > 0) {
                WallpaperService.commitPreview(root.activeWallpaperPath)
                IslandController.reset()
                event.accepted = true
            }
        }
    }
}
