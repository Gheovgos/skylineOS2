import QtQuick 2.15
import QtGraphicalEffects 1.0
import "../global"
import "../Lists"
import "../layer_help"
import "../utils.js" as Utils
import "qrc:/qmlutils" as PegasusUtils

FocusScope {

    property int numcolumns: widescreen ? 6 : 5
    property int idx: 0
    // "By Time Last Played" "By Title" "By Total Play Time"
    property var sortTitle: {
        switch (sortByIndex) {
        case 0:
            return "By Time Last Played";
        case 1:
            return "By Total Play Time";
        case 2:
            return "By Title";
        case 3:
            return "By Publisher";
        case 4:
            return "Favorities";
        default:
            return "";
        }
    }

    function processButtonArt(buttonModel) {
        var i;
        for (i = 0; buttonModel.length; i++) {
            if (buttonModel[i].name().includes("Gamepad")) {
                var buttonValue = buttonModel[i].key.toString(16);
                return buttonValue.substring(buttonValue.length - 1, buttonValue.length);
            }
        }
    }

    Item {
        id: softwareScreenContainer
        property bool expandedVisible: false

        onExpandedVisibleChanged: {
            if (!expandedVisible)
                gameGrid.focus = true;
        }

        anchors.fill: parent
        anchors {
            left: parent.left
            leftMargin: screenmargin
            right: parent.right
            rightMargin: screenmargin
        }

        Keys.onPressed: {
            if (event.isAutoRepeat)
                return;

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

            if (api.keys.isFilters(event)) {
                event.accepted = true;
                softwareScreenContainer.expandedVisible = !softwareScreenContainer.expandedVisible;
                return;
            }
            if (api.keys.isDetails(event)) {
                event.accepted = true;
                return;
            }
            if (api.keys.isCancel(event)) {
                event.accepted = true;
                showHomeScreen();
                return;
            }
            if (api.keys.isFilters(event) && !event.isAutoRepeat) {
                event.accepted = true;
                if (softwareScreenContainer.expandedVisible) {
                    softwareScreenContainer.expandedVisible = false;  // chiude panel
                } else {
                    softwareScreenContainer.expandedVisible = true;   // apre panel
                }
                return;
            }
            // Cycle collection forward
            if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
                event.accepted = true;
                turnOnSfx.play();
                if (currentCollection < api.collections.count - 1) {
                    nextCollection++;
                } else {
                    nextCollection = -1;
                }
            }

            // Cycle collection back
            if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
                event.accepted = true;
                turnOffSfx.play();
                if (currentCollection == -1) {
                    nextCollection = api.collections.count - 1;
                } else {
                    nextCollection--;
                }
            }
        }

        SequentialAnimation {
            id: na
            ColorAnimation {
                target: sortButton
                property: "color"
                from: sortButton.color
                to: theme.press
                duration: 100
                easing.type: Easing.OutQuad
            }
            ColorAnimation {
                target: sortButton
                property: "color"
                from: theme.press
                to: sortButton.color
                duration: 200
                easing.type: Easing.InQuad
            }
        }

        // Top bar
        Item {
            id: topBar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.right: parent.right
            height: Math.round(screenheight * 0.1222)
            z: 5

            Image {
                id: headerIcon
                width: Math.round(screenheight * 0.0611)
                height: width
                source: "../assets/images/allsoft_icon.svg"
                sourceSize.width: vpx(128)
                sourceSize.height: vpx(128)

                anchors {
                    top: parent.top
                    topMargin: Math.round(screenheight * 0.0416)
                    left: parent.left
                    leftMargin: vpx(38)
                }

                Text {
                    id: collectionTitle
                    text: currentCollection == -1 ? "All Software" : api.collections.get(currentCollection).name
                    color: theme.text
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.0277)
                    font.bold: true
                    anchors {
                        verticalCenter: headerIcon.verticalCenter
                        left: parent.right
                        leftMargin: vpx(12)
                    }
                }
            }

            // Nintendo's Sort Options: "By Time Last Played", "By Total Play Time", "By Title", "By Publisher"
            Rectangle {
                id: sortButton

                width: sortTypeTxt.contentWidth + vpx(90)
                height: Math.round(screenheight * 0.0611)
                color: theme.main

                anchors {
                    top: parent.top
                    topMargin: Math.round(screenheight * 0.0416)
                    right: parent.right
                    rightMargin: vpx(23)
                }

                Image {
                    id: sortIcon
                    width: Math.round(screenheight * 0.04)
                    height: width
                    source: "../assets/images/navigation/" + processButtonArt(api.keys.filters) + ".svg"
                    sourceSize.width: 64
                    sourceSize.height: 64
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: vpx(10)
                    }
                }

                ColorOverlay {
                    anchors.fill: sortIcon
                    source: sortIcon
                    color: theme.text
                    cached: true
                }

                Text {
                    id: sortTypeTxt
                    text: sortTitle

                    anchors {
                        left: sortIcon.right
                        leftMargin: vpx(5)
                        rightMargin: vpx(17)
                        verticalCenter: sortIcon.verticalCenter
                    }

                    color: theme.text
                    font.family: titleFont.name
                    font.weight: Font.Thin
                    font.pixelSize: Math.round(screenheight * 0.02)
                    horizontalAlignment: Text.Right
                }

                Image {
                    id: sortArrow
                    width: Math.round(screenheight * 0.02)
                    height: width
                    source: "../assets/images/navigation/sort_arrow.png"
                    sourceSize.width: 64
                    sourceSize.height: 64
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: sortTypeTxt.right
                        leftMargin: vpx(10)
                    }
                }

                ColorOverlay {
                    anchors.fill: sortArrow
                    source: sortArrow
                    color: theme.text
                    cached: true
                }
            }

            MouseArea {
                anchors.fill: sortButton
                hoverEnabled: true
                onEntered: {}
                onExited: {}
                onClicked: {
                    na.running = true;
                    cycleSort();
                }
            }

            ColorOverlay {
                anchors.fill: headerIcon
                source: headerIcon
                color: theme.text
                cached: true
            }

            MouseArea {
                anchors.fill: headerIcon
                hoverEnabled: true
                onEntered: {}
                onExited: {}
                onClicked: {}
            }

            // Line
            Rectangle {
                y: parent.height - vpx(1)
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: theme.secondary
            }
        }

        // Grid masks (better performance than using clip: true)
        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                right: parent.right
            }
            color: theme.main
            height: topBar.height
            z: 4
        }

        // Game grid
        GridView {
            id: gameGrid
            focus: true

            NumberAnimation {
                id: anim
                property: "scale"
                to: 0.7
                duration: 100
            }

            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    anim.start();
                    playSoftware();
                }

                if (api.keys.isFilters(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    softwareScreenContainer.expandedVisible = true;
                }

                if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
    event.accepted = true;
    requestHideApp(currentGame.title);
    return;
}
            }

            Keys.onUpPressed: {
                navSound.play();
                moveCurrentIndexUp();
            }
            Keys.onDownPressed: {
                navSound.play();
                moveCurrentIndexDown();
            }
            Keys.onLeftPressed: {
                navSound.play();
                moveCurrentIndexLeft();
            }
            Keys.onRightPressed: {
                navSound.play();
                moveCurrentIndexRight();
            }

            onCurrentIndexChanged: {
                currentGameIndex = currentIndex;
                return;
            }

            anchors {
                left: parent.left
                leftMargin: vpx(63)
                top: topBar.bottom
                right: parent.right
                rightMargin: vpx(63)
                bottom: parent.bottom
            }
            topMargin: Math.round(screenheight * 0.12)
            bottomMargin: Math.round(screenheight * 0.12)

            cellWidth: width / numcolumns
            cellHeight: cellWidth
            preferredHighlightBegin: Math.round(screenheight * 0.1388)
            preferredHighlightEnd: Math.round(screenheight * 0.6527)
            highlightRangeMode: ListView.ApplyRange//StrictlyEnforceRange // Highlight never moves outside the range
            snapMode: ListView.NoSnap
            highlightMoveDuration: 100//200 //150 is default

            model: softwareList[sortByIndex].games //api.collections.get(collectionIndex).games
            delegate: gameGridDelegate

            Component {
                id: gameGridDelegate

                Item {
                    id: delegateContainer
                    property bool selected: delegateContainer.GridView.isCurrentItem
                    onSelectedChanged: {
                        if (selected)
                            updateData();
                    }

                    function updateData() {
                        currentGame = modelData;
                    }

                    width: gameGrid.cellWidth - vpx(10)
                    height: width
                    z: selected ? 10 : 0

                    // Preference order for Game Backgrounds
                    property var gameBG: modelData ? (modelData.assets.boxFront || modelData.assets.tile || "") : ""

                    Image {
                        id: gameImage
                        width: parent.width
                        height: parent.height
                        asynchronous: true
                        smooth: true
                        source: gameBG // modelData.collections.get(0).shortName === "steam" ? modelData.assets.screenshot : gameBG
                        sourceSize {
                            width: 256
                            height: 256
                        }
                        fillMode: (gameBG == modelData.assets.boxFront) ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                        layer.enabled: enableDropShadows && !selected //FIXME: disabled because it blurs the gameImages.
                        layer.effect: DropShadow {
                            transparentBorder: true
                            horizontalOffset: 0
                            verticalOffset: 0
                            color: "#4D000000"
                            radius: 3.0
                            samples: 6
                            z: -200
                        }
                    }

                    //white overlay on screenshot for better logo visibility over screenshot
                    Rectangle {
                        width: parent.width
                        height: parent.height
                        color: "white"
                        opacity: 0.15
                        visible: logo.source != "" && gameImage.source != ""
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
                        visible: modelData.favorite
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
                            color: "white" //theme.icon
                            antialiasing: true
                            smooth: true
                            cached: true
                        }
                    }

                    // Logo
                    Image {
                        id: logo

                        width: gameImage.width
                        height: gameImage.height
                        anchors {
                            fill: parent
                            margins: vpx(6)
                        }

                        asynchronous: true

                        property var logoImage: {
                            if (modelData != null) {
                                if (modelData.collections.get(0).shortName === "retropie")
                                    return "";
                                else
                                //modelData.assets.boxFront;
                                if (modelData.collections.get(0).shortName === "steam")
                                    return Utils.logo(modelData) ? Utils.logo(modelData) : "";
                                else
                                //root.logo(modelData);
                                if (modelData.assets.tile != "")
                                    return "";
                                else
                                    return modelData.assets.logo;
                            } else {
                                return "";
                            }
                        }

                        //opacity: 0
                        source: modelData ? logoImage || "" : "" //modelData.assets.logo ? modelData.assets.logo : ""
                        sourceSize {
                            width: 256
                            height: 256
                        }
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: modelData.assets.logo && gameBG != modelData.assets.boxFront ? true : false
                        z: 8
                    }

                    MouseArea {
                        anchors.fill: gameImage
                        hoverEnabled: true
                        onEntered: {}
                        onExited: {}
                        onClicked: {
                            if (selected) {
                                anim.start();
                                playSoftware();
                            } else
                                navSound.play();
                            gameGrid.currentIndex = index;
                        }
                    }

                    //NumberAnimation { id: anim; property: "scale"; to: 0.7; duration: 100 }
                    //NumberAnimation { property: "scale"; to: 1.0; duration: 100 }

                    Rectangle {
                        id: outerborder
                        width: gameImage.width
                        height: gameImage.height
                        color: theme.button//"white"
                        z: -1

                        Rectangle {
                            anchors.fill: outerborder
                            anchors.margins: vpx(4)
                            color: theme.button
                            z: 7
                        }

                        Text {
                            text: modelData.title
                            x: vpx(8)
                            width: parent.width - vpx(16)
                            height: parent.height
                            font.family: titleFont.name
                            color: theme.text
                            font.pixelSize: Math.round(screenheight * 0.0194)
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.Wrap
                            visible: logo.source == "" && gameImage.source == ""//!modelData.assets.logo
                            z: 10
                        }
                    }

                    // Title bubble
                    Rectangle {
                        id: titleBubble
                        width: gameTitle.contentWidth + vpx(54)
                        height: Math.round(screenheight * 0.0611)
                        color: theme.button
                        radius: vpx(4)

                        // Need to figure out how to stop it from clipping the margin
                        // mapFromItem and mapToItem are probably going to help
                        property int xpos: gameImage.width / 2 - width / 2
                        x: xpos
                        //y: highlightBorder.y//vpx(-63)
                        z: 10 * index

                        anchors {
                            horizontalCenter: bubbletriangle.horizontalCenter
                            bottom: bubbletriangle.top
                        }

                        opacity: selected ? 0.95 : 0
                        //Behavior on opacity { NumberAnimation { duration: 50 } }

                        Text {
                            id: gameTitle
                            text: sortByIndex == 3 ? modelData.publisher + " / " + modelData.title : modelData.title
                            color: theme.accent
                            font.pixelSize: Math.round(screenheight * 0.0222)
                            font.bold: true
                            font.family: titleFont.name
                            //horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap

                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                leftMargin: vpx(27)
                            }
                        }

                        Component.onCompleted: {
                            if (wordWrap) {
                                if (gameTitle.paintedWidth > gameImage.width * 1.75) {
                                    gameTitle.width = gameImage.width * 1.5 - vpx(54);
                                    titleBubble.height = titleBubble.height * 1.5;
                                }
                            }
                        }
                    }

                    Image {
                        id: bubbletriangle
                        source: "../assets/images/triangle.svg"
                        width: vpx(17)
                        height: Math.round(screenheight * 0.0152)
                        opacity: 0
                        x: gameImage.width / 2 - width / 2
                        anchors.bottom: gameImage.top
                    }

                    ColorOverlay {
                        anchors.fill: bubbletriangle
                        source: bubbletriangle
                        color: theme.button
                        cached: true
                        opacity: titleBubble.opacity
                    }

                    // Border
                    HighlightBorder {
                        id: highlightBorder
                        width: gameImage.width + vpx(18)
                        height: width

                        anchors.centerIn: gameImage

                        //x: vpx(-7)
                        //y: vpx(-7)
                        z: -10

                        selected: delegateContainer.GridView.isCurrentItem
                    }
                }
            }
        }

        // Dim overlay
        Rectangle {
            id: dimOverlay
            parent: homeScreenContainer
            anchors.fill: parent
            color: "black"
            opacity: softwareScreenContainer.expandedVisible ? 0.5 : 0
            visible: softwareScreenContainer.expandedVisible
            z: 9
            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: softwareScreenContainer.expandedVisible = false
            }
        }

        // Panel
        Rectangle {
            id: expandedPanel
            parent: homeScreenContainer
            focus: softwareScreenContainer.expandedVisible

            width: softwareScreenContainer.expandedVisible ? Math.round(screenwidth * 0.75) : 0
            height: softwareScreenContainer.expandedVisible ? Math.round(screenheight * 0.75) : 0
            x: (screenwidth - width) / 2
            y: (screenheight - height) / 2
            z: 10
            radius: vpx(24)
            color: theme.button
            visible: softwareScreenContainer.expandedVisible
            opacity: softwareScreenContainer.expandedVisible ? 1 : 0

            border.width: currentGame && currentGame.favorite ? vpx(3) : 0
            border.color: theme.accent

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 0
                radius: currentGame && currentGame.favorite ? 24 : 8
                samples: 32
                color: currentGame && currentGame.favorite ? theme.accent : "#50000000"
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
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            Image {
                anchors.fill: parent
                source: currentGame ? (currentGame.assets.background || currentGame.assets.screenshots[0] || "") : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                visible: source !== "" && softwareScreenContainer.expandedVisible
                opacity: 0.15
                layer.enabled: true
                layer.effect: FastBlur {
                    radius: 32
                }
            }

            Item {
                anchors {
                    fill: parent
                    margins: vpx(32)
                }
                opacity: softwareScreenContainer.expandedVisible ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Text {
                    id: swPanelTitle
                    text: currentGame ? currentGame.title : ""
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

                Rectangle {
                    id: swDivider
                    anchors {
                        top: swPanelTitle.bottom
                        topMargin: vpx(16)
                        left: parent.left
                        right: parent.right
                    }
                    height: 1
                    color: theme.text
                    opacity: 0.12
                }

                Item {
                    id: swLeftCol
                    width: Math.round(parent.width * 0.26)
                    anchors {
                        top: swDivider.bottom
                        topMargin: vpx(20)
                        left: parent.left
                        bottom: swPlayButton.top
                    }

                    Rectangle {
                        width: parent.width
                        height: width
                        radius: vpx(16)
                        color: theme.main

                        AnimatedImage {
                            id: swCoverImage
                            playing: true
                            anchors.fill: parent
                            source: currentGame ? (currentGame.assets.boxFront || "") : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: swCoverImage.width
                                    height: swCoverImage.height
                                    radius: vpx(16)
                                    visible: false
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: currentGame ? currentGame.title.charAt(0) : "?"
                            color: theme.icon
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.06)
                            font.bold: true
                            visible: swCoverImage.status !== Image.Ready
                        }
                    }
                }

                Rectangle {
                    anchors {
                        top: swDivider.bottom
                        topMargin: vpx(20)
                        bottom: swPlayButton.top
                        left: swLeftCol.right
                        leftMargin: vpx(24)
                    }
                    width: 1
                    color: theme.text
                    opacity: 0.10
                }

                // Colonna destra: descrizione
                Column {
                    spacing: vpx(12)
                    anchors {
                        top: swDivider.bottom
                        topMargin: vpx(20)
                        left: swLeftCol.right
                        leftMargin: vpx(40)
                        right: parent.right
                    }

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
                        width: parent.width
                        text: currentGame ? (currentGame.description || "No description available.") : ""
                        color: theme.text
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.023)
                        wrapMode: Text.WordWrap
                        lineHeight: 1.4
                        elide: Text.ElideRight
                        maximumLineCount: 6
                    }
                }

                // Play button
                Rectangle {
                    id: swPlayButton
                    width: vpx(56)
                    height: vpx(56)
                    radius: width / 2
                    color: theme.accent
                    anchors {
                        bottom: parent.bottom
                        right: parent.right
                    }

                    Image {
                        id: swPlayIcon
                        source: "../assets/images/navigation/play.svg"
                        width: vpx(20)
                        height: vpx(20)
                        fillMode: Image.PreserveAspectFit
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: vpx(1)
                    }
                    ColorOverlay {
                        anchors.fill: swPlayIcon
                        source: swPlayIcon
                        color: "white"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            softwareScreenContainer.expandedVisible = false;
                            anim.start();
                            playSoftware();
                        }
                    }
                }
            }

            // Chiudi con B o Y, lancia con A
            Keys.onPressed: {
                if (api.keys.isCancel(event) || api.keys.isFilters(event)) {
                    event.accepted = true;
                    softwareScreenContainer.expandedVisible = false;
                }
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    softwareScreenContainer.expandedVisible = false;
                    anim.start();
                    playSoftware();
                }
            }
        }
    }
}
