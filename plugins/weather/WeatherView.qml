import QtQuick
import QtQuick.Layouts

import Quickshell

import "../../core"
import "../../styles"
import "."

FocusScope {
    id: root
    property bool showSettings: false
    implicitWidth: showSettings ? 440 : 350
    implicitHeight: showSettings ? (settingsView.implicitHeight + 36) : (layout.implicitHeight + 36)

    Component.onCompleted: forceActiveFocus()

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            if (root.showSettings) {
                root.showSettings = false
            } else {
                IslandController.reset()
            }
            event.accepted = true
        }
    }

    readonly property bool hasError: WeatherService.errorMessage !== ""
    readonly property bool isLoading: WeatherService.loading

    // -----------------------------------------------------
    // LIVE FORECAST VIEW (Default)
    // -----------------------------------------------------
    ColumnLayout {
        id: layout
        visible: !root.showSettings
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // Top Header: Location, Condition Summary & Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "󰖐"
                color: root.hasError ? Theme.textMuted : Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: 18
                Layout.alignment: Qt.AlignVCenter

                Behavior on color {
                    ColorAnimation { duration: Theme.animationNormal }
                }
            }

            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true

                Text {
                    text: WeatherService.city !== "" ? WeatherService.city : "Local Weather"
                    color: Theme.textPrimary
                    font.pixelSize: 15
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: root.isLoading
                        ? "Updating weather data..."
                        : (root.hasError
                            ? "Connection failed • Tap to retry"
                            : (WeatherService.condition + (WeatherService.tempHigh !== "--" ? (" • H: " + WeatherService.tempHigh + "  L: " + WeatherService.tempLow) : "")))
                    color: root.hasError ? Theme.danger : (root.isLoading ? Theme.accent : Theme.textMuted)
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.fillWidth: true

                    Behavior on color {
                        ColorAnimation { duration: Theme.animationNormal }
                    }
                }
            }

            // Weather Settings Dropdown Button
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: setHover.hovered ? Theme.buttonHover : Theme.surface
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "󰒓"
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: 13
                }

                HoverHandler { id: setHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.showSettings = true }
            }

            // Refresh Button (gentle pulse while loading)
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: refHover.hovered ? Theme.buttonHover : Theme.surface
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: root.hasError ? Theme.textMuted : (root.isLoading ? Theme.accent : Theme.textSecondary)
                    font.family: Theme.iconFont
                    font.pixelSize: 13

                    SequentialAnimation on opacity {
                        running: root.isLoading
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
                    }

                    Behavior on color {
                        ColorAnimation { duration: Theme.animationNormal }
                    }
                }

                HoverHandler { id: refHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: WeatherService.refresh() }
            }
        }

        // Current Main Weather Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 96
            radius: 16
            color: Theme.surface
            border.width: 1
            border.color: Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                // Weather Icon: Pulses while loading, turns grey on error, accent color on success
                Item {
                    width: 52
                    height: 52
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        id: weatherIcon
                        anchors.centerIn: parent
                        text: WeatherService.icon
                        color: root.hasError ? Theme.textMuted : Theme.accent
                        font.family: Theme.iconFont
                        font.pixelSize: 48

                        SequentialAnimation on opacity {
                            running: root.isLoading
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
                        }

                        Behavior on color {
                            ColorAnimation { duration: Theme.animationNormal }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Layout.alignment: Qt.AlignVCenter

                    RowLayout {
                        spacing: 8

                        Text {
                            text: WeatherService.temp
                            color: root.hasError ? Theme.textMuted : Theme.textPrimary
                            font.pixelSize: 28
                            font.bold: true

                            Behavior on color {
                                ColorAnimation { duration: Theme.animationNormal }
                            }
                        }

                        // Feels like badge
                        Rectangle {
                            height: 20
                            implicitWidth: feelsText.implicitWidth + 12
                            radius: 10
                            color: Theme.buttonBackground
                            visible: WeatherService.feelsLike !== "--"

                            Text {
                                id: feelsText
                                anchors.centerIn: parent
                                text: "Feels like " + WeatherService.feelsLike
                                color: root.hasError ? Theme.textMuted : Theme.textSecondary
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }

                    Text {
                        text: root.hasError ? WeatherService.errorMessage : WeatherService.condition
                        color: root.hasError ? Theme.danger : Theme.textSecondary
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: WeatherService.lastUpdated ? ("Updated at " + WeatherService.lastUpdated) : ""
                        color: Theme.textMuted
                        font.pixelSize: 10
                        visible: WeatherService.lastUpdated !== "" && !root.hasError
                    }
                }
            }
        }

        // Secondary Metrics Grid: 4 Clean Informational Tiles
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            // 1. Humidity
            Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: 12
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Text { text: "󰖎"; font.family: Theme.iconFont; font.pixelSize: 18; color: Theme.accent }
                    ColumnLayout {
                        spacing: 1
                        Text { text: "Humidity"; color: Theme.textSecondary; font.pixelSize: 10 }
                        Text { text: WeatherService.humidity; color: Theme.textPrimary; font.bold: true; font.pixelSize: 13 }
                    }
                }
            }

            // 2. Wind Speed
            Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: 12
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Text { text: "󰖝"; font.family: Theme.iconFont; font.pixelSize: 18; color: Theme.accent }
                    ColumnLayout {
                        spacing: 1
                        Text { text: "Wind"; color: Theme.textSecondary; font.pixelSize: 10 }
                        Text { text: WeatherService.wind; color: Theme.textPrimary; font.bold: true; font.pixelSize: 13 }
                    }
                }
            }

            // 3. Air Pressure
            Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: 12
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Text { text: "󰥔"; font.family: Theme.iconFont; font.pixelSize: 18; color: Theme.accent }
                    ColumnLayout {
                        spacing: 1
                        Text { text: "Pressure"; color: Theme.textSecondary; font.pixelSize: 10 }
                        Text { text: WeatherService.pressure !== "--" ? WeatherService.pressure : "1013 hPa"; color: Theme.textPrimary; font.bold: true; font.pixelSize: 13 }
                    }
                }
            }

            // 4. UV Index / Precipitation
            Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: 12
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Text { text: "󰖙"; font.family: Theme.iconFont; font.pixelSize: 18; color: Theme.accent }
                    ColumnLayout {
                        spacing: 1
                        Text { text: "UV Index"; color: Theme.textSecondary; font.pixelSize: 10 }
                        Text {
                            text: WeatherService.uvIndex !== "--"
                                ? WeatherService.uvIndex
                                : (WeatherService.precipitation !== "--" ? WeatherService.precipitation : "Low")
                            color: Theme.textPrimary
                            font.bold: true
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }

    // -----------------------------------------------------
    // WEATHER SETTINGS SUBVIEW (Toggled via Gear Icon)
    // -----------------------------------------------------
    ColumnLayout {
        id: settingsView
        visible: root.showSettings
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        // Top Navigation Header (Back button to forecast)
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: backHover.hovered ? Theme.buttonHover : Theme.surface
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "󰁍"
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: 16
                }

                HoverHandler { id: backHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.showSettings = false }
            }

            Text {
                text: "Weather Settings"
                color: Theme.textPrimary
                font.bold: true
                font.pixelSize: 18
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }
        }

        Settings {
            Layout.fillWidth: true
        }
    }
}
