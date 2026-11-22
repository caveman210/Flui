import QtQuick
import QtQuick.Layouts

import "../../core"
import "../../styles"
import "../../services/display"
import "../../island"
import "../../config"
import "../../components/common"

// Clean Night Light settings: Schedule times & Temperature only (Curve removed to plugin)
FocusScope {
    id: root
    implicitWidth: 380
    implicitHeight: layout.implicitHeight + 36
    focus: true

    Component.onCompleted: forceActiveFocus()

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            IslandController.openSettings()
            event.accepted = true
        }
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        // Top Navigation Header
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
                TapHandler { onTapped: IslandController.openSettings() }
            }

            Text {
                text: "Night Light"
                color: Theme.textPrimary
                font.pixelSize: 18
                font.bold: true
                Layout.fillWidth: true
            }

            // Quick Status Pill
            Rectangle {
                implicitWidth: statusRow.implicitWidth + 14
                implicitHeight: 24
                radius: 12
                color: NightLightService.enabled ? Theme.accent : Theme.surface
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: NightLightService.enabled ? "󰔎" : "󰃞"
                        color: NightLightService.enabled ? Theme.background : Theme.textMuted
                        font.family: Theme.iconFont
                        font.pixelSize: 12
                    }

                    Text {
                        text: NightLightService.enabled ? (NightLightService.currentTemp + "K") : "Off"
                        color: NightLightService.enabled ? Theme.background : Theme.textSecondary
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }
        }

        // Target Color Temperature Section
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: tempLayout.implicitHeight + 24
            radius: 12
            color: Theme.surface
            border.width: 1
            border.color: Theme.border

            ColumnLayout {
                id: tempLayout
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Target Temperature"
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: ConfigStore.nightLightTargetTemp + "K"
                        color: Theme.accent
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                // Preset temperature chips
                RowLayout {
                    spacing: 6
                    Layout.fillWidth: true

                    Repeater {
                        model: [
                            { label: "3500K", val: 3500 },
                            { label: "4000K", val: 4000 },
                            { label: "4500K", val: 4500 },
                            { label: "5000K", val: 5000 },
                            { label: "5500K", val: 5500 }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool isSelected: ConfigStore.nightLightTargetTemp === modelData.val
                            Layout.fillWidth: true
                            implicitHeight: 26
                            radius: 13
                            color: isSelected ? Theme.accent : (pHover.hovered ? Theme.buttonHover : Theme.surfaceVariant)

                            HoverHandler { id: pHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    ConfigStore.nightLightTargetTemp = modelData.val
                                    ConfigStore.save()
                                    NightLightService.checkSchedule()
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: isSelected ? Theme.background : Theme.textSecondary
                                font.pixelSize: 10
                                font.bold: isSelected
                            }
                        }
                    }
                }
            }
        }

        // Schedule Toggle Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: schedLayout.implicitHeight + 20
            radius: 12
            color: Theme.surface
            border.width: 1
            border.color: Theme.border

            ColumnLayout {
                id: schedLayout
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "󰥔"
                        font.family: Theme.iconFont
                        font.pixelSize: 16
                        color: Theme.accent
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "Automatic Schedule"
                            color: Theme.textPrimary
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Text {
                            text: ConfigStore.nightLightSchedule ? "Runs daily at scheduled hours" : "Manual control only"
                            color: Theme.textMuted
                            font.pixelSize: 10
                        }
                    }

                    Rectangle {
                        width: 38
                        height: 20
                        radius: 10
                        color: ConfigStore.nightLightSchedule ? Theme.accent : Theme.buttonBackground
                        border.color: Theme.border
                        border.width: 1

                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            anchors.verticalCenter: parent.verticalCenter
                            x: ConfigStore.nightLightSchedule ? parent.width - width - 3 : 3
                            color: ConfigStore.nightLightSchedule ? Theme.background : Theme.textPrimary
                            Behavior on x {
                                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                            }
                        }

                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                ConfigStore.nightLightSchedule = !ConfigStore.nightLightSchedule
                                ConfigStore.save()
                                NightLightService.checkSchedule()
                            }
                        }
                    }
                }

                // Start & End Time Inputs
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: ConfigStore.nightLightSchedule

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: "Start (Evening)"
                            color: Theme.textSecondary
                            font.pixelSize: 10
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: 6
                            color: Theme.surfaceVariant
                            border.color: Theme.border
                            border.width: 1

                            TextInput {
                                id: startInput
                                anchors.fill: parent
                                anchors.margins: 6
                                text: ConfigStore.nightLightStart
                                color: Theme.textPrimary
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                onEditingFinished: {
                                    ConfigStore.nightLightStart = text.trim()
                                    ConfigStore.save()
                                    NightLightService.checkSchedule()
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: "End (Morning)"
                            color: Theme.textSecondary
                            font.pixelSize: 10
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: 6
                            color: Theme.surfaceVariant
                            border.color: Theme.border
                            border.width: 1

                            TextInput {
                                id: endInput
                                anchors.fill: parent
                                anchors.margins: 6
                                text: ConfigStore.nightLightEnd
                                color: Theme.textPrimary
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                onEditingFinished: {
                                    ConfigStore.nightLightEnd = text.trim()
                                    ConfigStore.save()
                                    NightLightService.checkSchedule()
                                }
                            }
                        }
                    }
                }
            }
        }

        // Extensibility Slot: Injected by plugins (e.g. nightlight-curve) when enabled
        ExtensionSlot {
            slotName: "nightlight.curve"
            Layout.fillWidth: true
        }
    }
}
