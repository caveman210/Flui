import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../config"
import "../../services"
import "."

Item {
    id: root

    property var slotHarness: null
    property real availableWidth: slotHarness ? slotHarness.availableWidth : -1

    readonly property bool isBar: ConfigStore.layout === 2 || (slotHarness && slotHarness.isBar)

    // Privacy indicators count for notch/pill collision avoidance (bar layout is completely unaffected)
    readonly property int privacyCount: slotHarness ? slotHarness.privacyCount : (!isBar
        ? ((PrivacyService.micActive ? 1 : 0) + (PrivacyService.cameraActive ? 1 : 0) + (PrivacyService.screenSharingActive ? 1 : 0))
        : 0)

    implicitHeight: isBar ? 28 : 33
    implicitWidth: isBar ? barRow.implicitWidth : notchRow.implicitWidth
    width: implicitWidth
    height: implicitHeight

    // BAR LAYOUT: Single row (15px icon, 12px bold temp + full city name)
    RowLayout {
        id: barRow
        visible: root.isBar
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        Text {
            text: WeatherService.icon
            color: Theme.accent
            font.family: Theme.iconFont
            font.pixelSize: 15
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: WeatherService.temp + (WeatherService.city ? " " + WeatherService.city : "")
            color: Theme.textPrimary
            font.pixelSize: 12
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
            Layout.maximumWidth: 320
        }
    }

    // PILL / NOTCH LAYOUT: Two-line stacked (18px icon, 14px bold temp, 11px lighter city)
    RowLayout {
        id: notchRow
        visible: !root.isBar
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Text {
            text: WeatherService.icon
            color: Theme.accent
            font.family: Theme.iconFont
            font.pixelSize: 18
            Layout.alignment: Qt.AlignVCenter
        }

        Column {
            id: notchCol
            spacing: 1
            Layout.alignment: Qt.AlignVCenter

            // Top: Degrees in larger bold text
            Text {
                id: tempText
                text: WeatherService.temp
                color: Theme.textPrimary
                font.pixelSize: 14
                font.bold: true
            }

            // Bottom: City in lighter smaller text
            Text {
                id: cityText
                visible: WeatherService.city !== ""
                text: WeatherService.city
                color: Theme.textSecondary
                font.pixelSize: 11
                elide: Text.ElideRight
                width: root.availableWidth > 0 ? Math.min(implicitWidth, Math.max(30, root.availableWidth - 26)) : implicitWidth
            }
        }
    }
}
