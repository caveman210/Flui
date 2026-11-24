import QtQuick
import QtQuick.Layouts

import "../../styles"
import "../../core"
import "../shared"
import "../../components/bar"
import "../../components/sections"
import "../../components/common"
import "../../services"
import "../../services/connectivity"
import "../../island"
import "../../config"

// Idle content of the bar layout: notification bell, extensibility slot info,
// clock center, control pill (with active VPN lock) + tray + power right.
Item {
    id: root

    implicitHeight: Theme.barHeight

    readonly property real weatherCenterX: leftArea.x + infoSlotContainer.x + infoSlotContainer.width / 2

    // Bar's left area: Notification bell, Plugin system (bar.info), and Media player
    RowLayout {
        id: leftArea
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16

        NotificationBell {
            Layout.alignment: Qt.AlignVCenter
        }

        // Extensibility Slot: bar.info (Weather, Quote, etc.) - ALWAYS visible in bar
        Item {
            id: infoSlotContainer
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: infoSlot.implicitWidth
            implicitHeight: infoSlot.implicitHeight
            width: implicitWidth
            height: implicitHeight

            SpaceHarness {
                id: barHarness
                totalWidth: 320
                isBar: true
            }

            ExtensionSlot {
                id: infoSlot
                slotName: "bar.info"
                orientation: "horizontal"
                cycle: true
                spaceHarness: barHarness
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: function(event) {
                    event.accepted = true
                    if (infoSlot.currentPluginId === "quote") {
                        IslandController.openQuote()
                    } else {
                        IslandController.openWeather()
                    }
                }
            }
        }

        // Media Line: shown alongside when media is active
        RowLayout {
            id: mediaRow
            visible: MediaService.hasPlayer
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            Text {
                text: "♪"
                color: Theme.accent
                font.pixelSize: 15
                Layout.alignment: Qt.AlignVCenter
            }

            ScrollingText {
                text: MediaService.title || "No Title"
                maxWidth: 200
                fontSize: 12
                hovered: mediaHover.hovered
                Layout.alignment: Qt.AlignVCenter
            }

            HoverHandler {
                id: mediaHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: function(event) {
                    event.accepted = true
                    IslandController.openMediaFromLeftSection()
                }
            }
        }
    }

    // Center Section: Clock — clicking drops the Calendar
    Item {
        id: centerSection
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: centerRow.implicitWidth + 24
        implicitHeight: Theme.barHeight

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 10
            color: centerHover.hovered || IslandState.mode === IslandState.calendarMode
                ? Theme.surface
                : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationFast
                }
            }
        }

        HoverHandler {
            id: centerHover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            gesturePolicy: TapHandler.ReleaseWithinBounds

            onTapped: function(event) {
                event.accepted = true

                if (IslandState.mode === IslandState.calendarMode)
                    IslandController.reset()
                else
                    IslandController.openCalendar()
            }
        }

        RowLayout {
            id: centerRow
            anchors.centerIn: parent
            spacing: 10

            Item {
                id: centerSlot
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: clock.implicitWidth
                implicitHeight: Theme.barHeight

                ClockView {
                    id: clock
                    anchors.centerIn: parent
                }
            }
        }
    }

    RightSection {
        id: rightSection
        showStatusChip: false
        showControlPill: true
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
    }
}
