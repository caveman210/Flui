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

    // Dynamic Space Harness for the left cluster:
    // Coordinates total space and exact allotments for notifications, plugins, and privacy.
    SpaceHarness {
        id: leftHarness
        totalWidth: root.width > 0 ? (root.width - Theme.sectionGap) : 200
        isBar: IslandState.layoutIsBar || ConfigStore.layout === 2
        privacyCount: privacy.activeCount
        privacyActive: privacy.anyActive
    }

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
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
            onVisibleChanged: {
                if (visible) leftHarness.requestSpace("notifications", implicitWidth + row.spacing)
                else leftHarness.releaseSpace("notifications")
            }
            Component.onCompleted: {
                if (visible) leftHarness.requestSpace("notifications", implicitWidth + row.spacing)
            }
        }

        NowPlayingWidget {
            id: nowPlaying
            visible: root.hasMedia
            cavaOnly: !IslandState.layoutIsBar
            hovered: sectionHover.hovered
            Layout.alignment: Qt.AlignVCenter
        }

        // Extensibility Slot: bar.info (Weather, Motivation, etc.)
        // Dynamically occupies the maximal remaining space allocated by the harness
        ExtensionSlot {
            id: infoSlot
            slotName: "bar.info"
            orientation: "horizontal"
            cycle: true
            visible: !root.hasMedia
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            spaceHarness: leftHarness
        }

        PrivacyCluster {
            id: privacy
            visible: !IslandState.layoutIsBar && privacy.anyActive && !root.hasMedia
            Layout.alignment: Qt.AlignVCenter
            onVisibleChanged: {
                if (visible) leftHarness.requestSpace("privacy", implicitWidth + row.spacing)
                else leftHarness.releaseSpace("privacy")
            }
            onImplicitWidthChanged: {
                if (visible) leftHarness.requestSpace("privacy", implicitWidth + row.spacing)
            }
            Component.onCompleted: {
                if (visible) leftHarness.requestSpace("privacy", implicitWidth + row.spacing)
            }
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
