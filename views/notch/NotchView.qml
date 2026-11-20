import QtQuick
import QtQuick.Layouts

import "../shared"
import "../../styles"
import "../../services"
import "../../services/audio"
import "../../services/power"
import "../../components/bar"
import "../../components/sections"
import "../../core"
import "../../island"

Item {
    id: root
    readonly property bool hasCava: MediaService.isPlaying
    readonly property int defaultWidth: 180
    implicitWidth: indicators.anyActive
                       ? defaultWidth + indicators.leftWidth + indicators.rightWidth
                       : (hasCava ? defaultWidth + 24 : defaultWidth)
    implicitHeight: 33

    // Left end: Reactive Cava when playing audio (if no privacy indicators)
    Cava {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        visible: root.hasCava && !indicators.anyActive
        barCount: 4
        barWidth: 3
        spacingSize: 2
        barColor: Theme.accent
    }

    PrivacyIndicators {
        id: indicators
        split: false
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
    }

    // Centered Clock — clicking expands the Calendar alone
    RowLayout {
        id: row
        spacing: 8
        anchors.centerIn: parent

        ClockView {
            Layout.alignment: Qt.AlignVCenter
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: {
            if (IslandState.mode === IslandState.calendarMode)
                IslandController.reset()
            else
                IslandController.openCalendar()
        }
    }

    // Right end: Battery readout
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: BatteryService.icon
        color: Theme.icon
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
    }
}
