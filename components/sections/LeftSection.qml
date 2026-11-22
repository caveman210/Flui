import QtQuick
import QtQuick.Layouts

import "../../styles"
import "../../core"
import "../../island"
import "../../components/bar"
import "../../components/common"
import "../../services"
import "../../config"

Item {
    id: root
    property bool interactive: true
    readonly property bool hasMedia: MediaService.hasPlayer
    implicitWidth: row.implicitWidth
    implicitHeight: Math.max(nowPlaying.implicitHeight, privacy.implicitHeight, 33)

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.leftMargin: Theme.sectionGap
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        NotificationBell {
            id: notifBell
            visible: !IslandState.layoutIsBar && !root.hasMedia
            Layout.alignment: Qt.AlignVCenter
            HoverHandler {
                id: bellHover
            }
        }

        PrivacyCluster {
            id: privacy
            visible: !IslandState.layoutIsBar && privacy.anyActive && !root.hasMedia
            Layout.alignment: Qt.AlignVCenter
        }

        NowPlayingWidget {
            id: nowPlaying
            visible: root.hasMedia
            cavaOnly: !IslandState.layoutIsBar
            hovered: sectionHover.hovered
            Layout.alignment: Qt.AlignVCenter
        }

        // Extensibility Slot: bar.info (Weather, Motivation, etc.)
        ExtensionSlot {
            id: infoSlot
            slotName: "bar.info"
            orientation: "horizontal"
            cycle: true
            visible: !root.hasMedia
            Layout.alignment: Qt.AlignVCenter
        }
    }

    HoverHandler {
        id: sectionHover
        enabled: root.interactive && (!notifBell.visible || !bellHover.hovered)
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: root.interactive && (!notifBell.visible || !bellHover.hovered)
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds

        onTapped: function(event) {
            event.accepted = true

            if (root.hasMedia) {
                IslandController.openMediaFromLeftSection()
            } else if (infoSlot.currentPluginId === "quote") {
                IslandController.openQuote()
            } else {
                IslandController.openWeather()
            }
        }
    }
}
