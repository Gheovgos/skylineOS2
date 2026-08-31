import QtQuick 2.12
import QtQuick.Layouts 1.11
import SortFilterProxyModel 0.2
import QtMultimedia 5.9
import QtGraphicalEffects 1.12
import "qrc:/qmlutils" as PegasusUtils
import "../utils.js" as Utils
import "../layer_home"

FocusScope {
    id: root
    property var currentGame
    property alias radius: bg.radius
    property string scrapedBackground: ""
    property bool showDescription: false
    property string focusedButton: "play"   // "back" | "play" | "options" | "desc"
    property bool showOptionsPanel: false

    clip: true

    onVisibleChanged: {
        if (visible)
            focusedButton = "play";
        maybeScrapeBackground();
    }

    function activateFocusedButton() {
        if (focusedButton === "back") {
            goBack();
        } else if (focusedButton === "play") {
            closeGameDetail();
            anim.start();
            playGame();
        } else if (focusedButton === "options") {
            showOptionsPanel = !showOptionsPanel;
        } else if (focusedButton === "desc") {
            showDescription = !showDescription;
        }
    }

    function goBack() {
        if (showOptionsPanel) {
            showOptionsPanel = false;
        } else if (showDescription) {
            showDescription = false;
        } else {
            closeGameDetail();
        }
    }

    function maybeScrapeBackground() {
        scrapedBackground = "";
        if (!currentGame)
            return;
        if (currentGame.assets.background || currentGame.assets.screenshots[0])
            return;

        var requestedTitle = currentGame.title;
        Utils.fetchScrapedBackground(requestedTitle, function (url) {
            if (currentGame && currentGame.title === requestedTitle)
                root.scrapedBackground = url;
        });
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: vpx(24)
        color: theme.button
        clip: true

        AnimatedImage {
            id: bgImage
            anchors.fill: parent
            playing: true
            source: currentGame ? (currentGame.assets.background || currentGame.assets.screenshots[0] || scrapedBackground || "") : ""
            visible: source !== ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true

            Behavior on source {
                SequentialAnimation {
                    NumberAnimation {
                        target: bgImage
                        property: "opacity"
                        to: 0
                        duration: 150
                    }
                    PropertyAction {}
                    NumberAnimation {
                        target: bgImage
                        property: "opacity"
                        to: 1
                        duration: 200
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: "#CC000000"
                }
                GradientStop {
                    position: 0.45
                    color: "#66000000"
                }
                GradientStop {
                    position: 1.0
                    color: "#00000000"
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "#00000000"
                }
                GradientStop {
                    position: 0.75
                    color: "#00000000"
                }
                GradientStop {
                    position: 1.0
                    color: "#99000000"
                }
            }
        }

        // === TOP STATUS BAR (ora, profilo, batteria, wifi) ===
        Item {
            id: topStatusBar
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: vpx(28)
                leftMargin: vpx(48)
                rightMargin: vpx(48)
            }
            height: vpx(48)
            z: 5

            Row {
                spacing: vpx(10)
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                Item {
                    id: profileIconClipDetail
                    width: vpx(36)
                    height: vpx(36)
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: profileIconDetail
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                        asynchronous: true
                        source: api.memory.get("RA_LoggedIn") === "Yes" ? "https://media.retroachievements.org/UserPic/" + api.memory.get("RA_Username") + ".png" : "../assets/images/profile_icon.png"
                    }
                    Rectangle {
                        id: profileMaskDetail
                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                    }
                    OpacityMask {
                        anchors.fill: parent
                        source: profileIconDetail
                        maskSource: profileMaskDetail
                    }
                }

                Text {
                    text: {
                        if (api.memory.get("RA_LoggedIn") === "Yes")
                            return api.memory.get("RA_Username") || "";
                        if (api.memory.has("Username") && api.memory.get("Username") !== "")
                            return api.memory.get("Username");
                        return "";
                    }
                    visible: text !== ""
                    color: "white"
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.022)
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                id: statusPill
                height: vpx(40)
                width: statusRow.width + vpx(28)
                radius: height / 2
                color: "#40000000"
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                Row {
                    id: statusRow
                    spacing: vpx(14)
                    anchors.centerIn: parent

                    Text {
                        text: Qt.formatTime(new Date(), settings.timeFormat === "12hr" ? "h:mmap" : "hh:mm")
                        color: "white"
                        font.family: titleFont.name
                        font.bold: true
                        font.pixelSize: Math.round(screenheight * 0.02)
                        font.capitalization: Font.SmallCaps
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: isNaN(api.device.batteryPercent) ? "" : parseInt(api.device.batteryPercent * 100) + "%"
                        visible: showPercent && !isNaN(api.device.batteryPercent)
                        color: "white"
                        font.family: titleFont.name
                        font.bold: true
                        font.pixelSize: Math.round(screenheight * 0.02)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    BatteryIcon {
                        width: Math.round(screenheight * 0.04)
                        height: width / 1.5
                        level: isNaN(api.device.batteryPercent) ? 0 : parseInt(api.device.batteryPercent * 100)
                        visible: !isNaN(api.device.batteryPercent)
                        anchors.verticalCenter: parent.verticalCenter
                        layer.enabled: true
                        layer.effect: ColorOverlay {
                            color: "white"
                        }
                    }

                    Image {
                        width: Math.round(screenheight * 0.04)
                        height: width
                        fillMode: Image.PreserveAspectFit
                        source: "../assets/images/navigation/wifi.svg"
                        visible: settings.showWifi === "Yes"
                        anchors.verticalCenter: parent.verticalCenter
                        layer.enabled: true
                        layer.effect: ColorOverlay {
                            color: "white"
                        }
                    }
                }
            }
        }

        Column {
            id: infoColumn
            spacing: vpx(14)
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: vpx(48)
                rightMargin: vpx(48)
                bottom: actionRow.top
                bottomMargin: vpx(28)
            }

            // Contenitore cover + badge piattaforma (necessario per un anchoring valido tra i due)
            Item {
                id: coverContainer
                width: coverFrame.width
                height: coverFrame.height

                Rectangle {
                    id: coverFrame
                    width: vpx(180)
                    height: vpx(180)
                    radius: vpx(28)
                    color: theme.button
                    clip: true
                    antialiasing: true

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 0
                        verticalOffset: vpx(6)
                        radius: 16
                        samples: 32
                        color: "#60000000"
                    }

                    Rectangle {
                        id: coverMask
                        anchors.fill: parent
                        radius: vpx(28)
                        visible: false
                        antialiasing: true
                    }

                    AnimatedImage {
                        id: coverImage
                        anchors.fill: parent
                        playing: true
                        asynchronous: true
                        smooth: true
                        fillMode: Image.PreserveAspectCrop
                        source: currentGame ? (currentGame.assets.boxFront || currentGame.assets.tile || "") : ""
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: coverImage
                        source: coverImage
                        maskSource: coverMask
                        visible: coverImage.source !== "" && coverImage.status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: coverImage.source === "" || coverImage.status !== Image.Ready
                        text: currentGame ? currentGame.title.charAt(0) : "?"
                        color: theme.icon
                        font.family: titleFont.name
                        font.bold: true
                        font.pixelSize: Math.round(screenheight * 0.06)
                    }
                }

                // Badge platform
                Rectangle {
                    id: platformBadge
                    height: vpx(32)
                    width: platformBadgeRow.width + vpx(20)
                    radius: vpx(10)
                    color: theme.button
                    border.width: vpx(2)
                    border.color: theme.main
                    visible: currentGame && currentGame.collections && currentGame.collections.count > 0
                    anchors {
                        left: coverFrame.right
                        bottom: coverFrame.bottom
                        leftMargin: vpx(8)
                    }
                    z: 6

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 0
                        verticalOffset: vpx(2)
                        radius: 6
                        samples: 16
                        color: "#60000000"
                    }

                    Row {
                        id: platformBadgeRow
                        anchors.centerIn: parent
                        spacing: vpx(6)

                        Image {
                            width: vpx(16)
                            height: vpx(16)
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                            source: {
                                if (!currentGame || !currentGame.collections || currentGame.collections.count === 0)
                                    return "";
                                var p = currentGame.collections.get(0).shortName;
                                return p ? "../assets/images/platforms/" + p + ".svg" : "";
                            }
                            visible: source !== ""
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: theme.icon
                            }
                        }

                        Text {
                            text: (currentGame && currentGame.collections && currentGame.collections.count > 0) ? currentGame.collections.get(0).name : ""
                            color: theme.icon
                            font.family: titleFont.name
                            font.bold: true
                            font.pixelSize: Math.round(screenheight * 0.016)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Titolo grande
            Text {
                text: currentGame ? currentGame.title : ""
                color: "white"
                font.family: titleFont.name
                font.bold: true
                font.pixelSize: Math.round(screenheight * 0.055)
                width: Math.min(implicitWidth, screenwidth * 0.55)
                wrapMode: Text.WordWrap
            }

            Text {
                text: currentGame ? (currentGame.summary || currentGame.description || "") : ""
                visible: text !== ""
                color: "white"
                opacity: 0.8
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.02)
                width: Math.min(implicitWidth, screenwidth * 0.45)
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        // === ACTION ROW (Back + Play + stats) ===
        Item {
            id: actionRow
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: vpx(48)
                rightMargin: vpx(48)
                bottomMargin: vpx(32)
            }
            height: vpx(56)

            Row {
                id: playRow
                spacing: vpx(12)
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    id: backButton
                    width: vpx(56)
                    height: vpx(56)
                    radius: width / 2
                    color: "#33FFFFFF"
                    border.width: root.focusedButton === "back" ? vpx(3) : 0
                    border.color: theme.accent
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on border.width {
                        NumberAnimation {
                            duration: 120
                        }
                    }

                    Image {
                        anchors.centerIn: parent
                        width: vpx(20)
                        height: vpx(20)
                        fillMode: Image.PreserveAspectFit
                        source: "../assets/images/navigation/back.svg"
                        layer.enabled: true
                        layer.effect: ColorOverlay {
                            color: "white"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.focusedButton = "back";
                            root.goBack();
                        }
                    }
                }

                Rectangle {
                    id: playButton
                    width: playLabel.width + vpx(56)
                    height: vpx(56)
                    radius: height / 2
                    color: "white"
                    border.width: root.focusedButton === "play" ? vpx(3) : 0
                    border.color: theme.accent

                    Behavior on border.width {
                        NumberAnimation {
                            duration: 120
                        }
                    }

                    Row {
                        id: playLabel
                        anchors.centerIn: parent
                        spacing: vpx(10)

                        Image {
                            source: "../assets/images/navigation/play.svg"
                            width: vpx(18)
                            height: vpx(18)
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: "black"
                            }
                        }
                        Text {
                            text: "Play"
                            color: "black"
                            font.family: titleFont.name
                            font.bold: true
                            font.pixelSize: Math.round(screenheight * 0.02)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.focusedButton = "play";
                            launchGame(currentGame);
                            anim.start();
                        }
                    }
                }

                Rectangle {
                    id: optionsButton
                    width: vpx(56)
                    height: vpx(56)
                    radius: width / 2
                    color: root.showOptionsPanel ? theme.accent : "#33FFFFFF"
                    border.width: root.focusedButton === "options" ? vpx(3) : 0
                    border.color: theme.accent

                    Behavior on border.width {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\u22EF"
                        color: "white"
                        font.pixelSize: Math.round(screenheight * 0.03)
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.focusedButton = "options";
                            root.showOptionsPanel = !root.showOptionsPanel;
                        }
                    }
                }
            }

            // progress + playtime
            Row {
                spacing: vpx(10)
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    height: vpx(36)
                    width: progRow.width + vpx(20)
                    radius: height / 2
                    color: "#33000000"
                    visible: currentGame.extra.progress > 0

                    Row {
                        id: progRow
                        anchors.centerIn: parent
                        spacing: vpx(6)
                        Image {
                            source: "../assets/images/navigation/trophy.svg"
                            width: vpx(16)
                            height: vpx(16)
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: "white"
                            }
                        }
                        Text {
                            text: currentGame && currentGame.extra ? currentGame.extra.progress + "%" : ""
                            color: "white"
                            font.family: titleFont.name
                            font.bold: true
                            font.pixelSize: Math.round(screenheight * 0.018)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Rectangle {
                    height: vpx(36)
                    width: timeRow.width + vpx(20)
                    radius: height / 2
                    color: "#33000000"
                    visible: currentGame && (currentGame.playTime > 0 || (currentGame.extra && currentGame.extra.playtime > 0))

                    Row {
                        id: timeRow
                        anchors.centerIn: parent
                        spacing: vpx(6)
                        visible: {
                            var pt = currentGame ? currentGame.playTime : 0;
                            var manual = (currentGame && currentGame.extra) ? (currentGame.extra.playtime || 0) : 0;
                            var stackTime = parseInt(api.memory.get(currentGame.title) || "0");
                            console.log("++++++++++++++++++++++++++++++", stackTime)
                            return pt > 0 || manual > 0 || stackTime > 0;
                        }
                        Image {
                            source: "../assets/images/navigation/clock.svg"
                            width: vpx(14)
                            height: vpx(14)
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: "white"
                            }
                        }
                        Text {
                            text: {
                                if (!currentGame)
                                    return "00:00";
                                var totalSeconds = 0;

                                if (currentGame.extra && currentGame.extra.playtime) {
                                    totalSeconds = currentGame.extra.playtime;
                                    // Free memory
                                    if (api.memory.has(currentGame.title))
                                        api.memory.unset(currentGame.title);
                                } else if (api.memory.has(currentGame.title))
                                    totalSeconds = api.memory.get(currentGame.title);
                                else if (currentGame.playTime > 0)
                                    totalSeconds = currentGame.playTime;

                                if (totalSeconds <= 0)
                                    return "00:00";

                                var h = Math.floor(totalSeconds / 3600);
                                var m = Math.floor((totalSeconds % 3600) / 60);

                                return h + ":" + (m < 10 ? "0" + m : m);
                            }
                            color: "white"
                            font.family: titleFont.name
                            font.bold: true
                            font.pixelSize: Math.round(screenheight * 0.018)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Rectangle {
                    height: vpx(36)
                    width: playersRow.width + vpx(20)
                    radius: height / 2
                    color: "#33000000"
                    visible: currentGame && currentGame.players > 0

                    Row {
                        id: playersRow
                        anchors.centerIn: parent
                        spacing: vpx(6)
                        Image {
                            source: "../assets/images/navigation/player.svg"
                            width: vpx(16)
                            height: vpx(16)
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: "white"
                            }
                        }
                        Text {
                            text: currentGame ? currentGame.players : ""
                            color: "white"
                            font.family: titleFont.name
                            font.bold: true
                            font.pixelSize: Math.round(screenheight * 0.018)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        // === CENTRO BASSO: rating + periodo di gioco ===
        Row {
            id: centerInfoRow
            spacing: vpx(14)
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: vpx(32)
            }

            // Badge rating, colorato in base al punteggio
            Rectangle {
                id: ratingBadge
                width: vpx(56)
                height: vpx(56)
                radius: vpx(14)
                visible: currentGame && currentGame.rating > 0
                color: {
                    if (!currentGame)
                        return "#33000000";
                    var r = currentGame.rating * 10;
                    if (r >= 8)
                        return "#1DB954"; // verde
                    if (r >= 5)
                        return "#F5A623"; // ambra
                    return "#E63946"; // rosso
                }

                Column {
                    anchors.centerIn: parent
                    spacing: vpx(1)

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: currentGame ? (currentGame.rating * 10).toFixed(1) : ""
                        color: "white"
                        font.family: titleFont.name
                        font.bold: true
                        font.pixelSize: Math.round(screenheight * 0.022)
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "RATING"
                        color: "white"
                        opacity: 0.85
                        font.family: titleFont.name
                        font.bold: true
                        font.letterSpacing: 1
                        font.pixelSize: Math.round(screenheight * 0.009)
                    }
                }
            }

            // Pill periodo di gioco (startDate / endDate)
            Rectangle {
                id: playPeriodPill
                height: vpx(56)
                width: playPeriodColumn.width + vpx(28)
                radius: vpx(14)
                color: "#33000000"
                visible: currentGame && currentGame.extra && (currentGame.extra.startdate || currentGame.extra.enddate)

                Column {
                    id: playPeriodColumn
                    anchors.centerIn: parent
                    spacing: vpx(2)

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (currentGame && currentGame.extra && currentGame.extra.enddate) ? "PLAY PERIOD" : "STARTED"
                        color: "white"
                        opacity: 0.5
                        font.family: titleFont.name
                        font.bold: true
                        font.letterSpacing: 1
                        font.pixelSize: Math.round(screenheight * 0.011)
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            if (!currentGame || !currentGame.extra)
                                return "";
                            var start = currentGame.extra.startdate || "";
                            var end = currentGame.extra.enddate || "";
                            if (start && end)
                                return Utils.formatDateItalian(start) + "  →  " + Utils.formatDateItalian(end);
                            return start ? Utils.formatDateItalian(start) : "";
                        }
                        color: "white"
                        font.family: titleFont.name
                        font.bold: true
                        font.pixelSize: Math.round(screenheight * 0.016)
                    }
                }
            }
        }

        Rectangle {
            id: descToggleButton
            width: vpx(56)
            height: vpx(56)
            radius: width / 2
            color: root.showDescription ? theme.accent : "#33FFFFFF"
            border.width: root.focusedButton === "desc" ? vpx(3) : 0
            border.color: "white"
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: vpx(32)
            }
            z: 6

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
            Behavior on border.width {
                NumberAnimation {
                    duration: 120
                }
            }

            Image {
                anchors.centerIn: parent
                width: vpx(22)
                height: vpx(22)
                fillMode: Image.PreserveAspectFit
                source: "../assets/images/navigation/desc.svg"
                layer.enabled: true
                layer.effect: ColorOverlay {
                    color: "white"
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.focusedButton = "desc";
                    root.showDescription = !root.showDescription;
                }
            }
        }

        Rectangle {
            id: descriptionPanel
            width: Math.round(screenwidth * 0.40)
            height: Math.round(bg.height * 0.7)
            radius: vpx(20)
            color: "#DD1A1A1A"
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: vpx(56)
            }
            x: root.showDescription ? bg.width - width - vpx(56) : bg.width
            opacity: root.showDescription ? 1 : 0
            visible: opacity > 0
            z: 5
            clip: true

            Behavior on x {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: vpx(4)
                radius: 20
                samples: 32
                color: "#80000000"
            }

            Flickable {
                id: descFlick
                anchors {
                    fill: parent
                    margins: vpx(28)
                }
                contentWidth: width
                contentHeight: descContent.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: descContent
                    width: descFlick.width
                    spacing: vpx(18)

                    Text {
                        id: descText
                        width: parent.width
                        text: currentGame.summary ? currentGame.summary : ""
                        color: "white"
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.019)
                        wrapMode: Text.WordWrap
                        lineHeight: 1.35
                    }

                    // Tag — sotto la descrizione, dentro lo stesso pannello scrollabile
                    Column {
                        width: parent.width
                        spacing: vpx(8)
                        visible: currentGame && currentGame.tagList && currentGame.tagList.length > 0

                        Text {
                            text: "TAGS"
                            color: "white"
                            opacity: 0.5
                            font.family: titleFont.name
                            font.bold: true
                            font.letterSpacing: 1.5
                            font.pixelSize: Math.round(screenheight * 0.013)
                        }

                        Flow {
                            width: parent.width
                            spacing: vpx(8)

                            property var pillColors: ["#3B82F6", "#8B5CF6", "#10B981", "#F59E0B", "#EF4444"]

                            Repeater {
                                model: currentGame ? currentGame.tagList : []
                                Rectangle {
                                    height: vpx(26)
                                    width: tagText.width + vpx(16)
                                    radius: height / 2
                                    color: parent.parent.pillColors[index % parent.parent.pillColors.length]
                                    opacity: 0.85

                                    Text {
                                        id: tagText
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "white"
                                        font.family: titleFont.name
                                        font.pixelSize: Math.round(screenheight * 0.016)
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }

                    // Box info
                    Rectangle {
                        id: infoBox
                        width: parent.width
                        radius: vpx(14)
                        color: "#22FFFFFF"
                        height: infoBoxColumn.height + vpx(24)
                        visible: (currentGame && currentGame.developer !== "") || (currentGame && currentGame.genreList && currentGame.genreList.length > 0) || (currentGame && currentGame.release && new Date(currentGame.release).getFullYear() > 1970)

                        Column {
                            id: infoBoxColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: vpx(16)
                            }
                            spacing: vpx(10)

                            Row {
                                width: parent.width
                                spacing: vpx(8)
                                visible: currentGame && currentGame.developer !== ""

                                Text {
                                    text: "Developer"
                                    color: "white"
                                    opacity: 0.5
                                    font.family: titleFont.name
                                    font.bold: true
                                    font.pixelSize: Math.round(screenheight * 0.013)
                                    width: vpx(90)
                                }
                                Text {
                                    text: currentGame ? (currentGame.developer || "") : ""
                                    color: "white"
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.016)
                                    width: parent.width - vpx(98)
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: vpx(8)
                                visible: currentGame && currentGame.genreList && currentGame.genreList.length > 0

                                Text {
                                    text: "Genre"
                                    color: "white"
                                    opacity: 0.5
                                    font.family: titleFont.name
                                    font.bold: true
                                    font.pixelSize: Math.round(screenheight * 0.013)
                                    width: vpx(90)
                                }
                                Text {
                                    text: (currentGame && currentGame.genreList) ? currentGame.genreList.join(", ") : ""
                                    color: "white"
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.016)
                                    width: parent.width - vpx(98)
                                    wrapMode: Text.WordWrap
                                }
                            }

                            // Data di rilascio — nuova riga, stesso schema etichetta/valore
                            Row {
                                width: parent.width
                                spacing: vpx(8)
                                visible: currentGame && currentGame.release && new Date(currentGame.release).getFullYear() > 1970

                                Text {
                                    text: "Released"
                                    color: "white"
                                    opacity: 0.5
                                    font.family: titleFont.name
                                    font.bold: true
                                    font.pixelSize: Math.round(screenheight * 0.013)
                                    width: vpx(90)
                                }
                                Text {
                                    text: currentGame ? Utils.formatDateItalian(currentGame.release) : ""
                                    color: "white"
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.016)
                                    width: parent.width - vpx(98)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Keys.onLeftPressed: {
        navSound.play();
        var order = ["back", "play", "options", "desc"];
        var i = order.indexOf(focusedButton);
        focusedButton = order[(i - 1 + order.length) % order.length];
    }
    Keys.onRightPressed: {
        navSound.play();
        var order = ["back", "play", "options", "desc"];
        var i = order.indexOf(focusedButton);
        focusedButton = order[(i + 1) % order.length];
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            event.accepted = true;
            goBack();
            return;
        }
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            activateFocusedButton();
        }
    }
}
