import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property bool panelVisible: false

    IpcHandler {
        target: "monitorSettings"

        function toggle(): void { root.panelVisible = !root.panelVisible }
        function show(): void { root.panelVisible = true }
        function hide(): void { root.panelVisible = false }
    }

    Loader {
        active: root.panelVisible
        sourceComponent: panelComponent
    }

    Component {
        id: panelComponent
        MonitorPanel {}
    }
}
