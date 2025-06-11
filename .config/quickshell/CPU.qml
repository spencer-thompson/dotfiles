pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// your singletons should always have Singleton as the type
Singleton {
    id: root
    property real percent

    Process {
        id: cpuProc
        command: ["quick-info", "cpu"]
        running: true

        stdout: SplitParser {
            onRead: data => root.percent = data
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: cpuProc.running = true
    }
}
