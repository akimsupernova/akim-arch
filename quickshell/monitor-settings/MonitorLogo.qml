import QtQuick

// i cant believe i wrote this by hand TT

Item {
    id: logo
    property real size: 28
    property color accent: "#0DB7D4"
    property color surfaceColor: "#090f0e"
    property color mutedColor: "#899390"

    implicitWidth: size * 1.3
    implicitHeight: size

    Rectangle {
        id: bezel
        width: parent.width
        height: parent.height * 0.72
        radius: height * 0.18
        color: logo.surfaceColor
        border.color: Qt.rgba(logo.accent.r, logo.accent.g, logo.accent.b, 0.85)
        border.width: Math.max(1, size * 0.045)

        Rectangle {
            id: screen
            anchors.fill: parent
            anchors.margins: parent.height * 0.14
            radius: 2
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(logo.accent.r, logo.accent.g, logo.accent.b, 0.28) }
                GradientStop { position: 1.0; color: Qt.rgba(logo.accent.r, logo.accent.g, logo.accent.b, 0.04) }
            }
            clip: true

            Rectangle {
                id: scanLine
                width: parent.width
                height: Math.max(1, screen.height * 0.10)
                color: Qt.rgba(logo.accent.r, logo.accent.g, logo.accent.b, 0.9)
                y: 0

                SequentialAnimation on y {
                    loops: Animation.Infinite
                    running: true
                    NumberAnimation { to: screen.height - scanLine.height; duration: 1600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0; duration: 1600; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    Rectangle {
        anchors.top: bezel.bottom
        anchors.horizontalCenter: bezel.horizontalCenter
        width: Math.max(2, size * 0.08)
        height: parent.height * 0.14
        color: logo.mutedColor
    }
    Rectangle {
        anchors.top: bezel.bottom
        anchors.topMargin: parent.height * 0.14
        anchors.horizontalCenter: bezel.horizontalCenter
        width: parent.width * 0.42
        height: Math.max(2, size * 0.06)
        radius: height / 2
        color: logo.mutedColor
    }

    SequentialAnimation on opacity {
        loops: Animation.Infinite
        running: true
        NumberAnimation { to: 0.85; duration: 1800; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
    }
}
