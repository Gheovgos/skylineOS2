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

            property real savedX: 0
            property real savedY: 0

            onExpandedChanged: {
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

                x: expanded ? (screenwidth - width) / 2 : wrapper.savedX
                y: expanded ? (screenheight - height) / 2 : wrapper.savedY
                z: 10

                radius: vpx(24)
                color: theme.button
                visible: expanded
                opacity: expanded ? 1 : 0

                border.width: expanded && gameData && gameData.favorite ? vpx(3) : 0
                border.color: theme.accent
                Behavior on border.width {
                    NumberAnimation {
                        duration: 200
                    }
                }

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 0
                    verticalOffset: 0
                    radius: expanded && gameData && gameData.favorite ? 24 : 8
                    samples: 32
                    color: expanded && gameData && gameData.favorite ? theme.accent : "#50000000"
                    Behavior on radius {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }

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

                // Background screenshot
                Image {
                    parent: homeScreenContainer
                    anchors.fill: parent
                    source: gameData ? (gameData.assets.background || gameData.assets.screenshots[0] || "") : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    visible: source !== "" && expanded
                    opacity: 0.15
                    z: 8

                    layer.enabled: true
                    layer.effect: FastBlur {
                        radius: 32
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

                    // TITLE
                    Text {
                        id: panelTitle
                        text: gameData ? gameData.title : ""
                        color: theme.text
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.045)
                        font.bold: true
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            rightMargin: vpx(48)
                        }
                    }

                    // Subtitle
                    Row {
                        id: panelSubtitle
                        spacing: vpx(6)
                        anchors {
                            top: panelTitle.bottom
                            topMargin: vpx(8)
                            left: parent.left
                        }
                        visible: gameData && gameData.genreList && gameData.genreList.length > 0

                        // Total Players
                        Rectangle {
                            width: playersRow.width + vpx(16)
                            height: vpx(24)
                            radius: height / 2
                            color: theme.main
                            visible: gameData && gameData.players > 0

                            Row {
                                id: playersRow
                                anchors.centerIn: parent
                                spacing: vpx(4)
                                Image {
                                    source: "../assets/images/navigation/player.svg"
                                    width: vpx(18)
                                    height: vpx(18)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: gameData ? gameData.players : ""
                                    color: theme.icon
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.017)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        property var pillColors: ["#3B82F6", "#8B5CF6", "#10B981", "#F59E0B", "#EF4444"]

                        Repeater {
                            model: gameData ? gameData.genreList : []
                            Rectangle {
                                height: vpx(22)
                                width: genreText.width + vpx(12)
                                radius: height / 2
                                color: panelSubtitle.pillColors[index % panelSubtitle.pillColors.length]
                                opacity: 0.85

                                Text {
                                    id: genreText
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: "white"
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.017)
                                    font.bold: true
                                }
                            }
                        }
                    }

                    // SEPARATOR HOR
                    Rectangle {
                        id: divider
                        anchors {
                            top: panelSubtitle.bottom
                            topMargin: vpx(16)
                            left: parent.left
                            right: parent.right
                        }
                        height: 1
                        color: theme.text
                        opacity: 0.12
                    }

                    // BADGE (TODO BETTER)
                    Rectangle {
                        id: favBadge
                        width: vpx(32)
                        height: vpx(32)
                        radius: width / 2
                        color: gameData && gameData.favorite ? theme.accent : "transparent"
                        border.color: gameData && gameData.favorite ? theme.accent : theme.text
                        border.width: vpx(2)
                        opacity: gameData && gameData.favorite ? 1 : 0.35
                        anchors {
                            top: parent.top
                            right: parent.right
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }

                        Image {
                            id: favIcon
                            source: "../assets/images/heart_filled.png"
                            anchors {
                                fill: parent
                                margins: vpx(7)
                            }
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }
                        ColorOverlay {
                            anchors.fill: favIcon
                            source: favIcon
                            color: gameData && gameData.favorite ? "white" : theme.text
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
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

                    // Content Area
                    Item {
                        id: contentArea
                        anchors {
                            top: divider.bottom
                            topMargin: vpx(20)
                            left: parent.left
                            right: parent.right
                            bottom: playButton.top
                            //bottomMargin: vpx(20)
                        }

                        // Left Column: cover + stats
                        Item {
                            id: leftCol
                            width: Math.round(parent.width * 0.26)
                            anchors {
                                top: parent.top
                                left: parent.left
                                bottom: parent.bottom
                            }
                            clip: true

                            Column {
                                width: parent.width
                                spacing: vpx(14)

                                // Cover with shadow
                                Rectangle {
                                    width: parent.width
                                    height: width
                                    radius: vpx(16)
                                    color: theme.main

                                    layer.enabled: enableDropShadows
                                    layer.effect: DropShadow {
                                        transparentBorder: true
                                        horizontalOffset: 0
                                        verticalOffset: vpx(6)
                                        radius: 16
                                        samples: 32
                                        color: "#50000000"
                                    }

                                    Image {
                                        id: coverImage
                                        anchors {
                                            fill: parent
                                            margins: vpx(0)
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
                                                radius: vpx(16)
                                                visible: false
                                            }
                                        }
                                    }
                                    // Placeholder
                                    Text {
                                        anchors.centerIn: parent
                                        text: gameData ? (gameData.title.charAt(0)) : "?"
                                        color: theme.icon
                                        font.family: titleFont.name
                                        font.pixelSize: Math.round(screenheight * 0.06)
                                        font.bold: true
                                        visible: coverImage.status !== Image.Ready
                                    }
                                }

                                // Stats pill row
                                Row {
                                    spacing: vpx(8)
                                    visible: {
                                        var pt = gameData ? gameData.playTime : 0;
                                        var manual = (gameData && gameData.extra) ? (gameData.extra.playtime || 0) : 0;
                                        return pt > 0 || manual > 0;
                                    }

                                    Rectangle {
                                        height: vpx(28)
                                        width: statRow.width + vpx(16)
                                        radius: height / 2
                                        color: theme.main

                                        Row {
                                            id: statRow
                                            anchors.centerIn: parent
                                            spacing: vpx(6)

                                            Text {
                                                text: "⏱"
                                                font.pixelSize: Math.round(screenheight * 0.018)
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text {
                                                text: {
                                                    if (gameData.extra.playtime)
                                                        return new Date(gameData.extra.playtime[0] * 1000).getUTCHours() + ":" + new Date(gameData.extra.playtime[0] * 1000).getUTCMinutes() + ":" + new Date(gameData.extra.playtime[0] * 1000).getUTCSeconds();
                                                    else
                                                        return new Date(gameData.playTime * 1000).getUTCHours() + ":" + new Date(gameData.playTime * 1000).getUTCMinutes() + ":" + new Date(gameData.playTime * 1000).getUTCSeconds();
                                                }
                                                color: theme.text
                                                font.family: titleFont.name
                                                font.pixelSize: Math.round(screenheight * 0.018)
                                                font.bold: true
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }

                                    // Developer
                                    Rectangle {
                                        width: devText.width + vpx(16)
                                        height: vpx(24)
                                        radius: height / 2
                                        color: theme.main
                                        visible: gameData && gameData.developer !== ""

                                        Text {
                                            id: devText
                                            anchors.centerIn: parent
                                            text: gameData ? (gameData.developer || "") : ""
                                            color: theme.icon
                                            font.family: titleFont.name
                                            font.pixelSize: Math.round(screenheight * 0.017)
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                //Progress
                                Row {
                                    spacing: vpx(8)
                                    visible: gameData && gameData.extra.progress > 0

                                    Rectangle {
                                        height: vpx(28)
                                        width: progressRow.width + vpx(16)
                                        radius: height / 2
                                        color: theme.main

                                        Row {
                                            id: progressRow
                                            anchors.centerIn: parent
                                            spacing: vpx(6)

                                            Image {
                                                source: "../assets/images/navigation/trophy.svg"
                                                width: vpx(20)
                                                height: width
                                            }
                                            Text {
                                                text: gameData.extra.progress + "%"
                                                color: theme.text
                                                font.family: titleFont.name
                                                font.pixelSize: Math.round(screenheight * 0.018)
                                                font.bold: true
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // SEPARATOR
                        Rectangle {
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                left: leftCol.right
                                leftMargin: vpx(24)
                            }
                            width: 1
                            color: theme.text
                            opacity: 0.10
                        }

                        // RIGHT COLUMN: DESCRIPTION, RATING, LAST PLAYED
                        Column {
                            id: rightCol
                            spacing: vpx(12)
                            anchors {
                                top: parent.top
                                left: leftCol.right
                                leftMargin: vpx(40)
                                right: parent.right
                            }

                            // Rating && Completition Percentage
                            Row {
                                spacing: vpx(8)
                                visible: gameData && gameData.rating > 0

                                Text {
                                    text: "★"
                                    color: theme.accent
                                    font.pixelSize: Math.round(screenheight * 0.022)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {

                                    text: gameData ? (gameData.rating * 10).toFixed(1) : ""
                                    color: theme.text
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.022)
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            //

                            Text {
                                text: "Description"
                                color: theme.text
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.022)
                                font.bold: true
                                opacity: 0.5
                                font.letterSpacing: 1.5
                            }

                            Text {
                                text: gameData ? (gameData.description || "No description available.") : ""
                                color: theme.text
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.023)
                                wrapMode: Text.WordWrap
                                width: parent.width
                                maximumLineCount: 7
                                elide: Text.ElideRight
                                lineHeight: 1.4
                            }

                            // Last played
                            Column {
                                spacing: vpx(2)

                                Text {
                                    text: "LAST PLAYED"
                                    color: theme.icon
                                    opacity: 0.45
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.013)
                                    font.letterSpacing: 1.5
                                }

                                Text {
                                    text: {
                                        var d = new Date(gameData.lastPlayed);
                                        if (isNaN(d.getTime()) || d.getFullYear() <= 1970)
                                            return "";
                                        return Qt.formatDate(d, "dd MMM yyyy");
                                    }

                                    color: theme.text
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.020)
                                    font.bold: true
                                }
                            }

                            Column {
                                spacing: vpx(2)

                                property string startDate: (gameData && gameData.extra) ? gameData.extra.startdate : ""
                                property string endDate: (gameData && gameData.extra) ? gameData.extra.enddate : ""

                                visible: gameData && gameData.extra && (gameData.extra.startdate || gameData.extra.enddate)

                                Text {
                                    text: gameData.extra.enddate ? "PLAY PERIOD" : "STARTED"
                                    color: theme.icon
                                    opacity: 0.45
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.013)
                                    font.letterSpacing: 1.5
                                }

                                Text {
                                    text: {
                                        var start = gameData.extra.startdate || "";
                                        var end = gameData.extra.enddate || "";

                                        if (start && end)
                                            return "Started: " + Qt.formatDate(new Date(start), "dd/MM/yyyy") + " Finished: " + Qt.formatDate(new Date(end), "dd/MM/yyyy");

                                        return start;
                                    }

                                    color: theme.text
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.020)
                                    font.bold: true
                                }
                            }
                        }
                    }

                    // PLAY BUTTON
                    Rectangle {
                        id: playButton
                        width: vpx(56)
                        height: vpx(56)
                        radius: width / 2
                        color: theme.accent
                        anchors {
                            bottom: parent.bottom
                            right: parent.right
                        }

                        layer.enabled: enableDropShadows
                        layer.effect: DropShadow {
                            transparentBorder: true
                            horizontalOffset: 0
                            verticalOffset: vpx(4)
                            radius: 12
                            samples: 24
                            color: "#50000000"
                        }

                        Image {
                            id: playIcon
                            source: "../assets/images/navigation/play.svg"
                            width: vpx(20)
                            height: vpx(20)
                            fillMode: Image.PreserveAspectFit
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: vpx(1)
                        }
                        ColorOverlay {
                            anchors.fill: playIcon
                            source: playIcon
                            color: "white"
                        }

                        scale: playMouse.containsMouse ? 1.1 : 1.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                            }
                        }

                        MouseArea {
                            id: playMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                wrapper.expanded = false;
                                anim.start();
                                playGame();
                            }
                        }
                    }
                }

                //Platform
                Image {
                    id: platformIcon

                    width: vpx(28)
                    height: vpx(28)

                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        leftMargin: vpx(18)
                        bottomMargin: vpx(18)
                    }

                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                    z: 20

                    source: {
                        if (!gameData || !gameData.collections || gameData.collections.count === 0)
                            return "";

                        var p = gameData.collections.get(0).shortName;
                        if (!p)
                            return "";

                        return "../assets/images/platforms/" + p + ".svg";
                    }
                }

                Text {
                    id: platformText

                    text: (gameData && gameData.collections && gameData.collections.count > 0) ? gameData.collections.get(0).name : ""

                    anchors {
                        left: platformIcon.right
                        leftMargin: vpx(8)
                        verticalCenter: platformIcon.verticalCenter
                    }

                    color: theme.accent
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.015)
                    font.bold: true
                    z: 20
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
