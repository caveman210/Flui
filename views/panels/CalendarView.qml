import QtQuick
import QtQuick.Layouts

import Quickshell

import "../../core"
import "../../styles"
import "../../services"
import "../../components/common"

FocusScope {
    id: root

    implicitWidth: 350
    implicitHeight: layout.implicitHeight + 36

    Component.onCompleted: {
        forceActiveFocus()
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            IslandController.reset()
            event.accepted = true
        }
    }

    property date displayedDate: new Date()
    property date today: new Date()

    readonly property int currentYear: displayedDate.getFullYear()
    readonly property int currentMonth: displayedDate.getMonth()

    readonly property string monthYearString: displayedDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")

    // Days in current month
    readonly property int daysInMonth: new Date(currentYear, currentMonth + 1, 0).getDate()

    // 0 = Sunday, 1 = Monday, etc. Adjust for Monday start:
    // If starting on Monday: (day + 6) % 7
    readonly property int firstDayOfWeek: {
        var day = new Date(currentYear, currentMonth, 1).getDay()
        return (day + 6) % 7
    }

    function prevMonth() {
        displayedDate = new Date(currentYear, currentMonth - 1, 1)
    }

    function nextMonth() {
        displayedDate = new Date(currentYear, currentMonth + 1, 1)
    }

    function resetToToday() {
        displayedDate = new Date()
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // Top Navigation Header (Month/Year & Prev/Next Buttons)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: root.monthYearString
                color: Theme.textPrimary
                font.bold: true
                font.pixelSize: 18
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            // Prev month button
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: prevHover.hovered ? Theme.buttonHover : Theme.surface
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    color: Theme.textSecondary
                    font.family: Theme.iconFont
                    font.pixelSize: 14
                }

                HoverHandler { id: prevHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.prevMonth() }
            }

            // Next month button
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: nextHover.hovered ? Theme.buttonHover : Theme.surface
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "󰅂"
                    color: Theme.textSecondary
                    font.family: Theme.iconFont
                    font.pixelSize: 14
                }

                HoverHandler { id: nextHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.nextMonth() }
            }
        }

        // Days of week header (Mon - Sun)
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                Item {
                    Layout.fillWidth: true
                    height: 24

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: Theme.textMuted
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }
        }

        // Calendar Grid (6 rows x 7 columns = 42 cells)
        GridLayout {
            id: grid
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 4
            columnSpacing: 4

            Repeater {
                model: 42

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8

                    readonly property int dayOffset: index - root.firstDayOfWeek
                    readonly property int dayNumber: dayOffset + 1
                    readonly property bool isCurrentMonth: dayNumber > 0 && dayNumber <= root.daysInMonth
                    readonly property bool isToday: isCurrentMonth &&
                                                   root.today.getDate() === dayNumber &&
                                                   root.today.getMonth() === root.currentMonth &&
                                                   root.today.getFullYear() === root.currentYear

                    color: isToday ? Theme.accent : (cellHover.hovered && isCurrentMonth ? Theme.buttonHover : "transparent")

                    Behavior on color {
                        ColorAnimation { duration: Theme.animationFast }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: isCurrentMonth ? dayNumber : ""
                        color: isToday ? Theme.background : (isCurrentMonth ? Theme.textPrimary : "transparent")
                        font.pixelSize: 12
                        font.bold: isToday
                    }

                    HoverHandler {
                        id: cellHover
                        enabled: isCurrentMonth
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }

        // Extensibility Slot: Calendar Weather Forecast Card
        ExtensionSlot {
            slotName: "calendar.weather"
            Layout.fillWidth: true
        }

        // Extensibility Slot: Calendar Events & Agenda
        ExtensionSlot {
            slotName: "calendar.events"
            Layout.fillWidth: true
        }
    }
}
