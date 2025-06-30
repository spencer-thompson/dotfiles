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

            implicitHeight: 40
            anchors {
                top: true
                left: true
                right: true
            }

            color: "transparent"

            WrapperMouseArea {
                // id: topMouseArea
                anchors.fill: parent
                // onClicked: console.log(`${Quickshell.screens.find(s => s.name === "DP-1")}`)
                onClicked: console.log(`${Hyprland.workspaces}`)

                // Rectangle {
                //     anchors.centerIn: parent
                //     // anchors.top: parent.top
                //     color: "white"
                //     height: 3
                //     width: parent.width * Battery.percent
                // }

                RowLayout {
                    id: topRow
                    anchors.fill: parent
                    anchors.bottomMargin: 8
                    spacing: 8
                    height: 32

                    // Rectangle {
                    //     // anchors.centerIn: parent
                    //     anchors.top: parent.top
                    //     color: "white"
                    //     height: 3
                    //     width: parent.width * Battery.percent
                    // }

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
                            anchors.bottomMargin: 6
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
                            width: parent.width * GPU.percent
                            anchors.right: parent.right
                            // anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            // anchors.topMargin: 0
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
                            width: parent.width * Memory.percent
                            anchors.right: parent.right
                            // anchors.verticalCenter: parent.verticalCenter
                            anchors.top: parent.verticalCenter
                            anchors.topMargin: 5
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
                        bottomLeftRadius: 8
                        bottomRightRadius: 8

                        color: cma.containsMouse ? "crimson" : "white"
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
                        //
                        // Text {
                        //     anchors.right: timeCenter.left
                        //     anchors.rightMargin: 3
                        //     anchors.leftMargin: 3
                        //     text: "󰤨"
                        //     color: "white"
                        //     font.family: "Berkeley Mono"
                        //     font.pointSize: 17
                        //     font.weight: 700
                        // }

                        Text {
                            id: timeCenter
                            anchors.centerIn: parent
                            text: cma.containsMouse ? Time.tlong : Time.tshort
                            // color: cma.containsMouse ? "white" : "crimson"
                            color: "black"
                            font.family: "Berkeley Mono"
                            font.pointSize: 20
                            font.weight: 700
                        }

                        MouseArea {
                            id: cma
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        // Rectangle {
                        //     anchors.top: topRow.top
                        //     anchors.horizontalCenter: topRow.horizontalCenter
                        //     height: 3
                        //     width: Battery.percent * topRow.width
                        // }
                    }

                    Rectangle {
                        color: "transparent"
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            id: memBar
                            height: 3
                            width: parent.width * CPU.percent
                            anchors.left: parent.left
                            anchors.bottom: parent.verticalCenter
                            anchors.bottomMargin: 6
                            color: "white"
                            radius: 5
                            border.color: "transparent"
                            // border.width: 2

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
                            anchors.verticalCenter: parent.verticalCenter
                            // anchors.bottomMargin: 2
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
                            // id: memBar
                            height: 3
                            width: parent.width * Memory.percent
                            anchors.left: parent.left
                            anchors.top: parent.verticalCenter
                            anchors.topMargin: 5
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
                // Rectangle {
                //     // anchors.top: parent.bottom
                //     color: "white"
                //     height: 3
                //     width: 10
                // }
            }

            Rectangle {
                // anchors.top: centerSection.top
                // anchors.topMargin: 30
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 37
                color: "white"
                radius: 5
                height: 3
                width: Battery.percent * centerSection.width
            }
        }
    }
}
