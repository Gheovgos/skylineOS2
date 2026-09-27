import QtQuick 2.15
import QtQuick.Window 2.15

Item {
    id: debugRoot

    property int screenCount: Qt.application.screens.length

    onScreenCountChanged: {
        console.log("[SecondScreenDebug] screenCount cambiato:", screenCount);
        for (var i = 0; i < Qt.application.screens.length; i++) {
            var s = Qt.application.screens[i];
            console.log("[SecondScreenDebug] screen", i, "name:", s.name, "size:", s.width + "x" + s.height);
        }
    }

    Component.onCompleted: {
        console.log("[SecondScreenDebug] screenCount iniziale:", screenCount);
        for (var i = 0; i < Qt.application.screens.length; i++) {
            var s = Qt.application.screens[i];
            console.log("[SecondScreenDebug] screen", i, "name:", s.name, "size:", s.width + "x" + s.height);
        }
    }

    Window {
        id: debugWindow
        visible: debugRoot.screenCount > 1
        screen: debugRoot.screenCount > 1 ? Qt.application.screens[1] : Qt.application.screens[0]
        width: 400
        height: 300
        color: "#202020"
        title: "Pegasus Second Screen Debug"

        Text {
            anchors.centerIn: parent
            text: "Secondo schermo rilevato!\n" + debugRoot.screenCount + " schermi totali"
            color: "white"
            font.pixelSize: 24
            horizontalAlignment: Text.AlignHCenter
        }
    }
}