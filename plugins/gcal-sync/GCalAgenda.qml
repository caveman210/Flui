import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../styles"

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 6

    property var events: []
    property bool authenticated: false
    property bool syncing: false

    Process {
        id: statusChecker
        command: [
            Quickshell.env("HOME") + "/.config/quickshell/plugins/gcal-sync/gcal.py",
            "status"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim())
                    root.authenticated = data.authenticated
                    if (root.authenticated) {
                        eventsFetcher.running = true
                    }
                } catch (e) {
                    console.warn("GCal status parse error:", e)
                }
            }
        }
    }

    Process {
        id: eventsFetcher
        command: [
            Quickshell.env("HOME") + "/.config/quickshell/plugins/gcal-sync/gcal.py",
            "events"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.syncing = false
                try {
                    var data = JSON.parse(text.trim())
                    if (data.events && Array.isArray(data.events)) {
                        root.events = data.events
                    }
                } catch (e) {
                    console.warn("GCal events parse error:", e)
                }
            }
        }
    }

    Process {
        id: authRunner
        command: [
            Quickshell.env("HOME") + "/.config/quickshell/plugins/gcal-sync/gcal.py",
            "auth"
        ]
        onExited: {
            statusChecker.running = true
        }
    }

    Timer {
        interval: 300000 // 5 minutes periodic auto-sync
        repeat: true
        running: root.authenticated
        onTriggered: {
            if (!eventsFetcher.running) {
                root.syncing = true
                eventsFetcher.running = true
            }
        }
    }

    Component.onCompleted: {
        statusChecker.running = true
    }

    // -------------------------------------------------------------
    // HEADER: Section Label & Actions
    // -------------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Text {
            text: "Google Calendar"
            color: Theme.textPrimary
            font.pixelSize: 11
            font.bold: true
        }

        Item { Layout.fillWidth: true }

        Text {
            visible: root.authenticated
            text: root.syncing ? "󰑐 Syncing..." : "󰑐 Refresh"
            color: syncHover.hovered ? Theme.accent : Theme.textMuted
            font.pixelSize: 10
            HoverHandler { id: syncHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    root.syncing = true
                    eventsFetcher.running = true
                }
            }
        }
    }

    // -------------------------------------------------------------
    // 1-CLICK WEB LOGIN BUTTON (Opens browser setup & Google OAuth)
    // -------------------------------------------------------------
    Rectangle {
        visible: !root.authenticated
        Layout.fillWidth: true
        implicitHeight: 38
        radius: 8
        color: Theme.surface
        border.color: Theme.border
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Text {
                text: "󱓞"
                color: Theme.accent
                font.family: Theme.iconFontMono
                font.pixelSize: 15
            }

            Text {
                text: "Connect Account"
                color: Theme.textPrimary
                font.pixelSize: 11
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle {
                implicitWidth: btnText.implicitWidth + 14
                implicitHeight: 24
                radius: 6
                color: authHover.hovered ? Theme.accentHover : Theme.accent

                HoverHandler { id: authHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        authRunner.running = false
                        authRunner.running = true
                    }
                }

                Text {
                    id: btnText
                    anchors.centerIn: parent
                    text: "Sign In with Google"
                    color: Theme.background
                    font.pixelSize: 10
                    font.bold: true
                }
            }
        }
    }

    // -------------------------------------------------------------
    // EMPTY EVENTS STATE
    // -------------------------------------------------------------
    Rectangle {
        visible: root.authenticated && root.events.length === 0
        Layout.fillWidth: true
        implicitHeight: 32
        radius: 8
        color: Theme.surface
        border.color: Theme.border
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "No upcoming events scheduled"
            color: Theme.textMuted
            font.pixelSize: 10
        }
    }

    // -------------------------------------------------------------
    // EVENTS LIST
    // -------------------------------------------------------------
    Repeater {
        model: root.authenticated ? root.events : 0
        delegate: Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: 34
            radius: 8
            color: eventHover.hovered ? Theme.surfaceVariant : Theme.surface
            border.color: Theme.border
            border.width: 1

            HoverHandler { id: eventHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    if (modelData.htmlLink) {
                        openLinkProc.command = ["xdg-open", modelData.htmlLink]
                        openLinkProc.running = false
                        openLinkProc.running = true
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Rectangle {
                    implicitWidth: evTime.implicitWidth + 8
                    implicitHeight: 18
                    radius: 4
                    color: Theme.surfaceVariant

                    Text {
                        id: evTime
                        anchors.centerIn: parent
                        text: modelData.time || "All Day"
                        color: Theme.accent
                        font.pixelSize: 9
                        font.bold: true
                    }
                }

                Text {
                    text: modelData.summary || "(No Title)"
                    color: Theme.textPrimary
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    visible: modelData.location && modelData.location.length > 0
                    text: "󰍎"
                    color: Theme.textMuted
                    font.family: Theme.iconFontMono
                    font.pixelSize: 11
                }
            }
        }
    }

    Process {
        id: openLinkProc
    }
}
