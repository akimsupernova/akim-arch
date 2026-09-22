import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property bool cleaning: false
    property string statusText: "System ready"
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
        Quickshell.execDetached(["hyprctl", "keyword", "bind", "SUPER ALT, C, exec, qs -c cleaner ipc call cleaner toggle"])
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

    function runScript(scriptName) {
        if (cleaning)
            return;

        cleaning = true;
        statusText = "Cleaning...";

        cleanupTimer.restart();

        cleanupProcess.command = [
            "/usr/bin/bash",
            Quickshell.env("HOME") + "/.config/quickshell/cleaner/scripts/" + scriptName
        ];

        cleanupProcess.running = true;
    }

    Process {
        id: cleanupProcess

        onExited: function(exitCode, exitStatus) {
            cleanupTimer.stop();
            root.cleaning = false;

            if (exitCode === 0)
                root.statusText = "Cleanup completed";
            else
                root.statusText = "Cleanup failed (" + exitCode + ")";
        }
    }

    Timer {
        id: cleanupTimer
        interval: 30000
        repeat: false

        onTriggered: {
            if (cleanupProcess.running) {
                cleanupProcess.signal(9)
                root.cleaning = false
                root.statusText = "Cleanup timed out"
            }
        }
    }

    IpcHandler {
        target: "cleaner"

        function toggle(): void {
            launcher.visible = !launcher.visible;
        }

        function show(): void {
            launcher.visible = true;
        }

        function hide(): void {
            launcher.visible = false;
        }
    }

    PanelWindow {
        id: launcher
        visible: false

        anchors {
            top: true
            right: true
        }

        margins {
            top: 80
            right: 30
        }

        implicitWidth: 360
        implicitHeight: 470
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        Item {
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                radius: 20
                color: root.withAlpha(root.theme.background, 0.88)
                border.width: 1
                border.color: root.theme.outline
            }

            Column {
                anchors {
                    fill: parent
                    margins: 20
                }
                spacing: 14

                RowLayout {
                    width: parent.width
                    height: 48
                    spacing: 12

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 14
                        color: root.theme.surface

                        Text {
                            anchors.centerIn: parent
                            text: "\uf2ed"
                            font.family: "Font Awesome 6 Free"
                            font.pixelSize: 22
                            font.weight: Font.Bold
                            color: root.theme.text
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: "SYSTEM CLEANER"
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            color: root.theme.text
                        }

                        Text {
                            text: "Arch Linux Maintenance"
                            font.pixelSize: 11
                            color: root.theme.muted
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 12
                    color: root.theme.surface

                    Text {
                        anchors.centerIn: parent
                        text: cleaning
                        ? "\uf110  " + statusText
                        : "\uf058  " + statusText
                        font.family: "Font Awesome 6 Free"
                        font.pixelSize: 11
                        color: cleaning ? root.theme.muted : root.theme.primary
                    }
                }

                Grid {
                    width: parent.width
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    CleanerCard {
                        width: (parent.width - 10) / 2
                        height: 100
                        icon: "\uf1c0"
                        title: "Pacman Cache"
                        description: "Remove old packages"
                        onClicked: root.runScript("pacman-cache.sh")
                    }

                    CleanerCard {
                        width: (parent.width - 10) / 2
                        height: 100
                        icon: "\uf1b2"
                        title: "Orphans"
                        description: "Remove unused packages"
                        onClicked: root.runScript("orphans.sh")
                    }

                    CleanerCard {
                        width: (parent.width - 10) / 2
                        height: 100
                        icon: "\uf1ea"
                        title: "Journal"
                        description: "Keep last 7 days"
                        onClicked: root.runScript("journal.sh")
                    }

                    CleanerCard {
                        width: (parent.width - 10) / 2
                        height: 100
                        icon: "\uf1f8"
                        title: "Thumbnails"
                        description: "Clear thumbnail cache"
                        onClicked: root.runScript("thumbnails.sh")
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 52
                    radius: 14
                    color: cleanMouse.containsMouse ? root.theme.primaryContainer : root.theme.surface
                    border.width: 1
                    border.color: root.theme.outline

                    Row {
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            text: "\uf2f1"
                            font.family: "Font Awesome 6 Free"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: root.theme.text
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: cleaning ? "CLEANING..." : "CLEAN EVERYTHING"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: root.theme.text
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 1
                        }
                    }

                    MouseArea {
                        id: cleanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !root.cleaning
                        onClicked: root.runScript("clean-all.sh")
                    }
                }

                Item {
                    width: 1
                    height: 1
                }

                Text {
                    width: parent.width
                    text: "Safe maintenance tools • By AKIMPNG"
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 10
                    color: root.theme.muted
                }
            }
        }
    }

    component CleanerCard: Rectangle {
        id: card

        property string icon: ""
        property string title: ""
        property string description: ""
        signal clicked()

        radius: 16
        color: mouse.containsMouse ? root.theme.primaryContainer : root.theme.surface
        border.width: 1
        border.color: mouse.containsMouse ? root.theme.primary : root.theme.outline

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        Behavior on border.color {
            ColorAnimation { duration: 140 }
        }

        Column {
            anchors.centerIn: parent
            spacing: 6

            Text {
                width: card.width
                text: card.icon
                horizontalAlignment: Text.AlignHCenter
                font.family: "Font Awesome 6 Free"
                font.pixelSize: 22
                font.weight: Font.Bold
                color: root.theme.text
            }

            Text {
                width: card.width
                text: card.title
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: root.theme.text
            }

            Text {
                width: card.width
                text: card.description
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 9
                color: root.theme.muted
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: !root.cleaning
            onClicked: card.clicked()
        }
    }
}
