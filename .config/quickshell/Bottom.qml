import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Scope {
    id: root
    property string time

    Variants {
        model: [Quickshell.screens.find(s => s.name === "DP-1")]

        PanelWindow {
            property var modelData
            screen: modelData

            implicitHeight: 30
            anchors {
                left: true
                right: true
                bottom: true
            }

            color: "transparent"

            // Text {
            //
            //     text: "hello world"
            // }

            RowLayout {
                id: workspacesRow
                // anchors.fill: parent
                anchors.centerIn: parent
                spacing: 12

                Repeater {
                    model: workspaces => Hyprland.workspaces.values

                    Rectangle {
                        width: 10
                        height: 10
                        color: "red"
                        Text {
                            required property string modelData
                            text: modelData
                        }
                    }
                }
            }

            // WrapperMouseArea {
            //     anchors.fill: parent
            //     onClicked: console.log(`${Quickshell.screens.find(s => s.name === "DP-1")}`)
            //
            //     RowLayout {
            //         anchors.fill: parent
            //         spacing: 12
            //
            //         Rectangle {
            //             id: topLeft
            //             color: "transparent"
            //             Layout.fillWidth: true
            //             Layout.fillHeight: true
            //
            //             Rectangle {
            //                 id: cpuBar
            //                 height: 4
            //                 width: parent.width * CPU.percent
            //                 anchors.right: parent.right
            //                 anchors.verticalCenter: parent.verticalCenter
            //                 color: "white"
            //                 radius: 5
            //
            //                 Behavior on width {
            //                     NumberAnimation {
            //                         duration: 800
            //                         easing {
            //                             type: Easing.InOutQuad
            //                             amplitude: 1.0
            //                             period: 0.5
            //                         }
            //                     }
            //                 }
            //             }
            //         }
            //
            //         Rectangle {
            //             // anchors.fill: parent
            //             id: centerSection
            //             bottomLeftRadius: 24
            //             bottomRightRadius: 24
            //
            //             color: cma.containsMouse ? "crimson" : "black"
            //             implicitWidth: cma.containsMouse ? 350 : 150
            //             // Layout.fillWidth: true
            //             Layout.fillHeight: true
            //
            //             Behavior on implicitWidth {
            //                 NumberAnimation {
            //                     easing {
            //                         type: Easing.OutQuint
            //                         amplitude: 1.0
            //                         period: 0.5
            //                     }
            //                 }
            //             }
            //
            //             Text {
            //                 anchors.centerIn: parent
            //                 text: cma.containsMouse ? Time.tlong : Time.tshort
            //                 // color: cma.containsMouse ? "white" : "crimson"
            //                 color: "white"
            //                 font.family: "Berkeley Mono"
            //                 font.pointSize: 20
            //                 font.weight: 700
            //             }
            //
            //             MouseArea {
            //                 id: cma
            //                 anchors.fill: parent
            //                 hoverEnabled: true
            //             }
            //         }
            //
            //         Rectangle {
            //             color: "transparent"
            //             Layout.fillWidth: true
            //             Layout.fillHeight: true
            //
            //             Rectangle {
            //                 id: memBar
            //                 height: 4
            //                 width: parent.width * Memory.percent
            //                 anchors.left: parent.left
            //                 anchors.verticalCenter: parent.verticalCenter
            //                 color: "white"
            //                 radius: 5
            //
            //                 Behavior on width {
            //                     NumberAnimation {
            //                         duration: 800
            //                         easing {
            //                             type: Easing.InOutQuad
            //                             amplitude: 1.0
            //                             period: 0.5
            //                         }
            //                     }
            //                 }
            //             }
            //         }
            //     }
            // }
        }
    }
}
