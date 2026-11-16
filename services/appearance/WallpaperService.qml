pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import ".."
import "../../core"
import "../../config"
import "../../styles"

Singleton {
    id: root

    property ListModel wallpapers: ListModel {}
    property var _scannedPaths: []

    // Current active wallpaper path
    property string currentWallpaper: ConfigStore.currentWallpaper

    // Saved state for ephemeral preview rollback
    property string _savedWallpaper: ""
    property string _savedSourceColor: ""
    property string _savedMode: "dark"
    property string _savedScheme: "scheme-tonal-spot"
    property string _savedContrast: "0"
    property var _savedThemeSnapshot: ({})
    property bool isPreviewing: false
    property int previewSecondsLeft: 5

    // Extracted dominant colors from wallpaper
    property var extractedColors: []

    // Color extraction process via magick
    Process {
        id: colorExtractorProcess
        command: []
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                var hex = line.trim()
                if (hex.startsWith("#") && hex.length === 7) {
                    if (root.extractedColors.indexOf(hex) === -1) {
                        var arr = root.extractedColors.slice()
                        arr.push(hex)
                        root.extractedColors = arr
                    }
                }
            }
        }
    }

    function extractDominantColors(path) {
        if (!path) return
        extractedColors = []
        colorExtractorProcess.command = [
            "bash", "-c",
            "magick \"" + path + "\" -resize 100x100 +dither -colors 8 -unique-colors txt:- 2>/dev/null | grep -o '#[0-9a-fA-F]\\{6\\}' || true"
        ]
        colorExtractorProcess.running = true
    }

    Process {
        id: scanProcess
        command: [
            "bash",
            "-c",
            "WP_DIR=\"" + (ConfigStore.wallpaperDir || "").replace("~", Quickshell.env("HOME")) + "\"; \
            if [ -z \"$WP_DIR\" ] || [ ! -d \"$WP_DIR\" ]; then \
                WP_DIR=\"${XDG_PICTURES_DIR:-$HOME/Pictures}/Wallpapers\"; \
                [ ! -d \"$WP_DIR\" ] && WP_DIR=\"$HOME/Wallpapers\"; \
                [ ! -d \"$WP_DIR\" ] && WP_DIR=\"${XDG_PICTURES_DIR:-$HOME/Pictures}\"; \
            fi; \
            find -L \"$WP_DIR\" -maxdepth 1 -type f \\( \
                -iname '*.jpg'  -o \
                -iname '*.jpeg' -o \
                -iname '*.png'  -o \
                -iname '*.webp' -o \
                -iname '*.gif' \
            \\) 2>/dev/null | sort"
        ]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: function(line) {
                let path = line.trim()
                if (path.length === 0)
                    return
                root._scannedPaths.push(path)
            }
        }

        onStarted: {
            root._scannedPaths = []
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0)
                return

            let changed = root.wallpapers.count !== root._scannedPaths.length
            if (!changed) {
                for (let i = 0; i < root._scannedPaths.length; i++) {
                    if (root.wallpapers.get(i).path !== root._scannedPaths[i]) {
                        changed = true
                        break
                    }
                }
            }

            if (changed) {
                root.wallpapers.clear()
                for (let i = 0; i < root._scannedPaths.length; i++) {
                    root.wallpapers.append({
                        path: root._scannedPaths[i]
                    })
                }
            }
        }
    }

    // Query active wallpaper if none saved in ConfigStore
    Process {
        id: queryProcess
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.indexOf("currently displaying: image: ") !== -1) {
                    var parts = text.split("currently displaying: image: ")
                    if (parts.length > 1) {
                        var foundPath = parts[1].trim()
                        if (foundPath.length > 0) {
                            if (!root.currentWallpaper) {
                                root.currentWallpaper = foundPath
                                ConfigStore.currentWallpaper = foundPath
                                ConfigStore.save()
                            }
                        }
                    }
                }
            }
        }
    }

    property string _pendingPath: ""

    Process {
        id: applyProcess

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                console.warn("WallpaperService: awww failed with code", exitCode)
                return
            }

            if (!root.isPreviewing) {
                StatusManager.show({
                    mode: "wallpaper",
                    icon: "󰸉",
                    title: String(root._pendingPath).split("/").pop(),
                    statusWidth: 240,
                    statusHeight: 33
                })
            }
        }
    }

    property string matugenMode: "dark" // dark | light
    property string matugenScheme: "scheme-tonal-spot"
    property string matugenContrast: "0"
    property string sourceColor: ""
    property ListModel palettes: ListModel {}

    Process {
        id: paletteProcess
        command: []

        stdout: StdioCollector {
            onStreamFinished: {
                root.palettes.clear()
                var parsed
                try {
                    parsed = JSON.parse(text)
                } catch (err) {
                    console.warn("WallpaperService: bad palette JSON:", err)
                    return
                }

                if (!Array.isArray(parsed))
                    return

                for (var i = 0; i < parsed.length; i++) {
                    var p = parsed[i]
                    root.palettes.append({
                        background: p.background,
                        surface: p.surface,
                        surfaceVariant: p.surfaceVariant,
                        primary: p.primary,
                        secondary: p.secondary,
                        tertiary: p.tertiary,
                        text: p.text,
                        error: p.error,
                        source: p.source,
                        mode: p.mode,
                        scheme: p.scheme
                    })
                }
            }
        }
    }

    function extractPalette(path) {
        if (!path)
            return

        palettes.clear()
        paletteProcess.command = [
            "matugen-preview",
            path
        ]
        paletteProcess.running = true
        extractDominantColors(path)
    }

    Process {
        id: matugenProcess

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                console.warn("WallpaperService: matugen failed with code", exitCode)
                return
            }
            ThemeService.reloadMatugenFile()
        }
    }

    // Apply colors live to Theme singleton in-memory
    function applyColorsLive(colorsObj) {
        for (var k in colorsObj) {
            if (Theme[k] !== undefined) {
                Theme[k] = colorsObj[k]
            }
        }
    }

    // Snapshot in-memory theme colors
    function snapshotCurrentTheme() {
        var keys = [
            "background", "surface", "surfaceVariant", "card",
            "textPrimary", "textSecondary", "textMuted",
            "icon", "iconActive", "iconDisabled",
            "accent", "accentHover", "accentPressed",
            "border", "borderHover", "borderSelected", "borderSubtle",
            "buttonBackground", "buttonHover", "buttonPressed", "buttonSelected", "buttonText",
            "danger", "dangerHover", "warning", "success",
            "sliderBackground", "sliderFill", "inputBackground", "inputBorder",
            "notificationBackground", "notificationUnread", "progress", "progressBackground",
            "wallpaperOverlay", "wallpaperSelection"
        ]
        var snap = {}
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i]
            if (Theme[key] !== undefined) {
                snap[key] = String(Theme[key])
            }
        }
        return snap
    }

    function runWallpaperOnly(path, transition, duration) {
        _pendingPath = path
        var transType = transition || ConfigStore.wallpaperTransitionType || "grow"
        var transDur = String(duration || ConfigStore.wallpaperTransitionDuration || 2)

        applyProcess.command = [
            "awww",
            "img",
            path,
            "--transition-type", transType,
            "--transition-duration", transDur,
            "--transition-fps", "60"
        ]
        applyProcess.running = true
    }

    function apply(path) {
        if (isPreviewing) {
            previewTimer.stop()
            isPreviewing = false
        }

        currentWallpaper = path
        ConfigStore.currentWallpaper = path
        ConfigStore.save()

        runWallpaperOnly(path, ConfigStore.wallpaperTransitionType, ConfigStore.wallpaperTransitionDuration)

        // Only run matugen if enabled by the user in settings
        if (!ConfigStore.matugenEnabled) {
            return
        }

        var themeCommand = [
            "matugen-theme"
        ]

        if (root.sourceColor && root.sourceColor.length > 0) {
            themeCommand.push("color", root.sourceColor)
        } else {
            themeCommand.push("image", path)
        }

        themeCommand.push(
            "--mode", root.matugenMode,
            "--type", root.matugenScheme,
            "--contrast", root.matugenContrast
        )

        matugenProcess.command = themeCommand
        matugenProcess.running = true
    }

    // 5-Second Ephemeral Preview Functionality
    Timer {
        id: previewTimer
        interval: 1000
        repeat: true
        onTriggered: {
            root.previewSecondsLeft--
            if (root.previewSecondsLeft <= 0) {
                root.cancelPreview()
            }
        }
    }

    function startPreview(path, previewColors) {
        if (!isPreviewing) {
            _savedWallpaper = currentWallpaper
            _savedSourceColor = root.sourceColor
            _savedMode = root.matugenMode
            _savedScheme = root.matugenScheme
            _savedContrast = root.matugenContrast
            _savedThemeSnapshot = snapshotCurrentTheme()
        }

        isPreviewing = true
        previewSecondsLeft = 5
        previewTimer.restart()

        // Apply wallpaper preview with fast transition
        runWallpaperOnly(path, "fade", 1)

        // Ephemeral theme preview: apply in-memory only without rewriting disk config
        if (previewColors) {
            applyColorsLive(previewColors)
        }
    }

    function cancelPreview() {
        if (!isPreviewing)
            return

        previewTimer.stop()
        isPreviewing = false

        // Revert in-memory theme snapshot immediately
        if (_savedThemeSnapshot) {
            applyColorsLive(_savedThemeSnapshot)
        }

        // Revert wallpaper back to original
        if (_savedWallpaper && _savedWallpaper.length > 0) {
            root.sourceColor = _savedSourceColor
            root.matugenMode = _savedMode
            root.matugenScheme = _savedScheme
            root.matugenContrast = _savedContrast
            runWallpaperOnly(_savedWallpaper, "fade", 1)
        }
    }

    function commitPreview(path) {
        if (isPreviewing) {
            previewTimer.stop()
            isPreviewing = false
        }
        apply(path)
    }

    // Shuffle System
    Timer {
        id: shuffleTimer
        running: ConfigStore.wallpaperShuffle && root.wallpapers.count > 1
        repeat: true
        interval: root.getIntervalMs(ConfigStore.wallpaperShuffleInterval)
        onTriggered: {
            root.shuffleNext()
        }
    }

    function getIntervalMs(str) {
        if (!str) return 3 * 3600 * 1000
        if (str.endsWith("m")) {
            var m = parseInt(str) || 15
            return m * 60 * 1000
        }
        if (str.endsWith("h")) {
            var h = parseInt(str) || 3
            return h * 3600 * 1000
        }
        if (str.endsWith("d")) {
            var d = parseInt(str) || 1
            return d * 24 * 3600 * 1000
        }
        return 3 * 3600 * 1000
    }

    function shuffleNext() {
        if (root.wallpapers.count <= 1) return
        var nextIdx = Math.floor(Math.random() * root.wallpapers.count)
        var item = root.wallpapers.get(nextIdx)
        if (item && item.path) {
            if (item.path === currentWallpaper && root.wallpapers.count > 1) {
                nextIdx = (nextIdx + 1) % root.wallpapers.count
                item = root.wallpapers.get(nextIdx)
            }
            if (item && item.path) {
                root.sourceColor = ""
                apply(item.path)
            }
        }
    }

    function reload() {
        scanProcess.running = true
        queryProcess.running = true
    }

    Component.onCompleted: {
        reload()
    }
}
