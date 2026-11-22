pragma Singleton

import QtQuick
import Quickshell

import "MotivationUtils.js" as MotivationUtils

// Bar idle line: a time-of-day greeting or one of the short
// motivational tidbits, chosen per local day with a 70/30 split in
// favour of the greeting.
Singleton {
    id: root

    readonly property var tidbits: [
        "Cross your limits",
        "Make it count",
        "One thing at a time",
        "Stay curious",
        "Keep moving",
        "Small steps, big change",
        "Breathe and begin",
        "Own the day",
        "Less noise, more focus",
        "Start where you are",
        "Do the brave thing",
        "You've got this"
    ]

    property string text: ""
    property bool showingTidbit: false

    function timeOfDayGreeting(d) {
        var h = d.getHours()

        if (h >= 5 && h < 12)
            return "Good morning"

        if (h >= 12 && h < 17)
            return "Good afternoon"

        if (h >= 17 && h < 22)
            return "Good evening"

        return "Good night"
    }

    function refresh() {
        var now = new Date()
        var seed = MotivationUtils.dailySeed(now.getTime())
        showingTidbit = true
        text = tidbits[(seed >>> 8) % tidbits.length]
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 60 * 1000
        running: true
        repeat: true

        onTriggered: root.refresh()
    }
}
