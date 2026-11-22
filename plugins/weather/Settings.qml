import QtQuick
import QtQuick.Layouts

import "../../core"
import "../../styles"
import "."

// Inline Plugin Settings for Weather & Forecast Plugin
ColumnLayout {
    id: root
    spacing: 14

    // Provider Selection Container
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: provCol.implicitHeight + 24
        radius: 12
        color: Theme.surface
        border.width: 1
        border.color: Theme.border

        ColumnLayout {
            id: provCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Column {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "Weather Provider"; color: Theme.textPrimary; font.pixelSize: 13; font.bold: true }
                Text { text: "Free aggregators and realtime sources"; color: Theme.textMuted; font.pixelSize: 10 }
            }

            // Grid of 4 Providers
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                Repeater {
                    model: WeatherService.providers

                    Rectangle {
                        id: provCard
                        Layout.fillWidth: true
                        height: 54
                        radius: 10
                        readonly property bool isSelected: (WeatherService.currentProvider || "openmeteo") === modelData.id
                        color: isSelected ? Theme.accent : (cardHover.hovered ? Theme.buttonHover : Theme.background)
                        border.width: 1
                        border.color: isSelected ? Theme.accent : Theme.border

                        Behavior on color {
                            ColorAnimation { duration: Theme.animationFast }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text {
                                text: modelData.icon
                                font.family: Theme.iconFont
                                font.pixelSize: 20
                                color: provCard.isSelected ? Theme.background : Theme.accent
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: modelData.name
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: provCard.isSelected ? Theme.background : Theme.textPrimary
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.desc
                                    font.pixelSize: 9
                                    color: provCard.isSelected ? Theme.background : Theme.textMuted
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        HoverHandler { id: cardHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                WeatherService.setProvider(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }

    // Location Override & Polling Interval Card
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: locCol.implicitHeight + 24
        radius: 12
        color: Theme.surface
        border.width: 1
        border.color: Theme.border

        ColumnLayout {
            id: locCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            // Location Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text { text: "󰍎"; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.accent }

                Column {
                    Layout.fillWidth: true
                    spacing: 1
                    Text { text: "Location Override"; color: Theme.textPrimary; font.pixelSize: 13; font.bold: true }
                    Text { text: "Empty = auto-detect via IP address"; color: Theme.textMuted; font.pixelSize: 10 }
                }

                Rectangle {
                    width: 150
                    height: 30
                    radius: 6
                    color: Theme.background
                    border.width: 1
                    border.color: Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4

                        TextInput {
                            id: locationInput
                            Layout.fillWidth: true
                            text: WeatherService.locationOverride
                            color: Theme.textPrimary
                            font.pixelSize: 11
                            selectByMouse: true
                            clip: true

                            Text {
                                text: "Auto (IP)"
                                color: Theme.textMuted
                                font.pixelSize: 11
                                visible: locationInput.text === "" && !locationInput.activeFocus
                            }

                            onEditingFinished: {
                                WeatherService.setLocation(text)
                            }
                        }

                        Text {
                            text: "✕"
                            visible: locationInput.text !== ""
                            color: Theme.textMuted
                            font.pixelSize: 9
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    locationInput.text = ""
                                    WeatherService.setLocation("")
                                }
                            }
                        }
                    }
                }
            }

            // Divider line
            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            // Polling Interval Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text { text: "󰥔"; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.accent }

                Column {
                    Layout.fillWidth: true
                    spacing: 1
                    Text { text: "Realtime Polling Interval"; color: Theme.textPrimary; font.pixelSize: 13; font.bold: true }
                    Text { text: "How frequently weather refreshes in the background"; color: Theme.textMuted; font.pixelSize: 10 }
                }

                RowLayout {
                    spacing: 6

                    Rectangle {
                        width: 26
                        height: 24
                        radius: 6
                        color: Theme.buttonBackground
                        border.width: 1
                        border.color: Theme.border

                        Text {
                            anchors.centerIn: parent
                            text: "-"
                            color: Theme.buttonText
                            font.pixelSize: 13
                            font.bold: true
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                if (WeatherService.pollIntervalMins > 1) {
                                    WeatherService.setPollInterval(WeatherService.pollIntervalMins - 1)
                                }
                            }
                        }
                    }

                    Text {
                        text: WeatherService.pollIntervalMins + " min"
                        color: Theme.textPrimary
                        font.bold: true
                        font.pixelSize: 12
                    }

                    Rectangle {
                        width: 26
                        height: 24
                        radius: 6
                        color: Theme.buttonBackground
                        border.width: 1
                        border.color: Theme.border

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color: Theme.buttonText
                            font.pixelSize: 13
                            font.bold: true
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                if (WeatherService.pollIntervalMins < 60) {
                                    WeatherService.setPollInterval(WeatherService.pollIntervalMins + 5)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Bottom Action: View Live Weather Panel
    Rectangle {
        Layout.fillWidth: true
        height: 38
        radius: 10
        color: viewHover.hovered ? Theme.buttonHover : Theme.surface
        border.width: 1
        border.color: Theme.border

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "󰖐"
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: 14
            }

            Text {
                text: "View Live Weather Forecast"
                color: Theme.textPrimary
                font.pixelSize: 12
                font.bold: true
            }
        }

        HoverHandler { id: viewHover; cursorShape: Qt.PointingHandCursor }
        TapHandler {
            onTapped: {
                if (root.parent && root.parent.parent && typeof root.parent.parent.showSettings !== "undefined") {
                    root.parent.parent.showSettings = false
                }
                IslandController.openPluginView("weather")
            }
        }
    }
}
