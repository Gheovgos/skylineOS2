import QtQuick 2.12
import QtGraphicalEffects 1.12
import QtQuick.Layouts 1.11
import "../utils.js" as Utils
import "qrc:/qmlutils" as PegasusUtils

FocusScope {
    id: root
    property int lastHomeSwitcherIndex: 0
    property bool raProfileVisible: false

    // Build the games list but with extra menu options at the start and end
    ListModel {
        id: gamesListModel

        property var activeCollection: listRecent.games

        Component.onCompleted: {
            clear();
            buildList();
        }

        onActiveCollectionChanged: {
            clear();
            buildList();
        }

        function buildList() {
            var showHidden = api.memory.get("Show Hidden Apps") === "Yes";
            for (var i = 0; i < activeCollection.count; i++) {
                var title = listRecent.games.get(i).title;
                if (showHidden || !isAppHidden(title))
                    append(createListElement(i));
            }
            append({
                "name": "All Software",
                "idx": -3,
                "icon": "../assets/images/allsoft_icon.svg",
                "background": ""
            });
        }

        function createListElement(i) {
            return {
                name: listRecent.games.get(i).title,
                idx: i,
                icon: listRecent.games.get(i).assets.logo,
                background: listRecent.games.get(i).assets.screenshots[0]
            };
        }
    }
    function openRAPanel() {
        raProfileVisible = true;
        raPanel.open();
        raPanel.forceActiveFocus();
    }

    // Loading RA data
    function loadRAData() {
        var username = api.memory.get("RA_Username");
        var apiKey = api.memory.get("RetroAchievements API Key");

        if (!username || !apiKey)
            return;

        // User summary
        var xhrUser = new XMLHttpRequest();
        xhrUser.onreadystatechange = function () {
            if (xhrUser.readyState === XMLHttpRequest.DONE && xhrUser.status === 200) {
                try {
                    var data = JSON.parse(xhrUser.responseText);
                    raPointsText.text = (data.TotalPoints || "0") + " pts";
                    raRankText.text = "Rank " + (data.Rank || "—");
                    raRatioText.text = "Ratio " + (data.TotalTruePoints && data.TotalPoints ? (data.TotalTruePoints / Math.max(data.TotalPoints, 1)).toFixed(2) : "—");
                    if (data.RecentlyPlayed && data.RecentlyPlayed.length > 0)
                        raLastGameText.text = "Last played: " + data.RecentlyPlayed[0].Title;
                } catch (e) {}
            }
        };
        xhrUser.open("GET", "https://retroachievements.org/API/API_GetUserSummary.php?z=" + username + "&y=" + apiKey + "&u=" + username + "&g=1&a=5");
        xhrUser.send();

        raFriendsModel.clear();
        var xhrGames = new XMLHttpRequest();
        xhrGames.onreadystatechange = function () {
            if (xhrGames.readyState === XMLHttpRequest.DONE && xhrGames.status === 200) {
                try {
                    var games = JSON.parse(xhrGames.responseText);
                    for (var i = 0; i < games.length; i++) {
                        var g = games[i];
                        var total = g.AchievementsTotal || g.NumPossibleAchievements || 0;
                        var earned = g.NumAchievedHardcore || g.NumAchieved || 0;
                        raFriendsModel.append({
                            title: g.Title || "",
                            imageUrl: "https://retroachievements.org" + (g.ImageIcon || ""),
                            earned: earned,
                            total: total,
                            percent: total > 0 ? Math.round(earned / total * 100) : 0,
                            lastPlayed: g.LastPlayed ? Qt.formatDate(new Date(g.LastPlayed), "dd MMM yyyy") : "",
                            gameId: g.GameID || 0
                        });
                    }
                } catch (e) {}
            }
        };
        xhrGames.open("GET", "https://retroachievements.org/API/API_GetUserRecentlyPlayedGames.php?z=" + username + "&y=" + apiKey + "&u=" + username + "&c=10");
        xhrGames.send();
    }

    function loadGameAchievements(gameId) {
        var username = api.memory.get("RA_Username");
        var apiKey = api.memory.get("RetroAchievements API Key");
        raAchievementsModel.clear();

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    var achievements = data.Achievements;
                    if (!achievements)
                        return;
                    for (var key in achievements) {
                        var a = achievements[key];
                        raAchievementsModel.append({
                            title: a.Title || "",
                            description: a.Description || "",
                            points: a.Points || 0,
                            badgeUrl: "https://media.retroachievements.org/Badge/" + (a.DateEarned ? a.BadgeName : a.BadgeName + "_lock") + ".png",
                            earned: a.DateEarned ? true : false,
                            dateEarned: a.DateEarned ? Qt.formatDate(new Date(a.DateEarned), "dd MMM yyyy") : ""
                        });
                    }
                } catch (e) {
                    console.log("Achievement parse error:", e);
                }
            }
        };
        xhr.open("GET", "https://retroachievements.org/API/API_GetGameInfoAndUserProgress.php?g=" + gameId + "&u=" + username + "&y=" + apiKey);
        xhr.send();
    }

    Connections {
        target: root
        onHiddenAppsChanged: {
            gamesListModel.clear();
            gamesListModel.buildList();
        }
    }

    Item {
        id: homeScreenContainer
        width: parent.width
        height: parent.height

        property var batteryStatus: isNaN(api.device.batteryPercent) ? "" : parseInt(api.device.batteryPercent * 100)

        Image {
            id: globalBackground
            anchors.fill: parent
            source: currentGame ? (currentGame.assets.background || currentGame.assets.screenshots[0] || "") : ""
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            visible: {
                if (typeof (api.memory.get("Game Background") != "undefined") && api.memory.get("Game Background") === "Yes") {
                    return status === Image.Ready;
                } else
                    return false;
            }

            Behavior on source {
                SequentialAnimation {
                    NumberAnimation {
                        target: globalBackground
                        property: "opacity"
                        to: 0
                        duration: 200
                    }
                    PropertyAction {}
                    NumberAnimation {
                        target: globalBackground
                        property: "opacity"
                        to: 1
                        duration: 200
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: theme.main
                opacity: 0.75
            }
        }

        Item {
            id: topbar

            height: Math.round(screenheight * 0.2569)
            anchors {
                left: parent.left
                leftMargin: vpx(60)
                right: parent.right
                rightMargin: vpx(60)
                top: parent.top
                topMargin: Math.round(screenheight * 0.0472)
            }

            Row {
                spacing: vpx(10)
                anchors {
                    top: parent.top
                    left: parent.left
                }

                Item {
                    id: profileButton
                    width: Math.round(screenheight * 0.0833)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter

                    property bool selected: focus

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + vpx(8)
                        height: parent.height + vpx(8)
                        radius: width / 2
                        color: theme.accent
                        z: -1
                        opacity: profileButton.selected ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }

                        SequentialAnimation on opacity {
                            running: profileButton.selected
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: 1.0
                                duration: 0
                            }
                            NumberAnimation {
                                to: 0.85
                                duration: 400
                                easing {
                                    type: Easing.OutQuad
                                }
                            }
                            NumberAnimation {
                                to: 1.0
                                duration: 500
                                easing {
                                    type: Easing.InQuad
                                }
                            }
                            PauseAnimation {
                                duration: 200
                            }
                        }
                    }

                    Item {
                        id: profileImageClip
                        anchors.fill: parent

                        Image {
                            id: profileIcon
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            source: api.memory.get("RA_LoggedIn") === "Yes" ? "https://media.retroachievements.org/UserPic/" + api.memory.get("RA_Username") + ".png" : "../assets/images/profile_icon.png"
                        }

                        Rectangle {
                            id: maskRect
                            anchors.fill: parent
                            radius: width / 2
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: profileIcon
                            maskSource: maskRect
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            profileButton.focus = true;
                            navSound.play();
                            homeSwitcher.currentIndex = -1;
                        }
                    }

                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            if (api.memory.get("RA_LoggedIn") === "Yes")
                                openRAPanel();
                            else
                                navSound.play();
                        }
                    }

                    Keys.onDownPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                        homeSwitcher.currentIndex = 0;
                    }
                }

                Text {
                    id: usernameText
                    text: {
                        if (api.memory.get("RA_LoggedIn") === "Yes")
                            return api.memory.get("RA_Username") || "";
                        if (api.memory.has("Username") && api.memory.get("Username") !== "")
                            return api.memory.get("Username");
                        return "";
                    }
                    color: profileButton.selected ? theme.accent : theme.text
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.028)
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
            }

            Text {
                id: collectionHomeTitle
                text: currentCollection == -1 ? "" : api.collections.get(currentCollection).name
                color: theme.text
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.0277)
                font.bold: true
                anchors {
                    verticalCenter: profileButton.verticalCenter
                    left: profileButton.right
                    leftMargin: vpx(12)
                }
            }

            RowLayout {
                spacing: vpx(5)
                anchors {
                    verticalCenter: profileButton.verticalCenter
                    right: parent.right
                    rightMargin: vpx(15)
                }

                Text {
                    id: sysTime
                    property var timeSetting: (settings.timeFormat === "12hr") ? "h:mmap  " : "hh:mm  "
                    function set() {
                        sysTime.text = Qt.formatTime(new Date(), timeSetting);
                    }
                    Timer {
                        interval: 60000
                        repeat: true
                        running: true
                        triggeredOnStart: true
                        onTriggered: sysTime.set()
                    }
                    onTimeSettingChanged: sysTime.set()
                    color: theme.text
                    font.family: titleFont.name
                    font.weight: Font.Bold
                    font.letterSpacing: 4
                    font.pixelSize: Math.round(screenheight * 0.0277)
                    horizontalAlignment: Text.Right
                    font.capitalization: Font.SmallCaps
                }

                Text {
                    id: batteryPercentage
                    function set() {
                        batteryPercentage.text = homeScreenContainer.batteryStatus + "%";
                    }
                    Timer {
                        interval: 60000
                        repeat: isNaN(api.device.batteryPercent) ? false : showPercent
                        running: isNaN(api.device.batteryPercent) ? false : showPercent
                        triggeredOnStart: isNaN(api.device.batteryPercent) ? false : showPercent
                        onTriggered: batteryPercentage.set()
                    }
                    color: theme.text
                    font.family: titleFont.name
                    font.weight: Font.Bold
                    font.letterSpacing: 1
                    font.pixelSize: Math.round(screenheight * 0.0277)
                    Component.onCompleted: font.capitalization = Font.SmallCaps
                    anchors.verticalCenter: sysTime.verticalCenter
                    visible: isNaN(api.device.batteryPercent) ? false : showPercent
                }

                BatteryIcon {
                    id: batteryIcon
                    width: Math.round(screenheight * 0.0433)
                    height: width / 1.5
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: theme.text
                        antialiasing: true
                        cached: true
                    }
                    function set() {
                        batteryIcon.level = homeScreenContainer.batteryStatus;
                    }
                    Timer {
                        interval: 60000
                        repeat: true
                        running: true
                        triggeredOnStart: true
                        onTriggered: batteryIcon.set()
                    }
                    anchors.verticalCenter: sysTime.verticalCenter
                    visible: !isNaN(api.device.batteryPercent)
                }

                Image {
                    id: chargingIcon
                    property bool chargingStatus: api.device.batteryCharging
                    width: Math.round(screenheight * 0.0433)
                    height: width
                    fillMode: Image.PreserveAspectFit
                    source: "../assets/images/charging.svg"
                    sourceSize.width: vpx(10)
                    sourceSize.height: vpx(15)
                    smooth: true
                    horizontalAlignment: Image.AlignLeft
                    anchors.verticalCenter: sysTime.verticalCenter
                    visible: chargingStatus && batteryIcon.level < 99
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: theme.text
                        antialiasing: true
                        cached: true
                    }
                    function set() {
                        chargingStatus = api.device.batteryCharging;
                    }
                    Timer {
                        interval: 10000
                        repeat: !isNaN(api.device.batteryPercent)
                        running: !isNaN(api.device.batteryPercent)
                        triggeredOnStart: !isNaN(api.device.batteryPercent)
                        onTriggered: chargingIcon.set()
                    }
                }

                Image {
                    id: wifiIcon
                    sourceSize.width: vpx(26)
                    sourceSize.height: vpx(26)
                    fillMode: Image.PreserveAspectFit
                    source: "../assets/images/navigation/wifi.svg"
                    anchors.verticalCenter: sysTime.verticalCenter
                    visible: (settings.showWifi === "Yes")
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: theme.text
                        antialiasing: true
                        cached: true
                    }
                }
            }
        }

        // Home menu
        HomeBar {
            id: homeSwitcher
            anchors {
                left: parent.left
                leftMargin: vpx(98)
                right: parent.right
                top: topbar.bottom
            }
            height: Math.round(screenheight * (parseFloat(settings.homeCardSize) / 100))
            focus: true
        }

        // Button menu
        Item {
            id: buttonMenuContainer
            anchors {
                top: homeSwitcher.bottom
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            width: buttonMenu.width + vpx(48)
            height: parent.bottom

            Item {
                id: buttonBar
                anchors.centerIn: parent
                width: buttonMenu.width + vpx(48)
                height: vpx(64)

                Image {
                    id: buttonBarBg
                    source: "../assets/images/menuButtonBackground.png"
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: buttonBarMask
                    }
                }

                Rectangle {
                    id: buttonBarMask
                    anchors.fill: parent
                    radius: parent.height / 2
                    color: theme.button
                    visible: buttonBarBg.status !== Image.Ready
                }

                //radius: height / 2
                //color: theme.button

                layer.enabled: enableDropShadows
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 0
                    verticalOffset: vpx(4)
                    radius: 12
                    samples: 24
                    color: "#30000000"
                }
            }

            RowLayout {
                id: buttonMenu
                spacing: vpx(8)
                anchors.centerIn: parent

                MenuButton {
                    id: infoButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Feed"
                    visible: (api.memory.get("Feed Button Show") === "Yes")
                    icon: "../assets/images/navigation/info.svg"
                    onFocusChanged: if (focus)
                        root.lastHomeSwitcherIndex = homeSwitcher.currentIndex

                    Keys.onUpPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                        homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0;
                    }
                    /* KeyNavigation.right: {navSound.play(); storeButton.visible ? storeButton : browserButton.visible ? browserButton : galleryButton.visible ? galleryButton : backlogButton.visible ? backlogButton : controllerButton.visible ? controllerButton : settingsButton.visible ? settingsButton : suspendButton}
                    KeyNavigation.left: {navSound.play(); suspendButton.visible ? suspendButton : settingsButton.visible ? settingsButton : controllerButton.visible ? controllerButton : backlogButton.visible ? backlogButton : galleryButton.visible ? galleryButton : browserButton.visible ? browserButton : storeButton}
                     */
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            showButtonScreen("info");
                        }
                    }
                    onClicked: {
                        infoButton.focus = true;
                        homeSwitcher.currentIndex = -1;
                        navSound.play();
                        showButtonScreen("info");
                    }
                }

                MenuButton {
                    id: storeButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Store"
                    icon: "../assets/images/navigation/Store.svg"
                    visible: (api.memory.get("Store Button Show") === "Yes")
                    onFocusChanged: if (focus)
                        root.lastHomeSwitcherIndex = homeSwitcher.currentIndex

                    Keys.onUpPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                        homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0;
                    }
                    KeyNavigation.right: browserButton.visible ? browserButton : galleryButton.visible ? galleryButton : backlogButton.visible ? backlogButton : controllerButton.visible ? controllerButton : settingsButton.visible ? settingsButton : suspendButton.visible ? suspendButton : infoButton
                    KeyNavigation.left: infoButton.visible ? infoButton : suspendButton.visible ? suspendButton : settingsButton.visible ? settingsButton : controllerButton.visible ? controllerButton : backlogButton.visible ? backlogButton : galleryButton.visible ? galleryButton : browserButton
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            if (Qt.platform.os === "android")
                                Qt.openUrlExternally((typeof (api.memory.get("Store URI")) != "undefined") ? api.memory.get("Store URI") : "https://play.google.com/store");
                            else
                                Qt.openUrlExternally((typeof (api.memory.get("Store URI")) != "undefined") ? api.memory.get("Store URI") : "steam://store");
                        }
                    }
                    onClicked: {
                        storeButton.focus = true;
                        homeSwitcher.currentIndex = -1;
                        navSound.play();
                        if (Qt.platform.os === "android")
                            Qt.openUrlExternally((typeof (api.memory.get("Store URI")) != "undefined") ? api.memory.get("Store URI") : "https://play.google.com/store");
                        else
                            Qt.openUrlExternally((typeof (api.memory.get("Store URI")) != "undefined") ? api.memory.get("Store URI") : "steam://store");
                    }
                }

                MenuButton {
                    id: browserButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Browser"
                    icon: "../assets/images/navigation/browser.svg"
                    visible: (api.memory.get("Browser Button Show") === "Yes")
                    onFocusChanged: if (focus)
                        root.lastHomeSwitcherIndex = homeSwitcher.currentIndex

                    Keys.onUpPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                        homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0;
                    }
                    KeyNavigation.right: galleryButton.visible ? galleryButton : backlogButton.visible ? backlogButton : controllerButton.visible ? controllerButton : settingsButton.visible ? settingsButton : suspendButton.visible ? suspendButton : infoButton.visible ? infoButton : storeButton
                    KeyNavigation.left: storeButton.visible ? storeButton : infoButton.visible ? infoButton : suspendButton.visible ? suspendButton : settingsButton.visible ? settingsButton : controllerButton.visible ? controllerButton : backlogButton.visible ? backlogButton : galleryButton
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            Qt.openUrlExternally((typeof (api.memory.get("Browser default link")) != "undefined") ? api.memory.get("Browser default link") : "https://");
                        }
                    }
                    onClicked: {
                        browserButton.focus = true;
                        homeSwitcher.currentIndex = -1;
                        navSound.play();
                        Qt.openUrlExternally((typeof (api.memory.get("Browser default link")) != "undefined") ? api.memory.get("Browser default link") : "https://");
                    }
                }

                MenuButton {
                    id: galleryButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Gallery"
                    icon: "../assets/images/navigation/Gallery.svg"
                    visible: (api.memory.get("Gallery Button Show") === "Yes")
                    onFocusChanged: if (focus)
                        root.lastHomeSwitcherIndex = homeSwitcher.currentIndex

                    Keys.onUpPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                        homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0;
                    }
                    KeyNavigation.right: backlogButton.visible ? backlogButton : controllerButton.visible ? controllerButton : settingsButton.visible ? settingsButton : suspendButton.visible ? suspendButton : infoButton.visible ? infoButton : storeButton.visible ? storeButton : browserButton
                    KeyNavigation.left: browserButton.visible ? browserButton : storeButton.visible ? storeButton : infoButton.visible ? infoButton : suspendButton.visible ? suspendButton : settingsButton.visible ? settingsButton : controllerButton.visible ? controllerButton : backlogButton
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            if (Qt.platform.os === "android")
                                Qt.openUrlExternally((typeof (api.memory.get("Gallery URI")) != "undefined") ? api.memory.get("Gallery URI") : "android-app://com.google.android.apps.photos");
                            else
                                Qt.openUrlExternally((typeof (api.memory.get("Gallery URI")) != "undefined") ? api.memory.get("Gallery URI") : "");
                        }
                    }
                    onClicked: {
                        galleryButton.focus = true;
                        homeSwitcher.currentIndex = -1;
                        navSound.play();
                        if (Qt.platform.os === "android")
                            Qt.openUrlExternally((typeof (api.memory.get("Gallery URI")) != "undefined") ? api.memory.get("Gallery URI") : "android-app://com.google.android.apps.photos");
                        else
                            Qt.openUrlExternally((typeof (api.memory.get("Gallery URI")) != "undefined") ? api.memory.get("Gallery URI") : "");
                    }
                }

                MenuButton {
                    id: backlogButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Backlog"
                    icon: "../assets/images/navigation/backlog.svg"
                    visible: (api.memory.get("Backlog Button Show") === "Yes")
                    onFocusChanged: if (focus)
                        root.lastHomeSwitcherIndex = homeSwitcher.currentIndex

                    Keys.onUpPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                        homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0;
                    }
                    KeyNavigation.right: controllerButton.visible ? controllerButton : settingsButton.visible ? settingsButton : suspendButton.visible ? suspendButton : infoButton.visible ? infoButton : storeButton.visible ? storeButton : browserButton.visible ? browserButton : galleryButton
                    KeyNavigation.left: galleryButton.visible ? galleryButton : browserButton.visible ? browserButton : storeButton.visible ? storeButton : infoButton.visible ? infoButton : suspendButton.visible ? suspendButton : settingsButton.visible ? settingsButton : controllerButton
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            showButtonScreen("backlog");
                        }
                    }
                    onClicked: {
                        backlogButton.focus = true;
                        homeSwitcher.currentIndex = -1;
                        navSound.play();
                        showButtonScreen("backlog");
                    }
                }

                MenuButton {
                    id: controllerButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Files"
                    icon: "../assets/images/navigation/Controller.svg"
                    visible: (api.memory.get("Files Button Show") === "Yes")
                    onFocusChanged: if (focus)
                        root.lastHomeSwitcherIndex = homeSwitcher.currentIndex

                    Keys.onUpPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                        homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0;
                    }
                    KeyNavigation.right: settingsButton.visible ? settingsButton : suspendButton.visible ? suspendButton : infoButton.visible ? infoButton : storeButton.visible ? storeButton : browserButton.visible ? browserButton : galleryButton.visible ? galleryButton : backlogButton
                    KeyNavigation.left: backlogButton.visible ? backlogButton : galleryButton.visible ? galleryButton : browserButton.visible ? browserButton : storeButton.visible ? storeButton : infoButton.visible ? infoButton : suspendButton.visible ? suspendButton : settingsButton
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            if (Qt.platform.os === "android")
                                Qt.openUrlExternally((typeof (api.memory.get("Files URI")) != "undefined") ? api.memory.get("Files URI") : "content://com.android.externalstorage.documents/root/primary");
                            else
                                Qt.openUrlExternally((typeof (api.memory.get("Files URI")) != "undefined") ? api.memory.get("Files URI") : "");
                        }
                    }
                    onClicked: {
                        controllerButton.focus = true;
                        homeSwitcher.currentIndex = -1;
                        navSound.play();
                        if (Qt.platform.os === "android")
                            Qt.openUrlExternally((typeof (api.memory.get("Files URI")) != "undefined") ? api.memory.get("Files URI") : "content://com.android.externalstorage.documents/root/primary");
                        else
                            Qt.openUrlExternally((typeof (api.memory.get("Files URI")) != "undefined") ? api.memory.get("Files URI") : "");
                    }
                }

                MenuButton {
                    id: settingsButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Theme Settings"
                    icon: "../assets/images/navigation/Settings.png"
                    onFocusChanged: if (focus)
                        root.lastHomeSwitcherIndex = homeSwitcher.currentIndex

                    Keys.onUpPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                        homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0;
                    }
                    KeyNavigation.right: suspendButton.visible ? suspendButton : infoButton.visible ? infoButton : storeButton.visible ? storeButton : browserButton.visible ? browserButton : galleryButton.visible ? galleryButton : backlogButton.visible ? backlogButton : controllerButton
                    KeyNavigation.left: controllerButton.visible ? controllerButton : backlogButton.visible ? backlogButton : galleryButton.visible ? galleryButton : browserButton.visible ? browserButton : storeButton.visible ? storeButton : infoButton.visible ? infoButton : suspendButton
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            showSettingsScreen();
                        }
                    }
                    onClicked: {
                        settingsButton.focus = true;
                        homeSwitcher.currentIndex = -1;
                        navSound.play();
                        showSettingsScreen();
                    }
                }

                MenuButton {
                    id: suspendButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Suspend"
                    icon: "../assets/images/navigation/Suspend.svg"
                    visible: (api.memory.get("Suspend Button Show") === "Yes")
                    onFocusChanged: if (focus)
                        root.lastHomeSwitcherIndex = homeSwitcher.currentIndex

                    Keys.onUpPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                        homeSwitcher.currentIndex = (root.lastHomeSwitcherIndex >= 0) ? root.lastHomeSwitcherIndex : 0;
                    }
                    KeyNavigation.right: infoButton.visible ? infoButton : storeButton.visible ? storeButton : browserButton.visible ? browserButton : galleryButton.visible ? galleryButton : backlogButton.visible ? backlogButton : controllerButton.visible ? controllerButton : settingsButton
                    KeyNavigation.left: settingsButton.visible ? settingsButton : controllerButton.visible ? controllerButton : backlogButton.visible ? backlogButton : galleryButton.visible ? galleryButton : browserButton.visible ? browserButton : storeButton.visible ? storeButton : infoButton
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            showButtonScreen("suspend");
                        }
                    }
                    onClicked: {
                        suspendButton.focus = true;
                        homeSwitcher.currentIndex = -1;
                        navSound.play();
                        showButtonScreen("suspend");
                    }
                }
            }
        }

        // Dim overlay RA
        Rectangle {
            id: raDim
            anchors.fill: parent
            color: "black"
            opacity: raProfileVisible ? 0.5 : 0
            visible: opacity > 0
            z: 50
            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: raPanel.close()
            }
        }

        // RA Panel
        Rectangle {
            id: raPanel
            width: parent.width
            height: Math.round(screenheight * 0.78)
            x: 0
            y: -parent.height
            z: 51
            radius: vpx(24)
            color: theme.button

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: vpx(-4)
                radius: 20
                samples: 32
                color: "#60000000"
            }

            property bool isOpen: false

            function open() {
                isOpen = true;
                raProfileVisible = true;
                slideIn.start();
                loadRAData();
                Qt.callLater(function () {
                    raFriendsList.forceActiveFocus();
                });
            }

            function close() {
                isOpen = false;
                raGameDetail.visible = false;
                slideOut.start();
            }

            NumberAnimation {
                id: slideIn
                target: raPanel
                property: "y"
                to: 0
                duration: 300
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                id: slideOut
                target: raPanel
                property: "y"
                to: -homeScreenContainer.height
                duration: 250
                easing.type: Easing.InCubic
                onStopped: {
                    raProfileVisible = false;
                    profileButton.focus = true;
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: vpx(12)
                width: vpx(40)
                height: vpx(4)
                radius: height / 2
                color: theme.icon
                opacity: 0.4
            }

            // Contenuto principale
            Item {
                id: raPanelContent
                anchors {
                    fill: parent
                    margins: vpx(32)
                    topMargin: vpx(28)
                }
                visible: !raGameDetail.visible

                Item {
                    id: raHeader
                    width: parent.width
                    height: vpx(80)

                    Item {
                        id: raAvatarClip
                        width: vpx(72)
                        height: vpx(72)
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: raAvatar
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            source: api.memory.get("RA_LoggedIn") === "Yes" ? "https://media.retroachievements.org/UserPic/" + api.memory.get("RA_Username") + ".png" : ""
                            asynchronous: true
                        }
                        Rectangle {
                            id: raAvatarMask
                            anchors.fill: parent
                            radius: width / 2
                            visible: false
                        }
                        OpacityMask {
                            anchors.fill: parent
                            source: raAvatar
                            maskSource: raAvatarMask
                        }
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: vpx(-3)
                            radius: width / 2
                            color: "transparent"
                            border.color: theme.accent
                            border.width: vpx(3)
                        }
                    }

                    Column {
                        anchors {
                            left: raAvatarClip.right
                            leftMargin: vpx(16)
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: vpx(4)

                        Text {
                            text: api.memory.get("RA_Username") || ""
                            color: theme.text
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.032)
                            font.bold: true
                        }
                        Row {
                            spacing: vpx(16)
                            Text {
                                id: raPointsText
                                text: "— pts"
                                color: theme.accent
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.020)
                                font.bold: true
                            }
                            Text {
                                id: raRankText
                                text: "Rank —"
                                color: theme.icon
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.020)
                            }
                            Text {
                                id: raRatioText
                                text: "Ratio —"
                                color: theme.icon
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.020)
                            }
                        }
                        Text {
                            id: raLastGameText
                            text: ""
                            color: theme.icon
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.017)
                            opacity: 0.7
                        }
                    }
                }

                Rectangle {
                    id: raSeparator
                    anchors {
                        top: raHeader.bottom
                        topMargin: vpx(16)
                        left: parent.left
                        right: parent.right
                    }
                    height: 1
                    color: theme.text
                    opacity: 0.12
                }

                Text {
                    id: raFriendsTitle
                    anchors {
                        top: raSeparator.bottom
                        topMargin: vpx(16)
                        left: parent.left
                    }
                    text: "RECENTLY PLAYED"
                    color: theme.icon
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.015)
                    font.bold: true
                    font.letterSpacing: 1.5
                    opacity: 0.6
                }

                ListView {
                    id: raFriendsList
                    anchors {
                        top: raFriendsTitle.bottom
                        topMargin: vpx(12)
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    spacing: vpx(8)
                    clip: true
                    model: raFriendsModel
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationWraps: false

                    delegate: Item {
                        width: raFriendsList.width
                        height: vpx(72)
                        property bool isSelected: ListView.isCurrentItem

                        Rectangle {
                            anchors.fill: parent
                            radius: vpx(12)
                            color: isSelected ? theme.accent : theme.main
                            opacity: isSelected ? 0.85 : 0.6
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
                        }

                        Item {
                            id: gameIconClip
                            width: vpx(52)
                            height: vpx(52)
                            anchors {
                                left: parent.left
                                leftMargin: vpx(8)
                                verticalCenter: parent.verticalCenter
                            }
                            Image {
                                id: gameIcon
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                visible: false
                                source: imageUrl
                                asynchronous: true
                            }
                            Rectangle {
                                id: gameIconMask
                                anchors.fill: parent
                                radius: vpx(8)
                                visible: false
                            }
                            OpacityMask {
                                anchors.fill: parent
                                source: gameIcon
                                maskSource: gameIconMask
                            }
                        }

                        Column {
                            anchors {
                                left: gameIconClip.right
                                leftMargin: vpx(12)
                                right: lastPlayedText.left
                                rightMargin: vpx(8)
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: vpx(4)

                            Text {
                                width: parent.width
                                text: title
                                color: theme.text
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.020)
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Item {
                                width: parent.width
                                height: vpx(6)
                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: theme.main
                                    opacity: 0.4
                                }
                                Rectangle {
                                    width: parent.width * (percent / 100)
                                    height: parent.height
                                    radius: height / 2
                                    color: percent >= 100 ? "#F59E0B" : theme.accent
                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 400
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                            }

                            Text {
                                text: earned + " / " + total + " (" + percent + "%)"
                                color: theme.icon
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.015)
                                opacity: 0.7
                            }
                        }

                        Text {
                            id: lastPlayedText
                            anchors {
                                right: parent.right
                                rightMargin: vpx(16)
                                verticalCenter: parent.verticalCenter
                            }
                            text: lastPlayed
                            color: theme.icon
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.014)
                            opacity: 0.6
                        }
                    }

                    Keys.onUpPressed: {
                        if (currentIndex > 0) {
                            navSound.play();
                            decrementCurrentIndex();
                        }
                    }
                    Keys.onDownPressed: {
                        if (currentIndex < count - 1) {
                            navSound.play();
                            incrementCurrentIndex();
                        }
                    }
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            var data = raFriendsModel.get(currentIndex);
                            raGameDetail.open(data);
                        }
                        if (api.keys.isCancel(event)) {
                            event.accepted = true;
                            raPanel.close();
                        }
                    }
                }
            }

            // Detail panel
            Rectangle {
                id: raGameDetail
                anchors.fill: parent
                radius: vpx(24)
                color: theme.button
                visible: false
                z: 10

                property var gameData: null

                function open(data) {
                    gameData = data;
                    visible = true;
                    loadGameAchievements(data.gameId);
                    Qt.callLater(function () {
                        achievementsList.forceActiveFocus();
                    });
                }

                function close() {
                    visible = false;
                    raFriendsList.forceActiveFocus();
                }

                Image {
                    anchors.fill: parent
                    source: raGameDetail.gameData ? raGameDetail.gameData.imageUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: 0.1
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

                    Item {
                        id: detailIconClip
                        width: vpx(80)
                        height: vpx(80)
                        anchors.top: parent.top

                        Image {
                            id: detailIcon
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            source: raGameDetail.gameData ? raGameDetail.gameData.imageUrl : ""
                            asynchronous: true
                        }
                        Rectangle {
                            id: detailIconMask
                            anchors.fill: parent
                            radius: vpx(12)
                            visible: false
                        }
                        OpacityMask {
                            anchors.fill: parent
                            source: detailIcon
                            maskSource: detailIconMask
                        }
                    }

                    Column {
                        anchors {
                            left: detailIconClip.right
                            leftMargin: vpx(16)
                            verticalCenter: detailIconClip.verticalCenter
                        }
                        spacing: vpx(4)
                        Text {
                            text: raGameDetail.gameData ? raGameDetail.gameData.title : ""
                            color: theme.text
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.032)
                            font.bold: true
                        }
                        Text {
                            text: raGameDetail.gameData ? raGameDetail.gameData.lastPlayed : ""
                            color: theme.icon
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.018)
                            opacity: 0.7
                        }
                    }

                    Rectangle {
                        id: detailDivider
                        anchors {
                            top: detailIconClip.bottom
                            topMargin: vpx(20)
                            left: parent.left
                            right: parent.right
                        }
                        height: 1
                        color: theme.text
                        opacity: 0.12
                    }

                    // Progress bar

                    Column {
                        id: progressSection

                        anchors {
                            top: detailDivider.bottom
                            topMargin: vpx(16)
                            left: parent.left
                            right: parent.right
                        }

                        spacing: vpx(16)

                        RowLayout {
                            width: parent.width

                            Text {
                                text: raGameDetail.gameData ? raGameDetail.gameData.earned + " / " + raGameDetail.gameData.total : ""

                                color: theme.text
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.020)
                                font.bold: true
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: raGameDetail.gameData ? raGameDetail.gameData.percent + "%" : ""

                                color: raGameDetail.gameData && raGameDetail.gameData.percent >= 100 ? "#F59E0B" : theme.accent

                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.020)
                                font.bold: true
                            }
                        }

                        Item {
                            width: parent.width
                            height: vpx(8)

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: theme.main
                                opacity: 0.4
                            }

                            Rectangle {
                                width: raGameDetail.gameData ? parent.width * (raGameDetail.gameData.percent / 100) : 0

                                height: parent.height
                                radius: height / 2

                                color: raGameDetail.gameData && raGameDetail.gameData.percent >= 100 ? "#F59E0B" : theme.accent

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 600
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }
                    }

                    // List achievement
                    ListView {
                        id: achievementsList
                        anchors {
                            top: progressSection.bottom
                            topMargin: vpx(16)
                            left: parent.left
                            right: parent.right
                            bottom: backHint.top
                            bottomMargin: vpx(12)
                        }
                        spacing: vpx(6)
                        clip: true
                        model: raAchievementsModel
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Item {
                            width: achievementsList.width
                            height: vpx(64)

                            Rectangle {
                                anchors.fill: parent
                                radius: vpx(10)
                                color: earned ? theme.main : "#1A000000"
                                opacity: earned ? 0.8 : 0.5
                                border.color: earned ? theme.accent : "transparent"
                                border.width: earned ? vpx(1) : 0
                            }

                            // Badge
                            Item {
                                id: badgeClip
                                width: vpx(48)
                                height: vpx(48)
                                anchors {
                                    left: parent.left
                                    leftMargin: vpx(8)
                                    verticalCenter: parent.verticalCenter
                                }
                                opacity: earned ? 1.0 : 0.35

                                Image {
                                    id: badgeImg
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectFit
                                    visible: false
                                    source: badgeUrl
                                    asynchronous: true
                                }
                                Rectangle {
                                    id: badgeMask
                                    anchors.fill: parent
                                    radius: vpx(6)
                                    visible: false
                                }
                                OpacityMask {
                                    anchors.fill: parent
                                    source: badgeImg
                                    maskSource: badgeMask
                                }
                            }

                            Column {
                                anchors {
                                    left: badgeClip.right
                                    leftMargin: vpx(10)
                                    right: pointsBadge.left
                                    rightMargin: vpx(8)
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: vpx(2)

                                Text {
                                    width: parent.width
                                    text: title
                                    color: earned ? theme.text : theme.icon
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.018)
                                    font.bold: earned
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: description
                                    color: theme.icon
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.014)
                                    opacity: 0.7
                                    elide: Text.ElideRight
                                }
                                Text {
                                    visible: earned && dateEarned !== ""
                                    text: "Unlocked: " + dateEarned
                                    color: theme.accent
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.013)
                                    opacity: 0.8
                                }
                            }

                            // Points badge
                            Rectangle {
                                id: pointsBadge
                                anchors {
                                    right: parent.right
                                    rightMargin: vpx(10)
                                    verticalCenter: parent.verticalCenter
                                }
                                width: vpx(44)
                                height: vpx(24)
                                radius: height / 2
                                color: earned ? theme.accent : theme.main
                                opacity: earned ? 1.0 : 0.5

                                Text {
                                    anchors.centerIn: parent
                                    text: points + "p"
                                    color: earned ? "white" : theme.icon
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.015)
                                    font.bold: true
                                }
                            }
                        }
                    }

                    Row {
                        id: backHint
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                        }
                        spacing: vpx(12)
                        Rectangle {
                            width: vpx(32)
                            height: vpx(32)
                            radius: width / 2
                            color: theme.main
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "B"
                                color: theme.text
                                font.family: titleFont.name
                                font.pixelSize: vpx(16)
                                font.bold: true
                                anchors.centerIn: parent
                            }
                        }
                        Text {
                            text: "Back"
                            color: theme.icon
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.020)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                        }
                        spacing: vpx(12)
                        Rectangle {
                            width: vpx(32)
                            height: vpx(32)
                            radius: width / 2
                            color: theme.main
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "B"
                                color: theme.text
                                font.family: titleFont.name
                                font.pixelSize: vpx(16)
                                font.bold: true
                                anchors.centerIn: parent
                            }
                        }
                        Text {
                            text: "Back"
                            color: theme.icon
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.020)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Keys.onPressed: {
                    if (api.keys.isCancel(event)) {
                        event.accepted = true;
                        raGameDetail.close();
                    }
                }
            }
        }

        ListModel {
            id: raFriendsModel
        }

        ListModel {
            id: raAchievementsModel
        }
    }
}
