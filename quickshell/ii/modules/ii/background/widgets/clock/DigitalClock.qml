pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Layouts

// Minimal editorial clock inspired by the reference:
// WEEKDAY
// DD MONTH, YYYY.
// - H:MM AM -
ColumnLayout {
    id: clockColumn
    spacing: 2

    property color colText: "#101923"
    property var textHorizontalAlignment: Text.AlignHCenter
    readonly property var enLocale: Qt.locale("en_US")

    // Weekday
    ClockText {
        id: weekdayText
        Layout.alignment: Qt.AlignHCenter
        text: clockColumn.enLocale.toString(DateTime.clock.date, "dddd").toUpperCase()
        color: clockColumn.colText
        horizontalAlignment: Text.AlignHCenter
        animateChange: false
        font {
            family: Config.options.background.widgets.clock.digital.font.family
            pixelSize: Config.options.background.widgets.clock.digital.font.size
            weight: 400
            letterSpacing: 7
            variableAxes: ({
                "wdth": 110,
                "ROND": 0
            })
        }
        style: Text.Normal
    }

    // Date
    ClockText {
        id: dateText
        Layout.topMargin: 1
        Layout.alignment: Qt.AlignHCenter
        visible: Config.options.background.widgets.clock.digital.showDate
        text: clockColumn.enLocale.toString(DateTime.clock.date, "dd MMMM, yyyy.").toUpperCase()
        color: clockColumn.colText
        horizontalAlignment: Text.AlignHCenter
        animateChange: false
        font {
            family: Config.options.background.widgets.clock.digital.font.family
            pixelSize: 12
            weight: 450
            letterSpacing: 1.2
            variableAxes: ({
                "wdth": 105,
                "ROND": 0
            })
        }
        style: Text.Normal
    }

    // Time
    ClockText {
        id: timeText
        Layout.topMargin: 1
        Layout.alignment: Qt.AlignHCenter
        text: "- " + clockColumn.enLocale.toString(DateTime.clock.date, "h:mm AP") + " -"
        color: clockColumn.colText
        horizontalAlignment: Text.AlignHCenter
        animateChange: false
        font {
            family: Config.options.background.widgets.clock.digital.font.family
            pixelSize: 13
            weight: 450
            letterSpacing: 1.5
            variableAxes: ({
                "wdth": 105,
                "ROND": 0
            })
        }
        style: Text.Normal
    }

    // Optional quote remains supported.
    ClockText {
        visible: Config.options.background.widgets.clock.quote.enable && Config.options.background.widgets.clock.quote.text.length > 0
        Layout.topMargin: 5
        Layout.alignment: Qt.AlignHCenter
        font.pixelSize: Appearance.font.pixelSize.normal
        text: Config.options.background.widgets.clock.quote.text
        animateChange: false
        color: clockColumn.colText
        horizontalAlignment: clockColumn.textHorizontalAlignment
        style: Text.Normal
    }
}
