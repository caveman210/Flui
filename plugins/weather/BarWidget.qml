import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../config"
import "."

Item {
    id: root

    readonly property bool isBar: ConfigStore.layout === 2

    implicitHeight: isBar ? 28 : 33
    implicitWidth: isBar ? barRow.implicitWidth : notchRow.implicitWidth

    // BAR LAYOUT: Single row (15px icon, 12px bold temp + full city name)
    RowLayout {
        id: barRow
        visible: root.isBar
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

    // PILL / NOTCH LAYOUT: Double row (18px icon, 13px bold temp, 11px city, no truncation unless true overflow)
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
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: WeatherService.temp
                color: Theme.textPrimary
                font.pixelSize: 13
                font.bold: true
            }

            Text {
                visible: WeatherService.city !== ""
                text: WeatherService.city
                color: Theme.textPrimary
                opacity: 0.7
                font.pixelSize: 11
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 240)
            }
        }
    }

}
