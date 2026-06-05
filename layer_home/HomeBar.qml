import QtQuick 2.15
import QtGraphicalEffects 1.12
import "../global"
import "../Lists"
import "../utils.js" as Utils
import "qrc:/qmlutils" as PegasusUtils

ListView {
    id: homeLayout
    //anchors.fill: parent
    property int _index: 0
    spacing: vpx(24)
    orientation: ListView.Horizontal

    displayMarginBeginning: vpx(107)
    displayMarginEnd: vpx(107)

    preferredHighlightBegin: vpx(0)
    preferredHighlightEnd: vpx(1077)
    highlightRangeMode: ListView.StrictlyEnforceRange // Highlight never moves outside the range
    snapMode: ListView.SnapToItem
    highlightMoveDuration: 100
    highlightMoveVelocity: -1
    keyNavigationWraps: true

    NumberAnimation {
        id: anim
        property: "scale"
        to: 0.7
        duration: 100
    }

    model: gamesListModel
    delegate: homeBarDelegate

    Component {
        id: homeBarDelegate
        Rectangle {
            id: wrapper

            property bool selected: ListView.isCurrentItem
            property var gameData: searchtext ? modelData : listRecent.currentGame(idx)
            property bool isGame: idx >= 0
            property bool expanded: false

            onGameDataChanged: {
                if (selected)
                    updateData();
            }
            onSelectedChanged: {
                if (!selected)
                    expanded = false;
                if (selected)
                    updateData();
            }

            function updateData() {
                currentGame = gameData;
                currentScreenID = idx;
            }

            width: homeLayout.height//isGame ? homeLayout.height : homeLayout.height*0.7
            height: width
            color: "transparent"

            anchors.verticalCenter: parent.verticalCenter

            scale: selected && !expanded ? 1.08 : expanded ? 0 : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                id: expandedPanel

                parent: homeScreenContainer

                width: expanded ? Math.round(screenwidth * 0.75) : wrapper.width
                height: expanded ? Math.round(screenheight * 0.75) : wrapper.height

                x: expanded ? (screenwidth - width) / 2 : wrapper.mapToItem(homeScreenContainer, 0, 0).x
                y: expanded ? (screenheight - height) / 2 : wrapper.mapToItem(homeScreenContainer, 0, 0).y
                z: 10

                radius: vpx(24)
                color: theme.button
                visible: expanded
                opacity: expanded ? 1 : 0

                Behavior on width {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on x {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }

                function formatPlayTime(seconds) {
                    if (!seconds || seconds <= 0)
                        return "0:00";
                    var h = Math.floor(seconds / 3600);
                    var m = Math.floor((seconds % 3600) / 60);
                    return h + ":" + (m < 10 ? "0" + m : m);
                }

                Rectangle {
                    id: dimOverlay
                    parent: homeScreenContainer
                    anchors.fill: parent
                    color: "black"
                    opacity: expanded ? 0.5 : 0
                    visible: expanded
                    z: 9
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 250
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: expanded
                        onClicked: wrapper.expanded = false
                    }
                }

                Item {
                    id: panelContent
                    anchors {
                        fill: parent
                        margins: vpx(32)
                    }
                    opacity: expanded ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }

                    Text {
                        id: panelTitle
                        text: gameData ? gameData.title : ""
                        color: theme.text
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.04)
                        font.bold: true
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: favBadge.left
                            rightMargin: vpx(8)
                        }
                    }

                    Rectangle {
                        id: favBadge
                        width: vpx(36)
                        height: vpx(36)
                        radius: width / 2
                        color: gameData && gameData.favorite ? theme.accent : theme.main
                        anchors {
                            top: parent.top
                            right: parent.right
                        }

                        Image {
                            id: favIcon
                            source: "../assets/images/heart_filled.png"
                            anchors {
                                fill: parent
                                margins: vpx(8)
                            }
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }
                        ColorOverlay {
                            anchors.fill: favIcon
                            source: favIcon
                            color: "white"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (gameData) {
                                    gameData.favorite = !gameData.favorite;
                                    gameData.favorite ? turnOnSfx.play() : turnOffSfx.play();
                                }
                            }
                        }
                    }

                    Item {
                        id: contentArea
                        anchors {
                            top: panelTitle.bottom
                            topMargin: vpx(20)
                            left: parent.left
                            right: parent.right
                            bottom: playButton.top
                            bottomMargin: vpx(16)
                        }

                        Item {
                            id: leftCol
                            width: Math.round(parent.width * 0.28)
                            anchors {
                                top: parent.top
                                left: parent.left
                                bottom: parent.bottom
                            }
                            clip: true

                            Column {
                                width: parent.width
                                spacing: vpx(12)

                                Rectangle {
                                    width: parent.width
                                    height: width
                                    radius: vpx(12)
                                    color: theme.main

                                    Image {
                                        id: coverImage
                                        anchors {
                                            fill: parent
                                            margins: vpx(2)
                                        }
                                        source: gameData ? (gameData.assets.boxFront || "") : ""
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        smooth: true
                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: Rectangle {
                                                width: coverImage.width
                                                height: coverImage.height
                                                radius: vpx(10)
                                                visible: false
                                            }
                                        }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "?"
                                        color: theme.icon
                                        font.pixelSize: Math.round(screenheight * 0.05)
                                        visible: coverImage.status !== Image.Ready
                                    }
                                }

                                Text {
                                    text: gameData && gameData.releaseYear > 0 ? gameData.releaseYear : ""
                                    color: theme.icon
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.022)
                                    visible: gameData && gameData.releaseYear > 0
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }

                                Text {
                                    text: gameData ? gameData.genreList.join(", ") : ""
                                    color: theme.icon
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.022)
                                    visible: text !== ""
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }

                                Text {
                                    text: "playTime raw: " + (gameData.playTime)
                                    color: theme.icon
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.022)
                                    width: parent.width
                                }

                                Text {
                                    text: {
                                        if (!gameData || !gameData.lastPlayed)
                                            return "";
                                        var d = new Date(gameData.lastPlayed);
                                        if (isNaN(d.getTime()) || d.getFullYear() <= 1970)
                                            return "";
                                        return "Ultimo: " + Qt.formatDate(d, "dd/MM/yyyy");
                                    }
                                    color: theme.icon
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.022)
                                    visible: text !== ""
                                    width: parent.width
                                }
                            }
                        }

                        Column {
                            id: rightCol
                            spacing: vpx(16)
                            anchors {
                                top: parent.top
                                left: leftCol.right
                                leftMargin: vpx(32)
                                right: parent.right
                            }

                            Text {
                                text: "Descrizione"
                                color: theme.text
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.03)
                                font.bold: true
                            }
                            Text {
                                text: gameData ? (gameData.description || "") : ""
                                color: theme.icon
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.022)
                                wrapMode: Text.WordWrap
                                width: parent.width
                                maximumLineCount: 6
                                elide: Text.ElideRight
                                visible: text !== ""
                            }
                            Text {
                                text: {
                                    if (!gameData)
                                        return "";
                                    var parts = [];
                                    if (gameData.developer)
                                        parts.push("Sviluppatore: " + gameData.developer);
                                    if (gameData.publisher)
                                        parts.push("Publisher: " + gameData.publisher);
                                    return parts.join("\n");
                                }
                                color: theme.icon
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.022)
                                wrapMode: Text.WordWrap
                                width: parent.width
                                visible: text !== ""
                            }
                            Text {
                                text: gameData && gameData.players > 0 ? "Giocatori: " + gameData.players : ""
                                color: theme.icon
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.022)
                                visible: text !== ""
                            }
                            Text {
                                text: gameData && gameData.rating > 0 ? "Rating: " + Math.round(gameData.rating * 100) + "%" : ""
                                color: theme.icon
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.022)
                                visible: text !== ""
                            }
                        }
                    }

                    Rectangle {
                        id: playButton
                        width: vpx(56)
                        height: vpx(48)  // più stretto senza testo
                        radius: vpx(12)
                        color: theme.accent
                        anchors {
                            bottom: parent.bottom
                            right: parent.right
                        }

                        layer.enabled: enableDropShadows
                        layer.effect: DropShadow {
                            transparentBorder: true
                            horizontalOffset: 0
                            verticalOffset: vpx(3)
                            radius: 8
                            samples: 16
                            color: "#40000000"
                        }

                        Image {
                            id: playIcon
                            source: "../assets/images/navigation/play.svg"
                            width: vpx(22)
                            height: vpx(22)
                            fillMode: Image.PreserveAspectFit
                            anchors.centerIn: parent
                        }
                        ColorOverlay {
                            anchors.fill: playIcon
                            source: playIcon
                            color: "white"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                wrapper.expanded = false;
                                anim.start();
                                playGame();
                            }
                        }
                    }
                }

                Keys.onLeftPressed: {
                    if (expanded)
                        event.accepted = true;
                }
                Keys.onRightPressed: {
                    if (expanded)
                        event.accepted = true;
                }
                Keys.onUpPressed: {
                    if (expanded)
                        event.accepted = true;
                }
                Keys.onDownPressed: {
                    if (expanded)
                        event.accepted = true;
                }
                Keys.onPressed: {
                    if (!expanded)
                        return;
                    event.accepted = true;
                    if (api.keys.isFilters(event) || api.keys.isCancel(event))
                        wrapper.expanded = false;
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        wrapper.expanded = false;
                        anim.start();
                        playGame();
                    }
                }
            }

            Rectangle {
                id: background

                width: isGame ? homeLayout.height : homeLayout.height * 0.7
                height: width

                radius: vpx(24)
                color: theme.button

                layer.enabled: enableDropShadows && !selected
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 0
                    verticalOffset: vpx(4)
                    radius: 16
                    samples: 32
                    color: "#30000000"
                }

                anchors.centerIn: parent
            }

            // Preference order for Game Backgrounds
            property var gameBG: {
                return getGameBackground(gameData, settings.gameBackground);
            }

            Rectangle {
                id: imageMask
                width: isGame ? homeLayout.height : homeLayout.height * 0.7
                height: width
                radius: vpx(24)
                visible: false
                anchors.centerIn: parent
            }

            Image {
                id: gameImage

                width: isGame ? homeLayout.height : homeLayout.height * 0.7
                height: width

                smooth: true
                asynchronous: true

                fillMode: (gameBG == gameData.assets.boxFront) ? Image.PreserveAspectFit : Image.PreserveAspectCrop

                source: gameBG

                sourceSize {
                    width: 256
                    height: 256
                }

                anchors.centerIn: parent

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: imageMask
                }

                Rectangle {
                    id: favicon
                    anchors {
                        right: parent.right
                        rightMargin: vpx(5)
                        top: parent.top
                        topMargin: vpx(5)
                    }

                    width: vpx(32)
                    height: width
                    radius: width / 2
                    color: theme.accent
                    visible: isGame ? gameData.favorite : false

                    Image {
                        id: faviconImage
                        source: "../assets/images/heart_filled.png"
                        asynchronous: true
                        anchors.fill: parent
                        anchors.margins: vpx(7)
                    }

                    ColorOverlay {
                        anchors.fill: faviconImage
                        source: faviconImage
                        color: "white"
                        antialiasing: true
                        smooth: true
                        cached: true
                    }
                }
            }

            //white overlay on screenshot for better logo visibility over screenshot
            Rectangle {
                width: gameImage.width
                height: gameImage.height
                color: "white"
                opacity: 0.15
                visible: logo.source != "" && gameImage.source != ""
            }

            Image {
                id: logo

                anchors.fill: gameImage
                anchors.centerIn: gameImage
                anchors.margins: isGame ? vpx(30) : vpx(60)
                property var logoImage: {
                    if (gameData != null) {
                        if (gameData.collections.get(0).shortName === "retropie")
                            return "";
                        else
                        //gameData.assets.boxFront;
                        if (gameData.collections.get(0).shortName === "steam")
                            return Utils.logo(gameData) ? Utils.logo(gameData) : "";
                        else
                        //root.logo(gameData);
                        if (gameData.assets.tile != "")
                            return "";
                        else if (gameBG == gameData.assets.boxFront)
                            return "";
                        else
                            return gameData.assets.logo;
                    } else {
                        return "";
                    }
                }

                source: gameData ? logoImage : icon //Utils.logo(gameData)
                sourceSize: Qt.size(gameImage.width, gameImage.height)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                visible: gameData.assets.logo && gameBG != gameData.assets.boxFront ? true : false
                // z: 10
            }

            ColorOverlay {
                anchors.fill: logo
                source: logo
                color: theme.icon
                antialiasing: true
                cached: true
                visible: !isGame
            }

            Text {
                text: idx > -1 ? gameData.title : name
                width: gameImage.width
                horizontalAlignment: Text.AlignHCenter
                font.family: titleFont.name
                color: theme.text
                font.pixelSize: Math.round(screenheight * 0.025)
                font.bold: true

                anchors.centerIn: gameImage
                wrapMode: Text.Wrap
                visible: logo.source == "" && gameImage.source == ""
                z: 10
            }

            MouseArea {
                anchors.fill: gameImage
                hoverEnabled: true
                onEntered: {}
                onExited: {}
                onClicked: {
                    if (selected) {
                        if (currentIndex == softCount) {
                            gotoSoftware();
                        } else {
                            anim.start();
                            playGame();//launchGame(currentGame);
                        }
                    } else
                        navSound.play();
                    homeSwitcher.currentIndex = index;
                    homeSwitcher.focus = true;
                    buttonMenu.focus = false;
                }
            }

            Text {
                id: topTitle
                text: idx > -1 ? gameData.title : name
                color: theme.accent
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.035)
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                //clip: true
                //elide: Text.ElideRight

                anchors {
                    horizontalCenter: gameImage.horizontalCenter
                    bottom: gameImage.top
                    bottomMargin: Math.round(screenheight * 0.025)
                }

                opacity: wrapper.ListView.isCurrentItem ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 75
                    }
                }
            }

            Component.onCompleted: {
                if (wordWrap) {
                    if (topTitle.paintedWidth > gameImage.width * 1.70) {
                        topTitle.width = gameImage.width * 1.5;
                    }
                }
            }

            HighlightBorder {
                id: highlightBorder
                width: gameImage.width + vpx(18)//vpx(274)
                height: width//vpx(274)

                anchors.centerIn: parent

                x: vpx(-9)
                y: vpx(-9)
                z: -1

                borderRadius: vpx(30)
                selected: wrapper.ListView.isCurrentItem
            }
        }
    }

    Keys.onLeftPressed: {
        navSound.play();
        decrementCurrentIndex();
    }
    Keys.onRightPressed: {
        navSound.play();
        incrementCurrentIndex();
    }

    Keys.onUpPressed: {
        borderSfx.play();
    }

    Keys.onDownPressed: {
        _index = currentIndex;
        navSound.play();
        themeButton.focus = true;
        homeSwitcher.currentIndex = -1;
    }

    function gotoSoftware() {
        showSoftwareScreen();
    }

    //TODO Software screen is always at index 12, but would hopefully not exist/be visible if there are less than 12 titles
    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (currentIndex == softCount) {
                gotoSoftware();
            } else {
                anim.start();
                playGame();//launchGame(currentGame);
            }
        }

        if (api.keys.isDetails(event)) {
            event.accepted = true;
            if (currentGame.favorite) {
                turnOffSfx.play();
            } else {
                turnOnSfx.play();
            }
            currentGame.favorite = !currentGame.favorite;
            return;
        }

        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            var item = homeLayout.currentItem;
            if (item)
                item.expanded = !item.expanded;
            return;
        }
    }
}
