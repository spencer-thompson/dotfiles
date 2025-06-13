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
                top: true
                left: true
                right: true
            }

            color: "transparent"

            WrapperMouseArea {
                anchors.fill: parent
                // onClicked: console.log(`${Quickshell.screens.find(s => s.name === "DP-1")}`)
                onClicked: console.log(`${Hyprland.workspaces}`)

                RowLayout {
                    anchors.fill: parent
                    spacing: 12

                    Rectangle {
                        // id: topLeft
                        color: "transparent"
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            // id: cpuBar
                            height: 3
                            width: parent.width * CPU.percent
                            anchors.right: parent.right
                            // anchors.verticalCenter: parent.verticalCenter
                            anchors.bottom: parent.verticalCenter
                            anchors.bottomMargin: 2
                            color: "white"
                            radius: 5

                            Behavior on width {
                                NumberAnimation {
                                    duration: 800
                                    easing {
                                        type: Easing.InOutQuad
                                        amplitude: 1.0
                                        period: 0.5
                                    }
                                }
                            }
                        }

                        Rectangle {
                            // id: cpuBar
                            height: 3
                            width: parent.width * Load.percent
                            anchors.right: parent.right
                            // anchors.verticalCenter: parent.verticalCenter
                            anchors.top: parent.verticalCenter
                            anchors.topMargin: 2
                            color: "white"
                            radius: 5

                            Behavior on width {
                                NumberAnimation {
                                    duration: 800
                                    easing {
                                        type: Easing.InOutQuad
                                        amplitude: 1.0
                                        period: 0.5
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        // anchors.fill: parent
                        id: centerSection
                        bottomLeftRadius: 24
                        bottomRightRadius: 24

                        color: cma.containsMouse ? "crimson" : "black"
                        implicitWidth: cma.containsMouse ? 350 : 150
                        // Layout.fillWidth: true
                        Layout.fillHeight: true

                        Behavior on implicitWidth {
                            NumberAnimation {
                                easing {
                                    type: Easing.OutQuint
                                    amplitude: 1.0
                                    period: 0.5
                                }
                            }
                        }

                        // IconImage {
                        //     implicitSize: 20
                        //     source: Quickshell.iconPath("audio-volume-high-symbolic")
                        // }

                        Text {
                            anchors.centerIn: parent
                            text: cma.containsMouse ? Time.tlong : Time.tshort
                            // color: cma.containsMouse ? "white" : "crimson"
                            color: "white"
                            font.family: "Berkeley Mono"
                            font.pointSize: 20
                            font.weight: 700
                        }

                        MouseArea {
                            id: cma
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }

                    Rectangle {
                        color: "transparent"
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            id: memBar
                            height: 3
                            width: parent.width * Memory.percent
                            anchors.left: parent.left
                            anchors.top: parent.verticalCenter
                            anchors.topMargin: 2
                            color: "white"
                            radius: 5
                            border.color: "transparent"
                            border.width: 2

                            Behavior on width {
                                NumberAnimation {
                                    duration: 800
                                    easing {
                                        type: Easing.InOutQuad
                                        amplitude: 1.0
                                        period: 0.5
                                    }
                                }
                            }
                        }

                        Rectangle {
                            // id: memBar
                            height: 3
                            width: parent.width * GPU.percent
                            anchors.left: parent.left
                            anchors.bottom: parent.verticalCenter
                            anchors.bottomMargin: 2
                            color: "white"
                            radius: 5

                            Behavior on width {
                                NumberAnimation {
                                    duration: 800
                                    easing {
                                        type: Easing.InOutQuad
                                        amplitude: 1.0
                                        period: 0.5
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
