import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Io

//@ pragma ShellId ii-safe-tools

ShellRoot {
    id: root

    property bool calculatorVisible: false
    property var theme: ({
        background: "#141313", surface: "#201f20", surfaceHigh: "#2b2a2a",
        primary: "#cbc4cb", primaryContainer: "#2d2a2f", onPrimary: "#322f34",
        text: "#e6e1e1", muted: "#cbc5ca", outline: "#49464a", error: "#ffb4ab"
    })
    readonly property string themePath: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell/user/generated/colors.json"

    function setTheme(data) {
        try {
            const c = JSON.parse(data)
            root.theme = {
                background: c.background || c.surface || "#141313",
                surface: c.surface_container || c.surface || "#201f20",
                surfaceHigh: c.surface_container_high || c.surface_container_highest || "#2b2a2a",
                primary: c.primary || "#cbc4cb",
                primaryContainer: c.primary_container || "#2d2a2f",
                onPrimary: c.on_primary || "#322f34",
                text: c.on_background || c.on_surface || "#e6e1e1",
                muted: c.on_surface_variant || c.outline || "#cbc5ca",
                outline: c.outline_variant || c.outline || "#49464a",
                error: c.error || "#ffb4ab"
            }
        } catch (e) {}
    }

    function withAlpha(colorStr, alpha) {
        const c = Qt.color(colorStr)
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }

    function installBinds() {
        Quickshell.execDetached(["hyprctl", "keyword", "bind", "SUPER ALT, K, exec, qs -c tools ipc call tools calculator"])
    }

    function toggleCalculator() {
        calculatorVisible = !calculatorVisible
        if (calculatorVisible) calcField.forceActiveFocus()
    }

    Component.onCompleted: {
        themeFile.reload()
        installBinds()
    }

    FileView {
        id: themeFile
        path: root.themePath
        watchChanges: true
        onFileChanged: reload()
        onLoadedChanged: if (loaded) root.setTheme(text())
    }

    Timer {
        id: themeWatchdog
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            themeFile.path = ""
            themeFile.path = root.themePath
        }
    }

    IpcHandler {
        target: "tools"
        function calculator(): void { root.toggleCalculator() }
        function close(): void { root.calculatorVisible = false }
    }

    component ActionButton: Rectangle {
        property string label: ""
        signal clicked()
        implicitHeight: 48
        radius: 14
        color: mouse.containsMouse ? root.theme.primaryContainer : root.theme.surface
        border.width: 1
        border.color: root.theme.outline
        Text { anchors.centerIn: parent; text: label; color: root.theme.text; font.pixelSize: 15 }
        MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
    }

    PanelWindow {
        id: calcWindow
        visible: root.calculatorVisible
        anchors.top: true
        anchors.right: true
        margins.top: 72
        margins.right: 24
        implicitWidth: 360
        implicitHeight: 535
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        focusable: true

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: root.withAlpha(root.theme.background, 0.88)
            border.width: 1
            border.color: root.theme.outline

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Calculator"; color: root.theme.text; font.pixelSize: 21; font.bold: true; Layout.fillWidth: true }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 82
                    radius: 17
                    color: root.theme.surface
                    border.width: 1
                    border.color: root.theme.outline
                    TextField {
                        id: calcField
                        anchors.fill: parent
                        anchors.margins: 12
                        placeholderText: "♗♔♘♙♕♖"
                        color: root.theme.text
                        placeholderTextColor: root.theme.muted
                        font.pixelSize: 23
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        background: Item {}
                        onAccepted: calculate()
                        function calculate() {
                            let s = text.replace(/×/g, "*").replace(/÷/g, "/").replace(/,/g, ".")
                            if (!/^[0-9+\-*/().%^\s]+$/.test(s)) { resultText.text = "Invalid expression"; return }
                            try {
                                s = s.replace(/\^/g, "**")
                                const value = Function("return (" + s + ")")()
                                resultText.text = Number.isFinite(value) ? String(value) : "Invalid result"
                            } catch (e) { resultText.text = "Invalid expression" }
                        }
                    }
                }

                Text {
                    id: resultText
                    Layout.fillWidth: true
                    text: "0"
                    color: root.theme.primary
                    font.pixelSize: 30
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 4
                    rowSpacing: 7
                    columnSpacing: 7
                    property var keys: ["7","8","9","÷","4","5","6","×","1","2","3","-","0",".","%","+","(",")","C","="]
                    Repeater {
                        model: parent.keys
                        delegate: Rectangle {
                            required property string modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 14
                            color: modelData === "=" ? root.theme.primary : root.theme.surface
                            border.width: 1
                            border.color: root.theme.outline
                            Text { anchors.centerIn: parent; text: modelData; color: modelData === "=" ? root.theme.onPrimary : root.theme.text; font.pixelSize: 19; font.bold: modelData === "=" }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (modelData === "C") { calcField.text = ""; resultText.text = "0" }
                                    else if (modelData === "=") calcField.calculate()
                                        else calcField.text += modelData
                                            calcField.forceActiveFocus()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
