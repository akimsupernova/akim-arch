import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

ColumnLayout {
    id: root
    property var monitorData
    property color accent: "#0DB7D4"
    property color textColor: "#e8eeeb"          // forced light, jangan andalkan theme yang bisa hitam
    property color mutedColor: "#a8b3b0"
    property color surfaceColor: "#161d1c"
    property color surfaceVariantColor: "#252b2a"
    property color outlineColor: "#899390"
    property color outlineVariantColor: "#3f4947"
    property color onPrimaryColor: "#003731"
    signal status(string msg)

    // Override whatever parent passes if it turns out dark
    Component.onCompleted: {
        // pastikan textColor selalu terang
        if (Qt.colorEqual(textColor, "black") || textColor.r + textColor.g + textColor.b < 1.2) {
            textColor = "#e8eeeb"
            mutedColor = "#a8b3b0"
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: content.implicitHeight + 20
        radius: 14
        color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, 0.78)
        border.color: Qt.rgba(root.outlineVariantColor.r, root.outlineVariantColor.g, root.outlineVariantColor.b, 0.65)
        border.width: 1

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: root.monitorData.name + (root.monitorData.description ? "  ·  " + root.monitorData.description : "")
                    color: "#e8eeeb"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Label {
                    text: root.monitorData.width + "x" + root.monitorData.height + " @ " +
                          (Math.round(root.monitorData.refreshRate * 10) / 10) + "Hz"
                    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.95)
                    font.pixelSize: 11
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "Mode"
                    color: "#a8b3b0"
                    font.pixelSize: 11
                }
                ComboBox {
                    id: modeCombo
                    Layout.fillWidth: true
                    model: root.buildModeList()
                    textRole: "label"
                    Component.onCompleted: {
                        var cur = root.currentModeLabel()
                        for (var i = 0; i < model.length; i++) {
                            if (model[i].label === cur) { currentIndex = i; break }
                        }
                    }

                    // paksa palette biar style system gak override jadi hitam
                    palette.text: "#e8eeeb"
                    palette.buttonText: "#e8eeeb"
                    palette.windowText: "#e8eeeb"
                    palette.highlightedText: "#e8eeeb"

                    background: Rectangle {
                        implicitHeight: 30
                        radius: 8
                        color: Qt.rgba(0.15, 0.18, 0.17, 0.85)
                        border.color: modeCombo.activeFocus ? root.accent : Qt.rgba(0.4, 0.45, 0.44, 0.4)
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                    }
                    contentItem: Text {
                        text: modeCombo.displayText
                        color: "#e8eeeb"
                        font.pixelSize: 12
                        leftPadding: 10
                        rightPadding: 28
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    indicator: Text {
                        text: "▾"
                        color: "#a8b3b0"
                        font.pixelSize: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    popup: Popup {
                        y: modeCombo.height + 4
                        width: modeCombo.width
                        implicitHeight: Math.min(contentItem.implicitHeight + 8, 240)
                        padding: 4
                        background: Rectangle {
                            radius: 10
                            color: "#1e2524"
                            border.color: Qt.rgba(0.4, 0.45, 0.44, 0.45)
                            border.width: 1
                        }
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: modeCombo.popup.visible ? modeCombo.delegateModel : null
                            currentIndex: modeCombo.highlightedIndex
                            ScrollIndicator.vertical: ScrollIndicator { }
                        }
                    }
                    delegate: ItemDelegate {
                        width: modeCombo.width - 8
                        height: 32
                        contentItem: Text {
                            text: modelData.label
                            color: "#e8eeeb"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 10
                        }
                        background: Rectangle {
                            color: highlighted || pressed
                                   ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25)
                                   : "transparent"
                            radius: 6
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Label { text: "Pos X"; color: "#a8b3b0"; font.pixelSize: 11 }
                SpinBox {
                    id: posX
                    from: -10000; to: 10000
                    value: root.monitorData.x
                    implicitHeight: 30
                    editable: true

                    palette.text: "#e8eeeb"
                    palette.buttonText: "#e8eeeb"
                    palette.highlightedText: "#e8eeeb"

                    background: Rectangle {
                        radius: 8
                        color: Qt.rgba(0.15, 0.18, 0.17, 0.85)
                        border.color: posX.activeFocus ? root.accent : Qt.rgba(0.4, 0.45, 0.44, 0.4)
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                    }
                    contentItem: TextInput {
                        z: 2
                        text: posX.textFromValue(posX.value, posX.locale)
                        color: "#e8eeeb"
                        font.pixelSize: 12
                        horizontalAlignment: Qt.AlignHCenter
                        verticalAlignment: Qt.AlignVCenter
                        readOnly: !posX.editable
                        validator: posX.validator
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        selectByMouse: true
                        selectionColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.4)
                        selectedTextColor: "#ffffff"
                        // sync balik ke SpinBox
                        onTextChanged: {
                            if (activeFocus) {
                                var v = posX.valueFromText(text, posX.locale)
                                if (!isNaN(v) && v !== posX.value) posX.value = v
                            }
                        }
                    }
                    up.indicator: Item {
                        width: 22; height: parent.height
                        x: parent.width - width
                        Text {
                            text: "▴"
                            color: "#a8b3b0"
                            font.pixelSize: 11
                            anchors.centerIn: parent
                        }
                    }
                    down.indicator: Item {
                        width: 22; height: parent.height
                        x: 0
                        Text {
                            text: "▾"
                            color: "#a8b3b0"
                            font.pixelSize: 11
                            anchors.centerIn: parent
                        }
                    }
                }

                Label { text: "Y"; color: "#a8b3b0"; font.pixelSize: 11 }
                SpinBox {
                    id: posY
                    from: -10000; to: 10000
                    value: root.monitorData.y
                    implicitHeight: 30
                    editable: true

                    palette.text: "#e8eeeb"
                    palette.buttonText: "#e8eeeb"
                    palette.highlightedText: "#e8eeeb"

                    background: Rectangle {
                        radius: 8
                        color: Qt.rgba(0.15, 0.18, 0.17, 0.85)
                        border.color: posY.activeFocus ? root.accent : Qt.rgba(0.4, 0.45, 0.44, 0.4)
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                    }
                    contentItem: TextInput {
                        z: 2
                        text: posY.textFromValue(posY.value, posY.locale)
                        color: "#e8eeeb"
                        font.pixelSize: 12
                        horizontalAlignment: Qt.AlignHCenter
                        verticalAlignment: Qt.AlignVCenter
                        readOnly: !posY.editable
                        validator: posY.validator
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        selectByMouse: true
                        selectionColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.4)
                        selectedTextColor: "#ffffff"
                        onTextChanged: {
                            if (activeFocus) {
                                var v = posY.valueFromText(text, posY.locale)
                                if (!isNaN(v) && v !== posY.value) posY.value = v
                            }
                        }
                    }
                    up.indicator: Item {
                        width: 22; height: parent.height
                        x: parent.width - width
                        Text {
                            text: "▴"
                            color: "#a8b3b0"
                            font.pixelSize: 11
                            anchors.centerIn: parent
                        }
                    }
                    down.indicator: Item {
                        width: 22; height: parent.height
                        x: 0
                        Text {
                            text: "▾"
                            color: "#a8b3b0"
                            font.pixelSize: 11
                            anchors.centerIn: parent
                        }
                    }
                }

                Label { text: "Scale"; color: "#a8b3b0"; font.pixelSize: 11 }
                SpinBox {
                    id: scaleBox
                    from: 50; to: 300; stepSize: 5
                    value: Math.round(root.monitorData.scale * 100)
                    property real realValue: value / 100
                    textFromValue: function(v) { return (v / 100).toFixed(2) }
                    valueFromText: function(t) { return Math.round(parseFloat(t) * 100) }
                    implicitHeight: 30
                    editable: true

                    palette.text: "#e8eeeb"
                    palette.buttonText: "#e8eeeb"
                    palette.highlightedText: "#e8eeeb"

                    background: Rectangle {
                        radius: 8
                        color: Qt.rgba(0.15, 0.18, 0.17, 0.85)
                        border.color: scaleBox.activeFocus ? root.accent : Qt.rgba(0.4, 0.45, 0.44, 0.4)
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                    }
                    contentItem: TextInput {
                        z: 2
                        text: scaleBox.textFromValue(scaleBox.value, scaleBox.locale)
                        color: "#e8eeeb"
                        font.pixelSize: 12
                        horizontalAlignment: Qt.AlignHCenter
                        verticalAlignment: Qt.AlignVCenter
                        readOnly: !scaleBox.editable
                        validator: scaleBox.validator
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        selectByMouse: true
                        selectionColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.4)
                        selectedTextColor: "#ffffff"
                        onTextChanged: {
                            if (activeFocus) {
                                var v = scaleBox.valueFromText(text, scaleBox.locale)
                                if (!isNaN(v) && v !== scaleBox.value) scaleBox.value = v
                            }
                        }
                    }
                    up.indicator: Item {
                        width: 22; height: parent.height
                        x: parent.width - width
                        Text {
                            text: "▴"
                            color: "#a8b3b0"
                            font.pixelSize: 11
                            anchors.centerIn: parent
                        }
                    }
                    down.indicator: Item {
                        width: 22; height: parent.height
                        x: 0
                        Text {
                            text: "▾"
                            color: "#a8b3b0"
                            font.pixelSize: 11
                            anchors.centerIn: parent
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight

                Rectangle {
                    id: saveBtn
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: saveLabel.implicitWidth + 28
                    implicitHeight: 30
                    radius: 15
                    color: saveArea.pressed ? Qt.darker(root.accent, 1.15)
                           : (saveArea.containsMouse ? Qt.lighter(root.accent, 1.08) : root.accent)

                    Behavior on color { ColorAnimation { duration: 120 } }
                    scale: saveArea.pressed ? 0.96 : 1.0
                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                    Label {
                        id: saveLabel
                        anchors.centerIn: parent
                        text: "Apply"
                        color: root.onPrimaryColor
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: saveArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.saveToConfig()
                    }
                }
            }
        }
    }

    function buildModeList() {
        var modes = root.monitorData.availableModes || []
        var seen = ({})
        var out = []
        for (var i = 0; i < modes.length; i++) {
            var m = modes[i]
            var match = m.match(/^(\d+)x(\d+)@([\d.]+)Hz?$/)
            if (!match) continue
            var w = match[1], h = match[2]
            var refresh = Math.round(parseFloat(match[3]))
            var key = w + "x" + h + "@" + refresh
            if (seen[key]) continue
            seen[key] = true
            out.push({ label: key, width: parseInt(w), height: parseInt(h), refresh: refresh })
        }
        out.sort(function(a, b) {
            return (b.width * b.height - a.width * a.height) || (b.refresh - a.refresh)
        })
        return out
    }

    function currentModeLabel() {
        return root.monitorData.width + "x" + root.monitorData.height + "@" + Math.round(root.monitorData.refreshRate)
    }

    function selectedMode() {
        return modeCombo.model[modeCombo.currentIndex]
    }

    function saveToConfig() {
        var mode = root.selectedMode()
        if (!mode) return
        var modeStr = mode.width + "x" + mode.height + "@" + mode.refresh
        var posStr = posX.value + "x" + posY.value
        var scaleStr = scaleBox.realValue.toFixed(2)

        var script =
            "python3 \"$HOME/.config/quickshell/monitor-settings/update_monitor.py\"" +
            " --output '" + root.monitorData.name + "'" +
            " --mode '" + modeStr + "'" +
            " --position '" + posStr + "'" +
            " --scale '" + scaleStr + "'"

        saveProc.command = ["sh", "-c", script]
        saveProc.running = true
    }

    Process {
        id: saveProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.indexOf("OK") >= 0) {
                    root.status("Done, enjoy! - " + root.monitorData.name + ".")
                } else if (text.length > 0) {
                    root.status(text)
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) root.status("Error:" + text)
            }
        }
    }
}
