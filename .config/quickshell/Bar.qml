import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property string time

    Variants {
        model: Quickshell.screens

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

            // MarginWrapperManager {
            //     margin: 5
            // }
            WrapperMouseArea {
                anchors.fill: parent
                onClicked: console.log("clicked it ya")

                RowLayout {
                    anchors.fill: parent
                    spacing: 12

                    Rectangle {
                        id: topLeft
                        color: "transparent"
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            id: cpuBar
                            height: 4
                            width: parent.width * CPU.percent
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
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

                        color: "black"
                        width: 350
                        // Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            anchors.centerIn: parent
                            text: Time.time
                            color: "white"
                            font.family: "Berkeley Mono"
                            font.pointSize: 20
                            font.weight: 700
                        }
                    }

                    Rectangle {
                        color: "transparent"
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            id: memBar
                            height: 4
                            width: parent.width * Memory.percent
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
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
