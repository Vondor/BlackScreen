/*
 * Draws the connected monitors to scale, in their real relative positions,
 * and reports clicks on them.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Item {
    id: mapRoot

    property var screens: []
    property var bounds: ({ x: 0, y: 0, width: 1, height: 1 })
    property string visibleScreenKey: ""
    property bool blackoutActive: false
    property bool showResolution: true

    signal screenActivated(string key)

    // One factor for both axes keeps the aspect ratio of the real desktop.
    readonly property real scaleFactor: {
        if (!bounds || bounds.width <= 0 || bounds.height <= 0
                || width <= 0 || height <= 0) {
            return 1;
        }
        return Math.min(width / bounds.width, height / bounds.height);
    }

    Item {
        id: canvas

        anchors.centerIn: parent
        width: mapRoot.bounds.width * mapRoot.scaleFactor
        height: mapRoot.bounds.height * mapRoot.scaleFactor

        Repeater {
            model: mapRoot.screens

            delegate: Rectangle {
                id: tile

                readonly property bool isKept: mapRoot.visibleScreenKey === modelData.key
                readonly property bool isBlacked: mapRoot.blackoutActive && !isKept
                readonly property color labelColor: {
                    if (tile.isBlacked) {
                        return "#ffffff";
                    }
                    if (tile.isKept) {
                        return Kirigami.Theme.highlightedTextColor;
                    }
                    return Kirigami.Theme.textColor;
                }

                x: (modelData.x - mapRoot.bounds.x) * mapRoot.scaleFactor
                y: (modelData.y - mapRoot.bounds.y) * mapRoot.scaleFactor
                width: Math.max(Kirigami.Units.gridUnit, modelData.width * mapRoot.scaleFactor)
                height: Math.max(Kirigami.Units.gridUnit, modelData.height * mapRoot.scaleFactor)

                radius: 3
                clip: true

                color: {
                    if (tile.isBlacked) {
                        return "#000000";
                    }
                    if (tile.isKept) {
                        return Kirigami.Theme.highlightColor;
                    }
                    if (tileMouse.containsMouse) {
                        return Kirigami.Theme.alternateBackgroundColor;
                    }
                    return Kirigami.Theme.backgroundColor;
                }

                border.width: tileMouse.containsMouse ? 2 : 1
                border.color: tileMouse.containsMouse
                    ? Kirigami.Theme.highlightColor
                    : Kirigami.Theme.disabledTextColor

                Behavior on color {
                    ColorAnimation { duration: Kirigami.Units.shortDuration }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - Kirigami.Units.smallSpacing * 2
                    spacing: 0

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideMiddle
                        text: modelData.label
                        color: tile.labelColor
                    }

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        visible: mapRoot.showResolution
                                 && tile.height > Kirigami.Units.gridUnit * 3
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        opacity: 0.7
                        font: Kirigami.Theme.smallFont
                        text: Math.round(modelData.width) + " × " + Math.round(modelData.height)
                        color: tile.labelColor
                    }
                }

                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mapRoot.screenActivated(modelData.key)
                }
            }
        }
    }
}
