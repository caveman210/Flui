import QtQuick
import QtQuick.Layouts

import "../../core"
import "../../styles"
import "."

// Quote-of-the-day panel, opened from the bar's greeting/quote line.
FocusScope {
    id: root

    implicitWidth: 560
    implicitHeight: layout.implicitHeight + 56

    Component.onCompleted: {
        forceActiveFocus()
        if (!QuoteService.hasQuote) {
            QuoteService.refresh()
        }
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            IslandController.reset()
            event.accepted = true
        }
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 28
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            Text {
                text: "QUOTE OF THE DAY"
                color: Theme.textSecondary
                font.family: Theme.iconFont
                font.pixelSize: 10
                font.letterSpacing: 2
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 26
                height: 26
                radius: 13
                color: refreshHover.hovered ? Theme.surfaceVariant : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰑐"
                    font.family: Theme.iconFont
                    font.pixelSize: 13
                    color: QuoteService.loading ? Theme.accent : Theme.textSecondary
                }

                HoverHandler { id: refreshHover }
                TapHandler {
                    onTapped: QuoteService.refresh()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: QuoteService.hasQuote
                    ? "“" + QuoteService.quote + "”"
                    : QuoteService.loading
                        ? "Fetching the quote of the day…"
                        : "No quote available right now."
            color: QuoteService.hasQuote
                    ? Theme.textPrimary
                    : Theme.textSecondary
            font.family: Theme.iconFont
            font.pixelSize: 20
            font.italic: true
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.3
        }

        Text {
            Layout.fillWidth: true
            visible: QuoteService.hasQuote
                    && QuoteService.author !== ""
            text: "- " + QuoteService.author
            color: Theme.textSecondary
            font.family: Theme.iconFont
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
