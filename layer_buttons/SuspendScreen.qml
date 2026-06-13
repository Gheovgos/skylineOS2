import QtQuick 2.12

Item {
    id: suspendRoot
    width: parent.width
    height: parent.height
    property int pressCount: 0

    Rectangle {
        anchors.fill: parent
        color: theme.main
    }

    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: vpx(40)
        width: vpx(120)
        height: vpx(40)
        radius: vpx(20)
        color: "#E60012"

        Text {
            text: "PAUSED"
            color: "white"
            font.pixelSize: vpx(20)
            font.bold: true
            font.family: titleFont.name
            anchors.centerIn: parent
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: vpx(40)

        Rectangle {
            width: vpx(180)
            height: vpx(180)
            radius: width / 2
            color: "transparent"
            border.color: "#E60012"
            border.width: vpx(6)
            anchors.horizontalCenter: parent.horizontalCenter

            SequentialAnimation on border.width {
                loops: Animation.Infinite
                NumberAnimation { to: vpx(8); duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: vpx(4); duration: 800; easing.type: Easing.InOutSine }
            }

            Image {
                source: Qt.resolvedUrl("assets/images/navigation/home.svg")
                width: vpx(80)
                height: vpx(80)
                anchors.centerIn: parent
                smooth: true
            }
        }

        Text {
            text: "Press key three times"
            color: theme.text
            font.pixelSize: vpx(24)
            font.family: titleFont.name
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: vpx(24)

            Repeater {
                model: 3
                Rectangle {
                    width: vpx(20)
                    height: vpx(20)
                    radius: vpx(10)
                    color: index < suspendRoot.pressCount ? "#E60012" : "transparent"
                    border.color: index < suspendRoot.pressCount ? "#E60012" : theme.text  // ✅ tema
                    border.width: vpx(2)

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    scale: index < suspendRoot.pressCount ? 1.2 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 150; easing.type: Easing.OutBack }
                    }
                }
            }
        }
    }

    focus: true

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            event.accepted = true;
            suspendRoot.pressCount = 0;
            showHomeScreen();
            return;
        }

        event.accepted = true;
        suspendRoot.pressCount++;

        if (suspendRoot.pressCount >= 3) {
            suspendRoot.pressCount = 0;
            showHomeScreen();
        }
    }
}