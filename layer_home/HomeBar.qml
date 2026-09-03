import QtQuick 2.15
import QtGraphicalEffects 1.12
import QtMultimedia 5.9
import "../global"
import "../Lists"
import "../utils.js" as Utils
import "qrc:/qmlutils" as PegasusUtils

ListView {
    id: homeLayout
    //anchors.fill: parent
    property bool anyExpanded: false
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
    property real cardScale: parseFloat(settings.homeCardSize) / 35.0

    NumberAnimation {
        id: anim
        property: "scale"
        to: 0.7
        duration: 100
    }

    model: gamesListModel
    delegate: homeBarDelegate

    boundsBehavior: Flickable.StopAtBounds
    boundsMovement: Flickable.StopAtBounds

    Component {
        id: homeBarDelegate
        Rectangle {
            id: wrapper

            property bool selected: ListView.isCurrentItem
            property var gameData: searchtext ? modelData : listRecent.currentGame(idx)
            property bool isGame: idx >= 0
            property bool expanded: false

            property real savedX: 0
            property real savedY: 0

            onExpandedChanged: {
                homeLayout.anyExpanded = expanded;
                if (expanded) {
                    var pos = wrapper.mapToItem(homeScreenContainer, 0, 0);
                    savedX = pos.x;
                    savedY = pos.y;
                }
            }

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

            width: homeLayout.height * homeLayout.cardScale
            height: width
            color: "transparent"

            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            scale: selected && !expanded ? 1.08 : expanded ? 0 : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                id: background

                width: isGame ? homeLayout.height : homeLayout.height * 0.7
                height: width

                radius: vpx(24)
                color: theme.button

                anchors.centerIn: parent
            }

            property var cardBG: {
                if (!gameData || !isGame)
                    return "";
                switch (settings.gameBackground) {
                case "Screenshot":
                    return gameData.assets.screenshots[0] || gameData.assets.background || "";
                case "Fanart":
                    return gameData.assets.background || gameData.assets.screenshots[0] || "";
                case "Boxart":
                    return gameData.assets.background || gameData.assets.screenshots[0] || "";
                default:
                    return "";
                }
            }

            property var gameBG: gameData ? (gameData.assets.boxFront || gameData.assets.tile || "") : ""

            Rectangle {
                id: imageMask
                width: isGame ? homeLayout.height : homeLayout.height * 0.7
                height: width
                radius: vpx(24)
                visible: false
                anchors.centerIn: parent
            }

            AnimatedImage {
                id: gameImage
                playing: true

                width: isGame ? homeLayout.height : homeLayout.height * 0.7
                height: width

                smooth: true
                asynchronous: true

                fillMode: Image.PreserveAspectFit

                source: gameBG

                /* sourceSize {
                    width: 512
                    height: 512
                } */

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

                onPressAndHold: {
                    var item = homeLayout.currentItem;
                    if (item)
                        openGameDetail(item, item.gameData);
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
        profileButton.focus = true;
        homeSwitcher.currentIndex = -1;
    }

    Keys.onDownPressed: {
        _index = currentIndex;
        navSound.play();
        infoButton.focus = true;
        homeSwitcher.currentIndex = -1;
    }

    function gotoSoftware() {
        showSoftwareScreen();
    }

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

        if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (currentGame && currentIndex !== softCount)
                requestHideApp(currentGame.title);
            return;
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
                openGameDetail(item, item.gameData);
            return;
        }
    }
}
