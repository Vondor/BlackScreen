/*
 * Black Screen — a KDE Plasma 6 widget.
 *
 * Shows every connected monitor in its real relative position. Click one and
 * every other monitor is covered by a full-screen black window. Click it again
 * (or press the configured shortcut) and everything comes back.
 *
 * Only Qt and Plasma modules that ship with every Plasma 6 desktop are used.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Window

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    // ------------------------------------------------------------------
    // Monitor model
    // Every entry: { key, label, x, y, width, height, ref }
    // "ref" is the QQuickScreenInfo object, needed to place a window.
    // ------------------------------------------------------------------
    property var screenList: []
    property var virtualBounds: ({ x: 0, y: 0, width: 1, height: 1 })
    property string screensSignature: ""

    // ------------------------------------------------------------------
    // Blackout state
    // ------------------------------------------------------------------
    property string visibleScreenKey: ""
    property var blackoutWindows: []

    readonly property bool blackoutActive: visibleScreenKey.length > 0

    Plasmoid.icon: "video-display"
    Plasmoid.title: i18n("Black Screen")

    toolTipMainText: i18n("Black Screen")
    toolTipSubText: blackoutActive
        ? i18n("Showing %1 only", labelFor(visibleScreenKey))
        : i18n("All monitors are visible")

    switchWidth: Kirigami.Units.gridUnit * 14
    switchHeight: Kirigami.Units.gridUnit * 10

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Show all monitors")
            icon.name: "view-visible"
            visible: root.blackoutActive
            onTriggered: root.restoreAll()
        }
    ]

    // ==================================================================
    // Monitor discovery
    // ==================================================================

    function keyFor(screenInfo, index) {
        const name = screenInfo.name;
        return (name && name.length > 0) ? name : "screen-" + index;
    }

    function labelFor(key) {
        for (let i = 0; i < screenList.length; ++i) {
            if (screenList[i].key === key) {
                return screenList[i].label;
            }
        }
        return key;
    }

    function hasScreen(key) {
        for (let i = 0; i < screenList.length; ++i) {
            if (screenList[i].key === key) {
                return true;
            }
        }
        return false;
    }

    /* Reads the current monitor layout from Qt. Everything is in logical
       pixels, so mixed-DPI setups line up the same way the System Settings
       display page shows them. The model is only replaced when something
       actually changed, so the popup does not flicker while it is open. */
    function refreshScreens() {
        const source = Qt.application.screens;
        const list = [];
        let signature = "";
        let minX = 0, minY = 0, maxX = 0, maxY = 0;

        for (let i = 0; i < source.length; ++i) {
            const info = source[i];
            const hasName = info.name && info.name.length > 0;
            const entry = {
                key: keyFor(info, i),
                label: hasName ? info.name : i18n("Screen %1", i + 1),
                x: info.virtualX,
                y: info.virtualY,
                width: info.width,
                height: info.height,
                ref: info
            };

            if (i === 0) {
                minX = entry.x;
                minY = entry.y;
                maxX = entry.x + entry.width;
                maxY = entry.y + entry.height;
            } else {
                minX = Math.min(minX, entry.x);
                minY = Math.min(minY, entry.y);
                maxX = Math.max(maxX, entry.x + entry.width);
                maxY = Math.max(maxY, entry.y + entry.height);
            }

            signature += entry.key + "@" + entry.x + "," + entry.y
                       + "+" + entry.width + "x" + entry.height + ";";
            list.push(entry);
        }

        if (signature === root.screensSignature && root.screenList.length === list.length) {
            return;
        }

        root.screensSignature = signature;
        root.virtualBounds = list.length > 0
            ? { x: minX, y: minY,
                width: Math.max(1, maxX - minX),
                height: Math.max(1, maxY - minY) }
            : { x: 0, y: 0, width: 1, height: 1 };
        root.screenList = list;
    }

    // ==================================================================
    // Blackout
    // ==================================================================

    /* Covers every monitor except "key" with a full-screen black window. */
    function showOnly(key) {
        restoreAll();
        refreshScreens();

        if (!key || !hasScreen(key) || screenList.length < 2) {
            return;
        }

        const created = [];
        for (let i = 0; i < screenList.length; ++i) {
            const entry = screenList[i];
            if (entry.key === key) {
                continue;
            }
            const window = blackoutWindowComponent.createObject(null, {
                targetScreen: entry.ref
            });
            if (window) {
                created.push(window);
            }
        }

        root.blackoutWindows = created;
        root.visibleScreenKey = key;
        Plasmoid.configuration.lastScreen = key;
    }

    function restoreAll() {
        for (let i = 0; i < blackoutWindows.length; ++i) {
            const window = blackoutWindows[i];
            if (window) {
                window.visible = false;
                window.destroy();
            }
        }
        root.blackoutWindows = [];
        root.visibleScreenKey = "";
    }

    function toggleScreen(key) {
        if (visibleScreenKey === key) {
            restoreAll();
        } else {
            showOnly(key);
        }
    }

    function screenPicked(key) {
        toggleScreen(key);
        if (Plasmoid.configuration.collapseAfterClick) {
            root.expanded = false;
        }
    }

    // ==================================================================
    // Global shortcut
    // ==================================================================

    /* Which monitor the shortcut should keep. Configured monitor first, then
       the one picked last, then the monitor the widget itself sits on. */
    function shortcutTargetKey() {
        const configured = Plasmoid.configuration.shortcutScreen;
        if (configured && hasScreen(configured)) {
            return configured;
        }

        const last = Plasmoid.configuration.lastScreen;
        if (last && hasScreen(last)) {
            return last;
        }

        const geometry = Plasmoid.screenGeometry;
        if (geometry) {
            for (let i = 0; i < screenList.length; ++i) {
                if (screenList[i].x === geometry.x && screenList[i].y === geometry.y) {
                    return screenList[i].key;
                }
            }
        }

        return screenList.length > 0 ? screenList[0].key : "";
    }

    function toggleFromShortcut() {
        if (blackoutActive) {
            restoreAll();
            return;
        }
        refreshScreens();
        showOnly(shortcutTargetKey());
    }

    // Plasma turns the applet's global shortcut into this signal.
    Connections {
        target: Plasmoid
        ignoreUnknownSignals: true

        function onActivated() {
            root.toggleFromShortcut();
            // Plasma's default reaction to the shortcut is to open the popup.
            // We do not want that here, the shortcut is a pure on/off switch.
            collapseTimer.restart();
        }
    }

    Timer {
        id: collapseTimer
        interval: 0
        onTriggered: root.expanded = false
    }

    // ==================================================================
    // Reacting to monitors being plugged in or out
    // ==================================================================

    Connections {
        target: Qt.application
        ignoreUnknownSignals: true

        function onScreensChanged() {
            const previous = root.visibleScreenKey;
            root.restoreAll();
            root.refreshScreens();
            if (previous.length > 0 && root.hasScreen(previous)) {
                root.showOnly(previous);
            }
        }
    }

    // Cheap safety net in case the signal above is not delivered.
    Timer {
        interval: 2000
        repeat: true
        running: root.expanded
        onTriggered: root.refreshScreens()
    }

    Component.onCompleted: refreshScreens()
    Component.onDestruction: restoreAll()

    // ==================================================================
    // The black windows
    // ==================================================================

    Component {
        id: blackoutWindowComponent

        Window {
            id: blackWindow

            property var targetScreen: null

            screen: targetScreen
            title: i18n("Black Screen")
            color: "black"
            // Frameless, always on top, and it must not steal the keyboard
            // focus from whatever is running on the monitor you kept.
            flags: Qt.Window
                 | Qt.FramelessWindowHint
                 | Qt.WindowStaysOnTopHint
                 | Qt.WindowDoesNotAcceptFocus
            visible: false

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Plasmoid.configuration.hideCursor ? Qt.BlankCursor : Qt.ArrowCursor
                onClicked: {
                    if (Plasmoid.configuration.clickToRestore) {
                        root.restoreAll();
                    }
                }
            }

            Component.onCompleted: {
                if (targetScreen) {
                    // Helps X11; on Wayland the compositor places the window
                    // on the output named by the "screen" property above.
                    blackWindow.x = targetScreen.virtualX;
                    blackWindow.y = targetScreen.virtualY;
                    blackWindow.width = targetScreen.width;
                    blackWindow.height = targetScreen.height;
                }
                blackWindow.showFullScreen();
                blackWindow.raise();
            }
        }
    }

    // ==================================================================
    // Panel icon
    // ==================================================================

    compactRepresentation: MouseArea {
        id: compactRoot

        property bool wasExpanded: false

        readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        Layout.preferredWidth: vertical ? -1 : compactRoot.height
        Layout.preferredHeight: vertical ? compactRoot.width : -1

        hoverEnabled: true
        activeFocusOnTab: true

        Accessible.role: Accessible.Button
        Accessible.name: i18n("Black Screen")

        onPressed: wasExpanded = root.expanded
        onClicked: root.expanded = !wasExpanded

        Kirigami.Icon {
            anchors.fill: parent
            source: "video-display"
            active: compactRoot.containsMouse
        }

        // Little dot that tells you a blackout is running.
        Rectangle {
            visible: root.blackoutActive
            width: Math.round(Math.min(parent.width, parent.height) / 3.5)
            height: width
            radius: height / 2
            color: Kirigami.Theme.highlightColor
            border.width: 1
            border.color: Kirigami.Theme.backgroundColor
            anchors {
                right: parent.right
                bottom: parent.bottom
            }
        }
    }

    // ==================================================================
    // Popup / desktop view
    // ==================================================================

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.minimumHeight: Kirigami.Units.gridUnit * 11
        Layout.preferredWidth: Kirigami.Units.gridUnit * 24
        Layout.preferredHeight: Kirigami.Units.gridUnit * 16

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 4
                    elide: Text.ElideRight
                    text: root.blackoutActive
                        ? i18n("Showing %1 only", root.labelFor(root.visibleScreenKey))
                        : i18n("Pick a monitor")
                }

                PlasmaComponents3.Button {
                    visible: root.blackoutActive
                    icon.name: "view-visible"
                    text: i18n("Show all")
                    onClicked: root.restoreAll()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Kirigami.Theme.colorSet: Kirigami.Theme.View
                Kirigami.Theme.inherit: false

                color: "transparent"
                radius: 3
                border.width: 1
                border.color: Kirigami.Theme.disabledTextColor

                ScreenMap {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing

                    screens: root.screenList
                    bounds: root.virtualBounds
                    visibleScreenKey: root.visibleScreenKey
                    blackoutActive: root.blackoutActive
                    showResolution: Plasmoid.configuration.showResolution

                    onScreenActivated: key => root.screenPicked(key)
                }
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font: Kirigami.Theme.smallFont
                opacity: 0.75
                text: {
                    if (root.screenList.length < 2) {
                        return i18n("Only one monitor is connected, so there is nothing to black out.");
                    }
                    if (root.blackoutActive) {
                        return i18n("Click the highlighted monitor to bring the others back.");
                    }
                    return i18n("Click a monitor to black out all the others.");
                }
            }
        }
    }
}
