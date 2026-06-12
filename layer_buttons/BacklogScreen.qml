import QtQuick 2.0

Item {
    id: backlogContainer
    width: parent.width
    height: parent.height

    property var rawData: []

    Rectangle {
        anchors.fill: parent
        color: theme.main
    }

    //=========================================
    // TOP HEADER
    //=========================================
    Rectangle {
        id: header
        width: parent.width
        height: 80
        color: theme.main
        
        Rectangle {
            width: parent.width
            height: 3
            color: "#E60012"
            anchors.bottom: parent.bottom
        }

        Text {
            text: "Backlog"
            color: theme.text
            font.pixelSize: 28
            font.bold: true
            font.family: titleFont.name
            anchors.left: parent.left
            anchors.leftMargin: 40
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // CONTROL BAR (Dice Button Only)
    Row {
        id: controlBar
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.leftMargin: 40
        anchors.topMargin: 20
        spacing: 20
        z: 2

        Rectangle {
            width: 160
            height: 40
            radius: 4
            color: backlogList.count === 0 ? "#555555" : (diceMouseArea.pressed ? theme.press : theme.button)
            border.color: backlogList.count === 0 ? "#555555" : theme.secondary
            border.width: 2

            Row {
                anchors.centerIn: parent
                spacing: 8

                Image {
                    source: Qt.resolvedUrl("../assets/images/navigation/dices.svg")
                    width: 20
                    height: 20
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: backlogList.count === 0 ? 0.4 : 1.0
                }

                Text {
                    text: "Random Game"
                    color: backlogList.count === 0 ? "#888888" : theme.text
                    font.pixelSize: 16
                    font.bold: true
                    font.family: titleFont.name
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: diceMouseArea
                anchors.fill: parent
                enabled: backlogList.count > 0
                onClicked: {
                    var randomIndex = Math.floor(Math.random() * backlogContainer.rawData.length);
                    var pickedGame = backlogContainer.rawData[randomIndex].title;
                    diceResultText.text = "Game: " + pickedGame;
                }
            }
        }

        Text {
            id: diceResultText
            text: ""
            color: "#E60012"
            font.pixelSize: 18
            font.bold: true
            font.family: titleFont.name
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // EMPTY STATE (Shown only if JSON is empty)
    Column {
        id: emptyState
        anchors.centerIn: parent
        spacing: 15
        visible: backlogList.count === 0 
        width: parent.width * 0.6

        Text {
            text: "Your backlog is empty!"
            color: theme.text
            font.pixelSize: 24
            font.bold: true
            font.family: titleFont.name
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Populate your backlog.json file to see your titles here."
            color: theme.icon
            font.pixelSize: 16
            font.family: titleFont.name
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.3
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // TITLES LIST
    ListView {
        id: backlogList
        anchors.top: controlBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        anchors.topMargin: 20
        
        clip: true
        focus: true
        model: 0 

        MouseArea {
            anchors.fill: parent
            onWheel: {
                if (wheel.angleDelta.y > 0) backlogList.decrementCurrentIndex();
                else backlogList.incrementCurrentIndex();
            }
            propagateComposedEvents: true
            onPressed: mouse.accepted = false
        }

        delegate: Item {
            width: backlogList.width
            height: 50 

            Text {
                text: (index + 1) + ". " + (modelData.title || "Unknown Title")
                color: theme.text
                font.pixelSize: 20
                font.bold: true
                font.family: titleFont.name
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 20
            }

            Rectangle {
                width: parent.width - 40
                height: 1
                color: theme.secondary
                opacity: 0.2
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
        
        boundsBehavior: Flickable.DragAndOvershootBounds
    }

    // DATA LOADING FUNCTION
    function loadBacklog() {
        var request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("backlog.json"), true);
        
        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request.status === 200 || request.status === 0) {
                    var data = JSON.parse(request.responseText);
                    backlogContainer.rawData = data;
                    backlogList.model = data;
                } else {
                    console.log("Error loading backlog.json:", request.status);
                }
            }
        }
        request.send();
    }

    Component.onCompleted: {
        loadBacklog();
    }
}