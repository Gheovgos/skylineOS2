import QtQuick 2.12
import QtGraphicalEffects 1.12
import QtQuick.Layouts 1.11
import "../utils.js" as Utils
import "qrc:/qmlutils" as PegasusUtils

//import QtQml 2.0

FocusScope {
    id: root

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
            /*append({
                "name":         "Explore",
                "idx":          -1,
                "icon":         "assets/images/navigation/Explore.png",
                "background":   ""
            })*/
            for (var i = 0; i < activeCollection.count; i++) {
                append(createListElement(i));
            }/*
            append({
                "name":         "Top Games",
                "idx":          -2,
                "icon":         "assets/images/navigation/Top Rated.png",
                "background":   ""
            })//*/
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

    Item {
        id: homeScreenContainer
        width: parent.width
        height: parent.height

        property var batteryStatus: isNaN(api.device.batteryPercent) ? "" : parseInt(api.device.batteryPercent * 100)

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

            // Top bar TODO with Exophase / RA
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

                    // Highlight DIETRO l'immagine (z negativo)
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
                            if (profileButton.focus) {
                                navSound.play();
                            } else {
                                profileButton.focus = true;
                                navSound.play();
                                homeSwitcher.currentIndex = -1;
                            }
                        }
                    }

                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            navSound.play();
                        }
                    }

                    Keys.onRightPressed: {
                        navSound.play();
                        infoButton.focus = true;
                        profileButton.focus = false;
                    }

                    Keys.onDownPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                        homeSwitcher.currentIndex = 0;
                        profileButton.focus = false;
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

                    //12HR-"h:mmap" 24HR-"hh:mm"
                    property var timeSetting: (settings.timeFormat === "12hr") ? "h:mmap  " : "hh:mm  "

                    function set() {
                        sysTime.text = Qt.formatTime(new Date(), timeSetting);
                    }

                    Timer {
                        id: textTimer
                        interval: 60000 // Run the timer every minute
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
                        id: percentTimer
                        interval: 60000 // Run the timer every minute
                        repeat: isNaN(api.device.batteryPercent) ? false : showPercent
                        running: isNaN(api.device.batteryPercent) ? false : showPercent
                        triggeredOnStart: isNaN(api.device.batteryPercent) ? "" : showPercent
                        onTriggered: batteryPercentage.set()
                    }

                    color: theme.text
                    font.family: titleFont.name
                    font.weight: Font.Bold
                    font.letterSpacing: 1
                    font.pixelSize: Math.round(screenheight * 0.0277)
                    //horizontalAlignment: Text.Right

                    Component.onCompleted: font.capitalization = Font.SmallCaps
                    anchors {
                        verticalCenter: sysTime.verticalCenter
                    }
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
                        id: iconTimer
                        interval: 60000 // Run the timer every minute
                        repeat: true
                        running: true
                        triggeredOnStart: true
                        onTriggered: batteryIcon.set()
                    }

                    anchors {
                        verticalCenter: sysTime.verticalCenter
                    }
                    visible: isNaN(api.device.batteryPercent) ? false : true
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
                    anchors {
                        verticalCenter: sysTime.verticalCenter
                    }
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
                        id: chargingIconTimer
                        interval: 10000 // Run the timer every minute
                        repeat: isNaN(api.device.batteryPercent) ? false : true
                        running: isNaN(api.device.batteryPercent) ? false : true
                        triggeredOnStart: isNaN(api.device.batteryPercent) ? false : true
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

            Rectangle {
                id: buttonBar
                anchors.centerIn: parent
                width: buttonMenu.width + vpx(48)
                height: vpx(64)
                radius: height / 2
                color: theme.button

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

                Keys.onUpPressed: {
                    navSound.play();
                    homeSwitcher.focus = true;
                    homeSwitcher.currentIndex = homeSwitcher._index;
                }
                Keys.onDownPressed: {
                    borderSfx.play();
                }

                MenuButton {
                    id: infoButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Feed"
                    visible: {
                        return (api.memory.get("Feed Button Show") === "Yes") ? true : false;
                    }
                    icon: "../assets/images/navigation/info.svg"
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            showButtonScreen("info");
                        }
                    }
                    Keys.onLeftPressed: {
                        navSound.play();
                        suspendButton.focus = true;
                    }
                    Keys.onRightPressed: {
                        navSound.play();
                        storeButton.focus = true;
                    }
                    onClicked: {
                        if (infoButton.focus) {
                            event.accepted = true;
                            showButtonScreen("info");
                        } else {
                            infoButton.focus = true;
                            navSound.play();
                            homeSwitcher.currentIndex = -1;
                        }
                    }
                }

                MenuButton {
                    id: storeButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Store"
                    icon: "../assets/images/navigation/Store.svg"
                    visible: {
                        return (api.memory.get("Store Button Show") === "Yes") ? true : false;
                    }
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            // TODO: showStoreScreen();
                        }
                    }
                    Keys.onLeftPressed: {
                        navSound.play();
                        infoButton.focus = true;
                    }
                    Keys.onRightPressed: {
                        navSound.play();
                        browserButton.focus = true;
                    }
                    onClicked: {
                        if (storeButton.focus) { /* TODO */ } else {
                            storeButton.focus = true;
                            navSound.play();
                            homeSwitcher.currentIndex = -1;
                        }
                    }
                }

                MenuButton {
                    id: browserButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Browser"
                    icon: "../assets/images/navigation/browser.svg"
                    visible: {
                        return (api.memory.get("Browser Button Show") === "Yes") ? true : false;
                    }
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            // TODO: showStoreScreen();
                        }
                    }
                    Keys.onLeftPressed: {
                        navSound.play();
                        storeButton.focus = true;
                    }
                    Keys.onRightPressed: {
                        navSound.play();
                        galleryButton.focus = true;
                    }
                    onClicked: {
                        if (browserButton.focus) { /* TODO */ } else {
                            browserButton.focus = true;
                            navSound.play();
                            homeSwitcher.currentIndex = -1;
                        }
                    }
                }

                MenuButton {
                    id: galleryButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Gallery"
                    icon: "../assets/images/navigation/Gallery.svg"
                    visible: {
                        return (api.memory.get("Gallery Button Show") === "Yes") ? true : false;
                    }
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            // TODO: showGalleryScreen();
                        }
                    }
                    Keys.onLeftPressed: {
                        navSound.play();
                        browserButton.focus = true;
                    }
                    Keys.onRightPressed: {
                        navSound.play();
                        backlogButton.focus = true;
                    }
                    onClicked: {
                        if (galleryButton.focus) { /* TODO */ } else {
                            galleryButton.focus = true;
                            navSound.play();
                            homeSwitcher.currentIndex = -1;
                        }
                    }
                }

                MenuButton {
                    id: backlogButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Backlog"
                    icon: "../assets/images/navigation/backlog.svg"
                    visible: {
                        return (api.memory.get("Backlog Button Show") === "Yes") ? true : false;
                    }
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            // TODO
                        }
                    }
                    Keys.onLeftPressed: {
                        navSound.play();
                        galleryButton.focus = true;
                    }
                    Keys.onRightPressed: {
                        navSound.play();
                        controllerButton.focus = true;
                    }
                    onClicked: {
                        if (backlogButton.focus) { /* TODO */ } else {
                            backlogButton.focus = true;
                            navSound.play();
                            homeSwitcher.currentIndex = -1;
                        }
                    }
                }

                MenuButton {
                    id: controllerButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Controller"
                    icon: "../assets/images/navigation/Controller.svg"
                    visible: {
                        return (api.memory.get("Controller Button Show") === "Yes") ? true : false;
                    }
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            // TODO: showControllerScreen();
                        }
                    }
                    Keys.onLeftPressed: {
                        navSound.play();
                        backlogButton.focus = true;
                    }
                    Keys.onRightPressed: {
                        navSound.play();
                        settingsButton.focus = true;
                    }
                    onClicked: {
                        if (controllerButton.focus) { /* TODO */ } else {
                            controllerButton.focus = true;
                            navSound.play();
                            homeSwitcher.currentIndex = -1;
                        }
                    }
                }

                MenuButton {
                    id: settingsButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Theme Settings"
                    icon: "../assets/images/navigation/Settings.png"

                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            showSettingsScreen();
                        }
                    }
                    Keys.onLeftPressed: {
                        navSound.play();
                        controllerButton.focus = true;
                    }
                    Keys.onRightPressed: {
                        borderSfx.play();
                        suspendButton.focus = true;
                    }
                    onClicked: {
                        if (settingsButton.focus) {
                            showSettingsScreen();
                        } else {
                            settingsButton.focus = true;
                            navSound.play();
                            homeSwitcher.currentIndex = -1;
                        }
                    }
                }

                MenuButton {
                    id: suspendButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Suspend"
                    icon: "../assets/images/navigation/Suspend.svg"
                    visible: {
                        return (api.memory.get("Suspend Button Show") === "Yes") ? true : false;
                    }
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            // TODO: api.device.suspend() o simile
                        }
                    }
                    Keys.onLeftPressed: {
                        navSound.play();
                        settingsButton.focus = true;
                    }
                    Keys.onRightPressed: {
                        borderSfx.play();
                        infoButton.focus = true;
                    }
                    onClicked: {
                        if (suspendButton.focus) { /* TODO */ } else {
                            suspendButton.focus = true;
                            navSound.play();
                            homeSwitcher.currentIndex = -1;
                        }
                    }
                }
            }
        }
    }
}
