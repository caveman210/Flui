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

    readonly property real weatherCenterX: mediaSection.x + mediaSection.width / 2

    // Bar's left cluster: Notification bell only
    RowLayout {
        id: leftCluster
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        NotificationBell {
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Media Line OR Extensibility Info Slot (Weather, Motivation, etc.)
    Item {
        id: mediaSection
        anchors.left: leftCluster.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: MediaService.hasPlayer
            ? mediaRow.implicitWidth
            : infoSlot.implicitWidth
        implicitHeight: Theme.barHeight

        // Priority 1: When media is playing, show track
        RowLayout {
            id: mediaRow
            visible: MediaService.hasPlayer
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                text: "♪"
                color: Theme.textPrimary
                font.pixelSize: 16
                Layout.alignment: Qt.AlignVCenter
            }

            ScrollingText {
                text: MediaService.title || "No Title"
                maxWidth: 240
                fontSize: 13
                hovered: mediaHover.hovered
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Extensibility Slot: bar.info (Weather, Quote, etc.)
        ExtensionSlot {
            id: infoSlot
            slotName: "bar.info"
            orientation: "horizontal"
            cycle: true
            visible: !MediaService.hasPlayer
            anchors.verticalCenter: parent.verticalCenter
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

                if (MediaService.hasPlayer) {
                    IslandController.openMediaFromLeftSection()
                } else if (infoSlot.currentPluginId === "quote") {
                    IslandController.openQuote()
                } else {
                    IslandController.openWeather()
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
