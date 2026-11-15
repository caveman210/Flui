import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

import "../../styles"
import "../../core"
import "../../island"

FocusScope {
    id: root

    readonly property var items: SystemTray.items ? SystemTray.items.values : []
    readonly property int itemCount: items.length
    readonly property int cols: Math.min(4, Math.max(1, itemCount))
    readonly property int rows: Math.max(1, Math.ceil(itemCount / cols))

    // Drill-in menu state
    property var activeMenuHandle: null
    property string activeMenuTitle: ""
    property var menuStack: []
    property var currentMenu: null

    function updateCurrentMenu() {
        currentMenu = menuStack.length > 0
            ? menuStack[menuStack.length - 1].handle
            : activeMenuHandle
    }

    readonly property string parentTitle: menuStack.length > 0
        ? menuStack[menuStack.length - 1].title
        : activeMenuTitle

    readonly property var menuEntries: menuOpener.children ? menuOpener.children.values : []

    readonly property int maxListHeight: 320
    readonly property int menuContentHeight: {
        if (menuEntries.length === 0)
            return 36

        var h = 0
        for (var i = 0; i < menuEntries.length; ++i)
            h += menuEntries[i].isSeparator ? 9 : 34
        return h
    }
    readonly property int menuListHeight: Math.min(menuContentHeight, maxListHeight)

    // Sizing: snug fit around icons with 8px gap and 12px margins
    implicitWidth: activeMenuHandle !== null
        ? 230
        : (itemCount === 0 ? 140 : cols * 24 + (cols - 1) * 8 + 24)

    implicitHeight: activeMenuHandle !== null
        ? (menuHeader.implicitHeight + menuListHeight + 24)
        : (itemCount === 0 ? 36 : rows * 24 + (rows - 1) * 8 + 18)

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.animationFast; easing.type: Theme.animationHorizontal }
    }
    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.animationFast; easing.type: Theme.animationVertical }
    }

    Component.onCompleted: forceActiveFocus()

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            if (root.menuStack.length > 0) {
                root.popSubMenu()
            } else if (root.activeMenuHandle !== null) {
                root.closeMenu()
            } else {
                IslandController.reset()
            }
            event.accepted = true
        }
    }

    function openMenuForItem(trayItem) {
        if (!trayItem || !trayItem.hasMenu)
            return

        var m = trayItem.menu
        var handle = (m && m.menu !== undefined && m.menu !== null) ? m.menu : m
        if (!handle)
            return

        root.activeMenuTitle = trayItem.title || trayItem.tooltip || trayItem.id || "Menu"
        root.menuStack = []
        root.activeMenuHandle = handle
        updateCurrentMenu()

        if (handle.updateLayout)
            handle.updateLayout()
        if (handle.sendOpened)
            handle.sendOpened()
    }

    function closeMenu() {
        if (root.activeMenuHandle && root.activeMenuHandle.sendClosed)
            root.activeMenuHandle.sendClosed()

        root.activeMenuHandle = null
        root.activeMenuTitle = ""
        root.menuStack = []
        root.currentMenu = null
    }

    function pushSubMenu(entry) {
        root.menuStack = root.menuStack.concat([{ handle: entry, title: entry.text }])
        updateCurrentMenu()
        if (entry.updateLayout)
            entry.updateLayout()
        if (entry.sendOpened)
            entry.sendOpened()
    }

    function popSubMenu() {
        if (root.menuStack.length === 0) {
            root.closeMenu()
            return
        }

        var top = root.menuStack[root.menuStack.length - 1]
        root.menuStack = root.menuStack.slice(0, root.menuStack.length - 1)
        updateCurrentMenu()

        if (top.handle && top.handle.sendClosed)
            top.handle.sendClosed()
    }

    // Icon source cache for fast rendering
    property var _iconCache: ({})
    function iconSource(icon) {
        if (!icon) return ""
        var cached = root._iconCache[icon]
        if (cached !== undefined) return cached
        var checked = Quickshell.iconPath(icon, true)
        var result = checked !== "" ? checked : icon
        root._iconCache[icon] = result
        return result
    }

    QsMenuOpener {
        id: menuOpener
        menu: root.currentMenu
    }

    // =========================================================================
    // VIEW 1: HUDDLED ICONS (Raw icons huddled together, max 4 per row)
    // =========================================================================
    Item {
        id: iconsContainer
        visible: root.activeMenuHandle === null
        anchors.fill: parent

        GridLayout {
            id: iconGrid
            anchors.centerIn: parent
            columns: root.cols
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                model: root.items

                Item {
                    id: iconTile
                    required property var modelData
                    readonly property var trayItem: modelData

                    width: 24
                    height: 24

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 20
                        opacity: tileHover.hovered ? 1.0 : 0.8
                        source: root.iconSource(iconTile.trayItem ? iconTile.trayItem.icon : "")

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.animationFast }
                        }
                    }

                    HoverHandler {
                        id: tileHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    // Left click: activate (or open menu if menu-only)
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: {
                            if (!iconTile.trayItem) return
                            if (iconTile.trayItem.onlyMenu) {
                                root.openMenuForItem(iconTile.trayItem)
                            } else {
                                iconTile.trayItem.activate()
                                IslandController.reset()
                            }
                        }
                    }

                    // Right click: drill-in menu subview
                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: {
                            if (iconTile.trayItem && iconTile.trayItem.hasMenu) {
                                root.openMenuForItem(iconTile.trayItem)
                            }
                        }
                    }
                }
            }
        }

        // Empty state
        Text {
            visible: root.itemCount === 0
            anchors.centerIn: parent
            text: "No tray apps"
            color: Theme.textMuted
            font.pixelSize: 11
        }
    }

    // =========================================================================
    // VIEW 2: DRILL-IN MENU PANE (When right clicked on an icon)
    // =========================================================================
    ColumnLayout {
        id: menuLayout
        visible: root.activeMenuHandle !== null
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        // Back header row
        RowLayout {
            id: menuHeader
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: backHover.hovered ? Theme.buttonHover : Theme.surface
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: Theme.accent
                    font.bold: true
                    font.pixelSize: 16
                }

                HoverHandler { id: backHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        if (root.menuStack.length > 0)
                            root.popSubMenu()
                        else
                            root.closeMenu()
                    }
                }
            }

            Text {
                text: root.parentTitle
                color: Theme.textPrimary
                font.bold: true
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                width: 20
                height: 20
                radius: 10
                color: menuCloseHover.hovered ? Theme.buttonHover : Theme.surface
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: Theme.textPrimary
                    font.pixelSize: 9
                }

                HoverHandler { id: menuCloseHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: IslandController.reset() }
            }
        }

        // Menu entries list
        ListView {
            id: menuList
            Layout.fillWidth: true
            implicitHeight: root.menuListHeight
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: root.menuEntries

            delegate: Item {
                id: mRow
                required property var modelData
                readonly property var entry: modelData
                readonly property bool isSeparator: entry.isSeparator
                readonly property bool isEnabled: !isSeparator && entry.enabled
                readonly property bool showCheck: !isSeparator && entry.buttonType !== QsMenuButtonType.None
                readonly property bool showIcon: !isSeparator && entry.icon !== ""

                width: menuList.width
                height: isSeparator ? 9 : 30

                // Separator
                Rectangle {
                    visible: mRow.isSeparator
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Theme.border
                }

                // Row background
                Rectangle {
                    visible: !mRow.isSeparator
                    anchors.fill: parent
                    radius: 6
                    color: rowHover.hovered && mRow.isEnabled ? Theme.buttonHover : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.animationFast }
                    }
                }

                // Checkmark / Radio indicator
                Text {
                    id: checkIndicator
                    visible: mRow.showCheck
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    horizontalAlignment: Text.AlignHCenter
                    text: mRow.entry.checkState === Qt.Checked
                        ? (mRow.entry.buttonType === QsMenuButtonType.RadioButton ? "●" : "✓")
                        : ""
                    color: Theme.accent
                    font.pixelSize: mRow.entry.buttonType === QsMenuButtonType.RadioButton ? 9 : 12
                }

                // Icon
                IconImage {
                    id: entryIcon
                    visible: mRow.showIcon
                    anchors.left: parent.left
                    anchors.leftMargin: mRow.showCheck ? 22 : 6
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 14
                    opacity: mRow.isEnabled ? 1.0 : 0.4
                    source: root.iconSource(mRow.entry.icon)
                }

                // Text label
                Text {
                    visible: !mRow.isSeparator
                    x: (mRow.showCheck ? 22 : 6) + (mRow.showIcon ? 20 : 0)
                    width: parent.width - x - (subChevron.visible ? 20 : 6)
                    anchors.verticalCenter: parent.verticalCenter
                    text: mRow.entry.text
                    color: Theme.textPrimary
                    opacity: mRow.isEnabled ? 1.0 : 0.4
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                // Submenu Chevron
                Text {
                    id: subChevron
                    visible: !mRow.isSeparator && mRow.entry.hasChildren
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: "›"
                    color: Theme.textSecondary
                    font.pixelSize: 13
                }

                HoverHandler {
                    id: rowHover
                    enabled: mRow.isEnabled
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    enabled: mRow.isEnabled
                    onTapped: {
                        if (mRow.entry.hasChildren) {
                            root.pushSubMenu(mRow.entry)
                        } else {
                            mRow.entry.triggered()
                            IslandController.reset()
                        }
                    }
                }
            }
        }

        // Empty actions state
        Text {
            visible: root.menuEntries.length === 0
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            text: "No actions available"
            color: Theme.textMuted
            font.pixelSize: 11
        }
    }
}
