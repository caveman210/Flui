import QtQuick
import Quickshell.Widgets
import "../../styles"

Rectangle {
    id: root
    property string imageSource: ""
    property bool selected: false
    property bool isHovered: false

    width: 160
    height: 100
    radius: 12
    color: Theme.surfaceVariant

    // Crisp, bounded outer border matching theme system tokens
    border.width: selected ? 2 : 1
    border.color: selected ? Theme.accent : Theme.border

    Behavior on border.color {
        ColorAnimation { duration: Theme.animationFast }
    }

    Behavior on border.width {
        NumberAnimation { duration: Theme.animationFast }
    }

    // Image container strictly clipped within card bounds
    ClippingRectangle {
        anchors.fill: parent
        anchors.margins: selected ? 2 : 1
        radius: Math.max(0, root.radius - (selected ? 2 : 1))

        Image {
            id: img
            anchors.fill: parent
            source: root.imageSource ? (root.imageSource.startsWith("file://") ? root.imageSource : "file://" + root.imageSource) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true
            sourceSize.width: 320
            sourceSize.height: 200

            // Playful subtle scale on hover, strictly contained inside the ClippingRectangle
            scale: root.isHovered ? 1.04 : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: Theme.animationNormal
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Ambient dark bottom vignette to lift overlay tags & text
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.6; color: Qt.rgba(0, 0, 0, 0.1) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.5) }
            }
        }

        // Active state badge - strictly positioned within inner margins
        Rectangle {
            visible: root.selected
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 7
            width: 20
            height: 20
            radius: 10
            color: Theme.accent

            Text {
                anchors.centerIn: parent
                text: "✓"
                font.pixelSize: 11
                font.bold: true
                color: Theme.background
            }
        }
    }
}
