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
    property var game
    property alias radius: bg.radius

    property int detailIndex: 0
    property var currentEntry: (gamesListModel.count > 0 && detailIndex >= 0 && detailIndex < gamesListModel.count) ? gamesListModel.get(detailIndex) : null
    property bool onAllSoftware: currentEntry ? currentEntry.idx < 0 : false

    clip: true

    onVisibleChanged: {
        if (visible)
            detailIndex = currentScreenID >= 0 ? currentScreenID : 0;
    }

    onDetailIndexChanged: {
        if (currentEntry && !onAllSoftware) {
            currentGame = listRecent.currentGame(currentEntry.idx);
            currentScreenID = currentEntry.idx;
        }
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
            source: (!root.onAllSoftware && currentGame) ? (currentGame.assets.background || currentGame.assets.screenshots[0] || "") : ""
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

        // Scurimento graduale da sinistra per far risaltare titolo/testo
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

            Row {
                spacing: vpx(14)
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

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

        // === INFO COLONNA: cover grande, titolo, tagline ===
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

            // Cover grande, arrotondata, al posto della vecchia miniRow
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

                // Maschera per garantire angoli smussati anche su immagini rettangolari
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
                    source: root.onAllSoftware
                            ? (root.currentEntry ? root.currentEntry.icon : "")
                            : (currentGame ? (currentGame.assets.boxFront || currentGame.assets.tile || "") : "")
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
                    text: root.onAllSoftware ? "…" : (currentGame ? currentGame.title.charAt(0) : "?")
                    color: theme.icon
                    font.family: titleFont.name
                    font.bold: true
                    font.pixelSize: Math.round(screenheight * 0.06)
                }
            }

            // Titolo grande
            Text {
                text: root.onAllSoftware ? (root.currentEntry ? root.currentEntry.name : "") : (currentGame ? currentGame.title : "")
                color: "white"
                font.family: titleFont.name
                font.bold: true
                font.pixelSize: Math.round(screenheight * 0.055)
                width: Math.min(implicitWidth, screenwidth * 0.55)
                wrapMode: Text.WordWrap
            }

            // Tagline / riassunto breve
            Text {
                text: (!root.onAllSoftware && currentGame) ? (currentGame.summary || currentGame.description || "") : ""
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
                    anchors.verticalCenter: parent.verticalCenter

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
                        onClicked: closeGameDetail()
                    }
                }

                Rectangle {
                    id: playButton
                    width: playLabel.width + vpx(56)
                    height: vpx(56)
                    radius: height / 2
                    color: "white"

                    Row {
                        id: playLabel
                        anchors.centerIn: parent
                        spacing: vpx(10)

                        Image {
                            source: root.onAllSoftware ? "../assets/images/allsoft_icon.svg" : "../assets/images/navigation/play.svg"
                            width: vpx(18)
                            height: vpx(18)
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: "black"
                            }
                        }
                        Text {
                            text: root.onAllSoftware ? "All Software" : "Play Game"
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
                            closeGameDetail();
                            if (root.onAllSoftware) {
                                showSoftwareScreen();
                            } else {
                                anim.start();
                                playGame();
                            }
                        }
                    }
                }

                Rectangle {
                    width: vpx(56)
                    height: vpx(56)
                    radius: width / 2
                    color: "#33FFFFFF"
                    visible: !root.onAllSoftware

                    Text {
                        anchors.centerIn: parent
                        text: "\u22EF" // ⋯
                        color: "white"
                        font.pixelSize: Math.round(screenheight * 0.03)
                        font.bold: true
                    }
                    // TODO: menu opzioni (preferiti, hide, ecc.) — step successivo
                }
            }

            // Stats a destra: progress + playtime
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
                    visible: !root.onAllSoftware && currentGame && currentGame.extra && currentGame.extra.progress > 0

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
                    visible: !root.onAllSoftware && currentGame && (currentGame.playTime > 0 || (currentGame.extra && currentGame.extra.playtime > 0))

                    Row {
                        id: timeRow
                        anchors.centerIn: parent
                        spacing: vpx(6)
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
                                var total = (currentGame.extra && currentGame.extra.playtime) ? currentGame.extra.playtime : currentGame.playTime;
                                if (!total || total <= 0)
                                    return "00:00";
                                var h = Math.floor(total / 3600);
                                var m = Math.floor((total % 3600) / 60);
                                return h + "h " + (m < 10 ? "0" + m : m) + "m";
                            }
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
    }

    Keys.onLeftPressed: {
        if (gamesListModel.count === 0)
            return;
        navSound.play();
        detailIndex = (detailIndex - 1 + gamesListModel.count) % gamesListModel.count;
    }
    Keys.onRightPressed: {
        if (gamesListModel.count === 0)
            return;
        navSound.play();
        detailIndex = (detailIndex + 1) % gamesListModel.count;
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            event.accepted = true;
            closeGameDetail();
        }
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            closeGameDetail();
            if (root.onAllSoftware) {
                showSoftwareScreen();
            } else {
                anim.start();
                playGame();
            }
        }
    }
}