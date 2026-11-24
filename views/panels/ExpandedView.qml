import QtQuick
import QtQuick.Layouts

import "../../components/sections"
import "../../services"
import "../../styles"
import "../../core"

Item {
    id: root

    readonly property int totalWidth: 560
    readonly property int sideWidth: 212
    readonly property int gutter: 20
    readonly property bool hasMedia: MediaService.hasPlayer

    implicitWidth: totalWidth
    implicitHeight: 75

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 5

        // Left Section: Media info when playing, otherwise standard LeftSection
        Item {
            Layout.preferredWidth: root.sideWidth
            Layout.fillHeight: true

            // When no media is playing, keep standard LeftSection (weather/notifications/etc.)
            LeftSection {
                visible: !root.hasMedia
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }

            // When media is playing: Cava on left, Song Title & Artist on right (no thumbnail, clean padding)
            RowLayout {
                id: mediaRow
                visible: root.hasMedia
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Cava {
                    id: cavaModule
                    dotBaseline: true
                    Layout.alignment: Qt.AlignVCenter
                }

                Column {
                    id: textCol
                    spacing: 3
                    Layout.alignment: Qt.AlignVCenter

                    ScrollingText {
                        text: MediaService.title || "No Title"
                        maxWidth: 160
                        fontSize: 13
                        hovered: mediaHover.hovered
                    }

                    ScrollingText {
                        text: MediaService.artist || "Unknown Artist"
                        maxWidth: 160
                        fontSize: 11
                        hovered: mediaHover.hovered
                        opacity: 0.7
                    }
                }
            }

            HoverHandler {
                id: mediaHover
                enabled: root.hasMedia
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                enabled: root.hasMedia
                acceptedButtons: Qt.LeftButton
                onTapped: IslandController.openMediaFromLeftSection()
            }
        }

        // Center Section: Clock and Calendar Date
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            CenterSection {
                expanded: true
                anchors.centerIn: parent
            }
        }

        // Right Section: Control toggles, tray, etc.
        RightSection {
            Layout.preferredWidth: root.sideWidth
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
