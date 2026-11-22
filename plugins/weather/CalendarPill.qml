import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../services"
import "."

Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: 64
    radius: 12
    color: Theme.surface
    border.width: 1
    border.color: Theme.border
    clip: true

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 12
        spacing: 12

        Text {
            text: WeatherService.icon
            color: Theme.accent
            font.family: Theme.iconFont
            font.pixelSize: 28
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: WeatherService.temp
            color: Theme.textPrimary
            font.pixelSize: 22
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        ColumnLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: 2

            Text {
                text: WeatherService.city !== "" ? WeatherService.city : "Weather"
                color: Theme.textPrimary
                font.pixelSize: 12
                font.bold: true
                Layout.alignment: Qt.AlignRight
            }

            Text {
                text: WeatherService.condition
                color: Theme.textSecondary
                font.pixelSize: 11
                Layout.alignment: Qt.AlignRight
                elide: Text.ElideRight
            }
        }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: PluginService.openView("weather", "center") }
}
