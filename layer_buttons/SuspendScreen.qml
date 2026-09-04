import QtQuick 2.12
import QtGraphicalEffects 1.12
import "qrc:/qmlutils" as PegasusUtils
import "../utils.js" as Utils
import "../layer_home"

Item {
    id: suspendRoot
    width: parent.width
    height: parent.height
    property int pressCount: 0
    property int requiredPresses: 3
    property int tickCount: 32
    property real fillRatio: pressCount / requiredPresses

    focus: true

    // Sfondo
    Rectangle {
        anchors.fill: parent
        color: theme.main
    }

    // Orbite ambientali che fluttuano lentamente
    Repeater {
        model: 3
        Rectangle {
            id: orb
            property real baseX: [0.18, 0.82, 0.5][index] * suspendRoot.width
            property real baseY: [0.75, 0.25, 0.9][index] * suspendRoot.height
            width: [140, 100, 170][index] ? vpx([140, 100, 170][index]) : vpx(120)
            height: width
            radius: width / 2
            color: theme.accent
            opacity: 0.06
            x: baseX - width / 2
            y: baseY - height / 2

            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: orb.baseY - orb.height / 2 - vpx(24); duration: 3200 + index * 600; easing.type: Easing.InOutSine }
                NumberAnimation { to: orb.baseY - orb.height / 2 + vpx(24); duration: 3200 + index * 600; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.11; duration: 2600 + index * 400; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.05; duration: 2600 + index * 400; easing.type: Easing.InOutSine }
            }
        }
    }

    // Pillola di stato: ora + batteria, stile "glass"
    Rectangle {
        id: statusPill
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: vpx(48)
        }
        width: statusRow.width + vpx(32)
        height: vpx(44)
        radius: height / 2
        color: theme.button
        opacity: 0.85

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: vpx(3)
            radius: 12
            samples: 20
            color: "#30000000"
        }

        Row {
            id: statusRow
            anchors.centerIn: parent
            spacing: vpx(12)

            Text {
                id: suspendTime
                text: Qt.formatTime(new Date(), settings.timeFormat === "12hr" ? "h:mmap" : "hh:mm")
                color: theme.text
                font.family: titleFont.name
                font.bold: true
                font.pixelSize: vpx(20)
                anchors.verticalCenter: parent.verticalCenter

                Timer {
                    interval: 30000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: suspendTime.text = Qt.formatTime(new Date(), settings.timeFormat === "12hr" ? "h:mmap" : "hh:mm")
                }
            }

            Rectangle {
                width: vpx(3)
                height: vpx(16)
                radius: width / 2
                color: theme.icon
                opacity: 0.25
                anchors.verticalCenter: parent.verticalCenter
                visible: !isNaN(api.device.batteryPercent)
            }

            BatteryIcon {
                width: vpx(28)
                height: width / 1.5
                level: isNaN(api.device.batteryPercent) ? 0 : parseInt(api.device.batteryPercent * 100)
                visible: !isNaN(api.device.batteryPercent)
                anchors.verticalCenter: parent.verticalCenter
                layer.enabled: true
                layer.effect: ColorOverlay { color: theme.icon }
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: vpx(40)

        // Anello radiale con luna crescente al centro
        Item {
            id: ringWrap
            width: vpx(220)
            height: width
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: suspendRoot.tickCount
                Rectangle {
                    property real angle: (index / suspendRoot.tickCount) * 360 - 90
                    property real ringRadius: ringWrap.width / 2 - vpx(6)
                    property bool lit: (index / suspendRoot.tickCount) < suspendRoot.fillRatio

                    width: vpx(4)
                    height: vpx(14)
                    radius: vpx(2)
                    antialiasing: true
                    color: lit ? theme.accent : theme.icon
                    opacity: lit ? 1.0 : 0.2
                    scale: lit ? 1.15 : 1.0

                    x: ringWrap.width / 2 + ringRadius * Math.cos(angle * Math.PI / 180) - width / 2
                    y: ringWrap.height / 2 + ringRadius * Math.sin(angle * Math.PI / 180) - height / 2
                    rotation: angle + 90
                    transformOrigin: Item.Center

                    Behavior on color { ColorAnimation { duration: 180 } }
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                }
            }

            // Nucleo centrale
            Rectangle {
                id: moonCore
                anchors.centerIn: parent
                width: vpx(140)
                height: width
                radius: width / 2
                color: theme.button

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 0
                    verticalOffset: vpx(4)
                    radius: 20
                    samples: 24
                    color: "#40000000"
                }

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.03; duration: 1800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
                }

                Item {
                    anchors.centerIn: parent
                    width: vpx(64)
                    height: width

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: theme.accent
                    }
                    Rectangle {
                        width: parent.width
                        height: parent.height
                        radius: width / 2
                        color: theme.button
                        x: vpx(20)
                        y: -vpx(6)
                    }
                }

            }
        }

        Text {
            text: suspendRoot.pressCount
            color: theme.icon
            opacity: 0.65
            font.pixelSize: vpx(16)
            font.family: titleFont.name
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    SequentialAnimation {
        id: pressFeedback
        NumberAnimation { target: moonCore; property: "scale"; to: 0.92; duration: 80 }
        NumberAnimation { target: moonCore; property: "scale"; to: 1.0; duration: 140; easing.type: Easing.OutBack }
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            event.accepted = true;
            suspendRoot.pressCount = 0;
            showHomeScreen();
            return;
        }

        event.accepted = true;
        suspendRoot.pressCount++;
        pressFeedback.start();

        if (suspendRoot.pressCount >= suspendRoot.requiredPresses) {
            suspendRoot.pressCount = 0;
            showHomeScreen();
        }
    }
}