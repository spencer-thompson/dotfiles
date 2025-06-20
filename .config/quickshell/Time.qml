pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    // an expression can be broken across multiple lines using {}
    readonly property string tshort: {
        // The passed format string matches the default output of
        // the `date` command.
        Qt.formatDateTime(clock.date, "h:mm AP");
    }

    readonly property string tlong: {
        Qt.formatDateTime(clock.date, "h:mm AP ddd MMM d");
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
