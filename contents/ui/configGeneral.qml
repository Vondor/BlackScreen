/*
 * Settings page.
 *
 * The cfg_* properties are picked up automatically by Plasma and written to
 * ~/.config/plasma-org.kde.plasma.desktop-appletsrc when you press OK/Apply.
 * The global shortcut lives in the same file, under the applet's [Shortcuts]
 * group, because Plasma owns that value.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls
import org.kde.plasma.plasmoid

Kirigami.FormLayout {
    id: page

    signal configurationChanged()

    property string cfg_shortcutScreen: ""
    property string cfg_shortcutScreenDefault: ""

    property string cfg_lastScreen: ""
    property string cfg_lastScreenDefault: ""

    property alias cfg_clickToRestore: clickToRestore.checked
    property bool cfg_clickToRestoreDefault: true

    property alias cfg_hideCursor: hideCursor.checked
    property bool cfg_hideCursorDefault: false

    property alias cfg_showResolution: showResolution.checked
    property bool cfg_showResolutionDefault: true

    property alias cfg_collapseAfterClick: collapseAfterClick.checked
    property bool cfg_collapseAfterClickDefault: true

    // Set once the page is fully built, so loading values does not look like
    // the user changing them.
    property bool ready: false

    // The Plasma::Applet instance. The shortcut is stored on it directly.
    property var applet: null
    property var pendingShortcut: undefined

    // Called by Plasma before it writes the cfg_* values.
    function saveConfig() {
        if (applet && pendingShortcut !== undefined) {
            applet.globalShortcut = pendingShortcut;
        }
    }

    function rebuildScreenModel() {
        screenModel.clear();
        screenModel.append({
            text: i18n("The one picked last in the widget"),
            value: ""
        });

        const screens = Qt.application.screens;
        let known = (page.cfg_shortcutScreen === "");

        for (let i = 0; i < screens.length; ++i) {
            const hasName = screens[i].name && screens[i].name.length > 0;
            const key = hasName ? screens[i].name : "screen-" + i;
            screenModel.append({
                text: hasName ? screens[i].name : i18n("Screen %1", i + 1),
                value: key
            });
            if (key === page.cfg_shortcutScreen) {
                known = true;
            }
        }

        if (!known) {
            screenModel.append({
                text: i18n("%1 (not connected right now)", page.cfg_shortcutScreen),
                value: page.cfg_shortcutScreen
            });
        }

        screenCombo.currentIndex = screenCombo.indexOfValue(page.cfg_shortcutScreen);
    }

    Component.onCompleted: {
        try {
            page.applet = Plasmoid;
        } catch (error) {
            page.applet = null;
        }
        if (page.applet) {
            shortcutItem.keySequence = page.applet.globalShortcut;
        }
        rebuildScreenModel();
        page.ready = true;
    }

    ListModel {
        id: screenModel
    }

    // ------------------------------------------------------------------
    // Shortcut
    // ------------------------------------------------------------------

    KQuickControls.KeySequenceItem {
        id: shortcutItem

        Kirigami.FormData.label: i18n("Toggle shortcut:")
        showClearButton: true
        enabled: page.applet !== null

        onKeySequenceChanged: {
            if (!page.ready) {
                return;
            }
            page.pendingShortcut = shortcutItem.keySequence;
            page.configurationChanged();
        }
    }

    QQC2.Label {
        Layout.maximumWidth: Kirigami.Units.gridUnit * 22
        wrapMode: Text.WordWrap
        font: Kirigami.Theme.smallFont
        opacity: 0.75
        text: i18n("One key combination, used as an on/off switch: press it once to black out the other monitors, press it again to bring them back.")
    }

    QQC2.ComboBox {
        id: screenCombo

        Kirigami.FormData.label: i18n("Monitor the shortcut keeps:")
        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        textRole: "text"
        valueRole: "value"
        model: screenModel

        onActivated: {
            page.cfg_shortcutScreen = screenCombo.currentValue;
        }
    }

    // ------------------------------------------------------------------
    // Behaviour
    // ------------------------------------------------------------------

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Behavior")
    }

    QQC2.CheckBox {
        id: clickToRestore
        text: i18n("Click a black monitor to bring all monitors back")
    }

    QQC2.CheckBox {
        id: hideCursor
        text: i18n("Hide the mouse cursor on black monitors")
    }

    QQC2.CheckBox {
        id: collapseAfterClick
        text: i18n("Close the widget after picking a monitor")
    }

    QQC2.CheckBox {
        id: showResolution
        text: i18n("Show each monitor's resolution")
    }
}
