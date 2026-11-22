import QtQuick
import QtQuick.Layouts

import "../../styles"
import "../../config"
import "./components"

// Inline Plugin Settings for Night Light Curve Engine
ColumnLayout {
    id: root
    spacing: 12

    // Information Card
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: infoCol.implicitHeight + 20
        radius: 10
        color: Theme.surface
        border.color: Theme.border
        border.width: 1

        ColumnLayout {
            id: infoCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰔎"
                    font.family: Theme.iconFont
                    font.pixelSize: 15
                    color: Theme.accent
                }

                Text {
                    text: "Transition Curve Progression"
                    color: Theme.textPrimary
                    font.pixelSize: 13
                    font.bold: true
                    Layout.fillWidth: true
                }
            }

            Text {
                text: "Shapes how Wayland gamma temperature transitions during scheduled hours. Drag handles on the graph to customize Bézier easing."
                color: Theme.textMuted
                font.pixelSize: 10
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }

    // Dedicated Interactive Curve Progression Section
    CurveEditor {
        Layout.fillWidth: true
    }
}