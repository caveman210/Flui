pragma Singleton

import QtQuick

// =========================================================
// DEFAULT THEME (Muted, warm neutral dynamic island fallback)
// Relaxed dark obsidian aesthetic: soft zinc/slate neutrals,
// subtle warm borders, low eye-strain accents.
// ONLY active if Matugen is not available.
// =========================================================

QtObject {
    // =========================================================
    // COLORS
    // =========================================================

    // Backgrounds
    property color background: "#09090B"
    property color surface: "#141416"
    property color surfaceVariant: "#1E1E22"
    property color card: "#18181B"

    // Overlays
    property color overlayLight: "#00000022"
    property color overlayMedium: "#00000044"
    property color overlayStrong: "#00000066"

    // Text
    property color textPrimary: "#F4F4F5"
    property color textSecondary: "#A1A1AA"
    property color textMuted: "#71717A"

    // Icons
    property color icon: "#A1A1AA"
    property color iconActive: "#F4F4F5"
    property color iconDisabled: "#52525B"

    // Accent (Soft neutral silver/slate)
    property color accent: "#E4E4E7"
    property color accentHover: "#FFFFFF"
    property color accentPressed: "#D4D4D8"

    // Borders
    property color border: "#27272A"
    property color borderHover: "#3F3F46"
    property color borderSelected: accent
    property color borderSubtle: "#FFFFFF12"

    // Buttons
    property color buttonBackground: "#18181B"
    property color buttonHover: "#27272A"
    property color buttonPressed: "#3F3F46"
    property color buttonSelected: accent
    property color buttonText: textPrimary
    property color controlButtonHover: "#27272A"

    // Status / semantic colors (Calm, desaturated tones)
    property color danger: "#F87171"
    property color dangerHover: "#EF4444"
    property color warning: "#FBBF24"
    property color success: "#4ADE80"

    // Inputs / sliders
    property color sliderBackground: "#27272A"
    property color sliderFill: accent
    property color inputBackground: "#141416"
    property color inputBorder: border

    // Notifications
    property color notificationBackground: card
    property color notificationUnread: surfaceVariant

    // Media
    property color progress: accent
    property color progressBackground: "#27272A"

    // Wallpaper selector
    property color wallpaperOverlay: overlayStrong
    property color wallpaperSelection: accent

    // Power menu
    property color powerDanger: danger
    property color powerWarning: warning

    // =========================================================
    // TYPOGRAPHY
    // =========================================================

    property string iconFont: "JetBrainsMono Nerd Font"
    readonly property string iconFontMono: "JetBrainsMono Nerd Font Mono"

    // =========================================================
    // LAYOUT & SIZING
    // =========================================================

    readonly property int outerPadding: 16
    readonly property int capsulePadding: 14
    readonly property int sectionGap: 0
    readonly property int clockSpacing: 2

    // Island
    readonly property int capsuleRadius: 23
    readonly property int leftSectionWidth: 130
    readonly property int rightSectionWidth: 132

    // Bar layout
    readonly property int barMargin: 8
    readonly property int barSideMargin: 28
    readonly property int barHeight: 33

    // Status overlays
    readonly property int statusDefaultWidth: 160
    readonly property int statusDefaultHeight: 33
    readonly property int statusWorkspaceWidth: 180
    readonly property int statusKeyboardWidth: 160
    readonly property int statusVolumeWidth: 280
    readonly property int statusBrightnessWidth: 280
    readonly property int statusNotificationWidth: 280
    readonly property int statusDeviceMaxWidth: 460

    // =========================================================
    // RADIUS
    // =========================================================

    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 12
    readonly property int radiusLarge: 16

    // =========================================================
    // ANIMATION
    // =========================================================

    readonly property int animationFast: 180
    readonly property int animationNormal: 300
    readonly property int animationSlow: 500
    readonly property var animationHorizontal: Easing.OutBack
    readonly property var animationVertical: Easing.OutCubic
}
