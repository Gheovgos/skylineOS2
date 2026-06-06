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

    Image {
        id: profileIcon
        width: Math.round(screenheight * 0.0833)
        height: width
        source: "../assets/images/profile_icon.png"

        smooth: true
        antialiasing: true
        layer.enabled: enableDropShadows
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 0
            color: "#4D000000"
            radius: 3.0
            samples: 6
        }
    }

    Text {
        id: usernameText
        text: api.memory.has("Username") ? api.memory.get("Username") : ""
        color: theme.text
        font.family: titleFont.name

        // leggermente più piccolo
        font.pixelSize: Math.round(screenheight * 0.028)

        font.bold: true

        // 👇 allineamento verticale corretto
        anchors.verticalCenter: profileIcon.verticalCenter
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
                    verticalCenter: profileIcon.verticalCenter
                    left: profileIcon.right
                    leftMargin: vpx(12)
                }
            }

            RowLayout {
                spacing: vpx(5)
                anchors {
                    verticalCenter: profileIcon.verticalCenter
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

                    anchors {
                        verticalCenter: profileIcon.verticalCenter
                    }
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
                    icon: "../assets/images/navigation/info.svg"
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            // TODO: showInfoScreen();
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
                        if (infoButton.focus) { /* TODO */ } else {
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
                        galleryButton.focus = true;
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
                    id: galleryButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Gallery"
                    icon: "../assets/images/navigation/Gallery.svg"
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            // TODO: showGalleryScreen();
                        }
                    }
                    Keys.onLeftPressed: {
                        navSound.play();
                        storeButton.focus = true;
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
