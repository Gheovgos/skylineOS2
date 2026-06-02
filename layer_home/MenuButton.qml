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

    Rectangle {
        id: highlight
        anchors.centerIn: parent
        width: parent.width + vpx(16)
        height: parent.height - vpx(8)
        radius: height / 2
        color: theme.accent
        opacity: selected ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        SequentialAnimation on opacity {
            running: selected
            loops: Animation.Infinite
            NumberAnimation { to: 1.0; duration: 0 }
            NumberAnimation { to: 0.85; duration: 400; easing { type: Easing.OutQuad } }
            NumberAnimation { to: 1.0; duration: 500; easing { type: Easing.InQuad } }
            PauseAnimation { duration: 200 }
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
        color: selected ? "white" : (autoColor ? theme.icon : customColor)
        antialiasing: true
        smooth: true
        cached: true
        Behavior on color { ColorAnimation { duration: 150 } }
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
            top: parent.bottom; topMargin: vpx(6)
            horizontalCenter: parent.horizontalCenter
        }
        opacity: selected ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 75 } }
    }
}