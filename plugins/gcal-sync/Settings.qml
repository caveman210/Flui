import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../styles"

ColumnLayout {
    id: root
    spacing: 12

    property bool authenticated: false
    property bool checking: false
    property bool syncing: false
    property string statusMsg: "Checking status..."

    Process {
        id: statusProc
        command: [
            Quickshell.env("HOME") + "/.config/quickshell/plugins/gcal-sync/gcal.py",
            "status"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.checking = false
                try {
                    var data = JSON.parse(text.trim())
                    root.authenticated = !!data.authenticated
                    root.statusMsg = root.authenticated ? "Connected to Google Calendar" : "Not connected"
                } catch (e) {
                    root.statusMsg = "Error checking status"
                }
            }
        }
    }

    Process {
        id: syncProc
        command: [
            Quickshell.env("HOME") + "/.config/quickshell/plugins/gcal-sync/gcal.py",
            "events"
        ]
        onExited: {
            root.syncing = false
            statusProc.running = true
        }
    }

    Process {
        id: logoutProc
        command: [
            Quickshell.env("HOME") + "/.config/quickshell/plugins/gcal-sync/gcal.py",
            "logout"
        ]
        onExited: {
            statusProc.running = true
        }
    }

    Process {
        id: authProc
        command: [
            Quickshell.env("HOME") + "/.config/quickshell/plugins/gcal-sync/gcal.py",
            "auth"
        ]
        onExited: {
            statusProc.running = true
        }
    }

    Component.onCompleted: {
        root.checking = true
        statusProc.running = true
    }

    // Status Card
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: statusCardLayout.implicitHeight + 20
        radius: 10
        color: Theme.surface
        border.color: Theme.border
        border.width: 1

        ColumnLayout {
            id: statusCardLayout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: root.authenticated ? Theme.success : Theme.textMuted
                }

                Text {
                    text: root.statusMsg
                    color: Theme.textPrimary
                    font.pixelSize: 12
                    font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: refreshText.implicitWidth + 12
                    implicitHeight: 22
                    radius: 6
                    color: refHover.hovered ? Theme.buttonHover : Theme.surfaceVariant

                    HoverHandler { id: refHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            root.checking = true
                            statusProc.running = false
                            statusProc.running = true
                        }
                    }

                    Text {
                        id: refreshText
                        anchors.centerIn: parent
                        text: "Check"
                        color: Theme.textSecondary
                        font.pixelSize: 10
                    }
                }
            }

            Text {
                text: root.authenticated
                    ? "Tokens and event cache stored in ~/.cache/quickshell/gcal/"
                    : "Authorize Flui to sync events into your Calendar view."
                color: Theme.textMuted
                font.pixelSize: 10
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }

    // Actions
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Sign In / Auth Button
        Rectangle {
            visible: !root.authenticated
            Layout.fillWidth: true
            implicitHeight: 32
            radius: 8
            color: signInHover.hovered ? Theme.accentHover : Theme.accent

            HoverHandler { id: signInHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    authProc.running = false
                    authProc.running = true
                }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    text: "󰊭"
                    color: Theme.background
                    font.family: Theme.iconFont
                    font.pixelSize: 13
                }
                Text {
                    text: "Sign In with Google"
                    color: Theme.background
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }

        // Sync Now Button
        Rectangle {
            visible: root.authenticated
            Layout.fillWidth: true
            implicitHeight: 32
            radius: 8
            color: syncHover.hovered ? Theme.buttonHover : Theme.surfaceVariant
            border.color: Theme.border
            border.width: 1

            HoverHandler { id: syncHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    if (!root.syncing) {
                        root.syncing = true
                        syncProc.running = false
                        syncProc.running = true
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.syncing ? "Syncing..." : "Sync Events Now"
                color: Theme.textPrimary
                font.pixelSize: 11
                font.bold: true
            }
        }

        // Disconnect / Clear Cache Button
        Rectangle {
            visible: root.authenticated
            implicitWidth: 120
            implicitHeight: 32
            radius: 8
            color: dcHover.hovered ? Theme.danger : Theme.surfaceVariant
            border.color: Theme.border
            border.width: 1

            HoverHandler { id: dcHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    logoutProc.running = false
                    logoutProc.running = true
                }
            }

            Text {
                anchors.centerIn: parent
                text: "Disconnect"
                color: dcHover.hovered ? Theme.background : Theme.danger
                font.pixelSize: 11
                font.bold: true
            }
        }
    }
}