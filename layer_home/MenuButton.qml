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

    property string clickAnim: "pop"

    function animate() {
        popAnim.stop();
        spinAnim.stop();
        wiggleAnim.stop();
        bounceAnim.stop();
        shakeAnim.stop();
        pulseAnim.stop();
        iconHolder.scale = 1;
        iconHolder.rotation = 0;
        iconHolder.opacity = 1;
        iconShift.x = 0;
        iconShift.y = 0;
        if (clickAnim === "spin")
            spinAnim.start();
        else if (clickAnim === "wiggle")
            wiggleAnim.start();
        else if (clickAnim === "bounce")
            bounceAnim.start();
        else if (clickAnim === "shake")
            shakeAnim.start();
        else if (clickAnim === "pulse")
            pulseAnim.start();
        else
            popAnim.start();
    }

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

        Item {
            id: iconHolder
            anchors.centerIn: parent
            width: vpx(28)
            height: vpx(28)
            transform: Translate {
                id: iconShift
            }

            Image {
                id: menuIcon
                anchors.fill: parent
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

        SequentialAnimation {
            id: popAnim
            NumberAnimation {
                target: iconHolder
                property: "scale"
                to: 1.35
                duration: 90
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: iconHolder
                property: "scale"
                to: 1.0
                duration: 220
                easing.type: Easing.OutBack
            }
        }

        NumberAnimation {
            id: spinAnim
            target: iconHolder
            property: "rotation"
            from: 0
            to: 360
            duration: 500
            easing.type: Easing.OutCubic
        }

        SequentialAnimation {
            id: wiggleAnim
            NumberAnimation {
                target: iconHolder
                property: "rotation"
                to: -14
                duration: 70
            }
            NumberAnimation {
                target: iconHolder
                property: "rotation"
                to: 14
                duration: 110
            }
            NumberAnimation {
                target: iconHolder
                property: "rotation"
                to: -8
                duration: 90
            }
            NumberAnimation {
                target: iconHolder
                property: "rotation"
                to: 0
                duration: 80
            }
        }

        SequentialAnimation {
            id: bounceAnim
            NumberAnimation {
                target: iconShift
                property: "y"
                to: -vpx(10)
                duration: 110
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: iconShift
                property: "y"
                to: 0
                duration: 260
                easing.type: Easing.OutBounce
            }
        }

                SequentialAnimation {
            id: shakeAnim
            NumberAnimation {
                target: iconShift
                property: "x"
                to: -vpx(6)
                duration: 50
            }
            NumberAnimation {
                target: iconShift
                property: "x"
                to: vpx(6)
                duration: 90
            }
            NumberAnimation {
                target: iconShift
                property: "x"
                to: -vpx(3)
                duration: 70
            }
            NumberAnimation {
                target: iconShift
                property: "x"
                to: 0
                duration: 60
            }
        }

        ParallelAnimation {
            id: pulseAnim
            SequentialAnimation {
                NumberAnimation {
                    target: iconHolder
                    property: "scale"
                    to: 1.5
                    duration: 140
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: iconHolder
                    property: "scale"
                    to: 1.0
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }
            SequentialAnimation {
                NumberAnimation {
                    target: iconHolder
                    property: "opacity"
                    to: 0.4
                    duration: 140
                }
                NumberAnimation {
                    target: iconHolder
                    property: "opacity"
                    to: 1.0
                    duration: 200
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.animate();
            root.clicked();
        }
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
