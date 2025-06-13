pragma Singleton

import Quickshell.Hyprland
import Quickshell
import QtQuick

Singleton {
    id: root
    // an expression can be broken across multiple lines using {}
    // readonly property list<Workspace> workspaces: layout.children.filter
    // readonly property string tlong: {
    //     Qt.formatDateTime(clock.date, "h:mm AP ddd MMM d");
    // }
    //

    // readonly property list workspaces: Hyprland.workspaces

    Repeater {
        model: Hyprland.workspaces.values.length

        Rectangle {
            color: "red"
        }
    }
}
