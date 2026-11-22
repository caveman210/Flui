import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../config"
import "../../components/sections"
import "."

RowLayout {
    id: root
    readonly property bool isBar: ConfigStore.layout === 2
    spacing: isBar ? 7 : 6
    implicitHeight: isBar ? 28 : 33

    HoverHandler {
        id: widgetHover
    }

    Text {
        text: "✦"
        color: Theme.accent
        font.pixelSize: 14
        Layout.alignment: Qt.AlignVCenter
    }

    ScrollingText {
        text: GreetingService.text
        maxWidth: root.isBar ? 260 : 160
        fontSize: 12
        hovered: widgetHover.hovered
        Layout.alignment: Qt.AlignVCenter
    }
}
