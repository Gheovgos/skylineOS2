import QtQuick 2.8
import QtGraphicalEffects 1.12
import "qrc:/qmlutils" as PegasusUtils

Item {
    id: root

    property bool selected: focus
    property real borderWidth: vpx(4)
    property string label: "No label"
    property string icon: "../assets/images/allsoft_icon.svg"
    property bool autoColor: true
    property string customColor: "transparent"
    signal clicked

    width: vpx(56)
    height: vpx(56)

    Item {
        id: visual
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        scale: selected ? 1.12 : 1.0
        Behavior on scale {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutBack
            }
        }

        Rectangle {
            id: baseCircle
            anchors.fill: parent
            radius: width / 2
            color: selected ? theme.main : "transparent"
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }

        Rectangle {
            id: ring
            anchors.centerIn: parent
            width: parent.width + vpx(10)
            height: width
            radius: width / 2
            color: "transparent"
            border.width: vpx(4)
            border.color: theme.accent
            opacity: selected ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: parent.border.width
                border.color: "white"
                opacity: 0
                SequentialAnimation on opacity {
                    running: selected
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.5
                        duration: 400
                        easing {
                            type: Easing.OutQuad
                        }
                    }
                    NumberAnimation {
                        to: 0
                        duration: 500
                        easing {
                            type: Easing.InQuad
                        }
                    }
                    PauseAnimation {
                        duration: 200
                    }
                }
            }
        }

        Image {
            id: menuIcon
            anchors.centerIn: parent
            width: vpx(28)
            height: vpx(28)
            source: icon
            sourceSize: Qt.size(width, height)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
        }

        ColorOverlay {
            anchors.fill: menuIcon
            source: menuIcon
            color: selected ? theme.accent : (autoColor ? theme.icon : customColor)
            antialiasing: true
            smooth: true
            cached: true
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
        hoverEnabled: true
    }

    Text {
        id: titleText
        text: label
        color: theme.accent
        font.family: titleFont.name
        font.pixelSize: Math.round(screenheight * 0.0277)
        font.bold: false
        anchors {
            top: parent.bottom
            topMargin: vpx(16)
            horizontalCenter: parent.horizontalCenter
        }
        opacity: selected ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 75
            }
        }
    }
}
