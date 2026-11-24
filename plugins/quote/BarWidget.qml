import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../config"
import "../../components/sections"
import "../../services"
import "."

RowLayout {
    id: root

    property var slotHarness: null
    readonly property real availableWidth: slotHarness ? slotHarness.remainingWidth : -1
    readonly property int privacyCount: slotHarness ? slotHarness.privacyCount : (!isBar
        ? ((PrivacyService.micActive ? 1 : 0) + (PrivacyService.cameraActive ? 1 : 0) + (PrivacyService.screenSharingActive ? 1 : 0))
        : 0)

    readonly property bool isBar: ConfigStore.layout === 2 || (slotHarness && slotHarness.isBar)
    readonly property real effectiveAvailableWidth: availableWidth >= 0 ? availableWidth : (isBar ? 260 : 160)

    // Dynamic space adaptation wrt space harness:
    // Quote consists of: quoteIcon ("✦") + spacing + quoteText (ScrollingText)
    readonly property int iconSpace: quoteIcon.implicitWidth + spacing
    readonly property int textAvailableWidth: Math.max(0, Math.floor(effectiveAvailableWidth - iconSpace))

    // Can show text if bar layout OR if remaining width fits at least a readable snippet (>= 28px)
    readonly property bool canShowText: isBar || textAvailableWidth >= 28

    // Entire widget visible if bar layout OR if space fits at least the quote icon
    visible: isBar || effectiveAvailableWidth >= quoteIcon.implicitWidth

    spacing: isBar ? 7 : (quoteText.visible ? 6 : 0)
    implicitHeight: isBar ? 28 : 33
    implicitWidth: !visible ? 0 : (quoteIcon.implicitWidth + (quoteText.visible ? (spacing + quoteText.implicitWidth) : 0))
    Layout.fillWidth: isBar || canShowText
    Layout.preferredWidth: implicitWidth

    HoverHandler {
        id: widgetHover
    }

    Text {
        id: quoteIcon
        text: "✦"
        color: Theme.accent
        font.pixelSize: 14
        Layout.alignment: Qt.AlignVCenter
    }

    ScrollingText {
        id: quoteText
        text: GreetingService.text
        maxWidth: root.isBar ? 260 : root.textAvailableWidth
        fontSize: 12
        hovered: widgetHover.hovered
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: visible ? implicitWidth : 0
        visible: root.canShowText
    }
}
