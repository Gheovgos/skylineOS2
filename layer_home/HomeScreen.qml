import QtQuick 2.12
import QtGraphicalEffects 1.12
import QtQuick.Layouts 1.11
import "../utils.js" as Utils
import "qrc:/qmlutils" as PegasusUtils

FocusScope {
    id: root

    // --- FUNZIONI DI NAVIGAZIONE INTELLIGENTE (Salvano il D-Pad dai pulsanti nascosti) ---
    function moveFocus(currentIndex, direction) {
        var buttons = [infoButton, storeButton, browserButton, galleryButton, backlogButton, controllerButton, settingsButton, suspendButton];
        var step = (direction === "right") ? 1 : -1;
        var n = buttons.length;

        // Calcola il prossimo indice teorico
        var nextIndex = (currentIndex + step + n) % n;

        // Cicla finché non trova il prossimo pulsante effettivamente visibile
        for (var i = 0; i < n - 1; i++) {
            if (buttons[nextIndex].visible) {
                navSound.play();
                buttons[nextIndex].focus = true;
                return;
            }
            nextIndex = (nextIndex + step + n) % n;
        }
        borderSfx.play(); // Suono di blocco se non ci sono alternative valide
    }

    function focusFirstVisibleButton() {
        var buttons = [infoButton, storeButton, browserButton, galleryButton, backlogButton, controllerButton, settingsButton, suspendButton];
        for (var i = 0; i < buttons.length; i++) {
            if (buttons[i].visible) {
                buttons[i].focus = true;
                return true;
            }
        }
        return false;
    }

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
            for (var i = 0; i < activeCollection.count; i++) {
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
                            navSound.play();
                        }
                    }

                    Keys.onRightPressed: {
                        navSound.play();
                        if (!root.focusFirstVisibleButton()) {
                            borderSfx.play();
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

                MenuButton {
                    id: infoButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Feed"
                    visible: (api.memory.get("Feed Button Show") === "Yes")
                    icon: "../assets/images/navigation/info.svg"

                    Keys.onUpPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                    }
                    Keys.onLeftPressed: root.moveFocus(0, "left")
                    Keys.onRightPressed: root.moveFocus(0, "right")
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

                    Keys.onUpPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                    }
                    Keys.onLeftPressed: root.moveFocus(1, "left")
                    Keys.onRightPressed: root.moveFocus(1, "right")
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

                    Keys.onUpPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                    }
                    Keys.onLeftPressed: root.moveFocus(2, "left")
                    Keys.onRightPressed: root.moveFocus(2, "right")
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                            Qt.openUrlExternally((typeof (api.memory.get("Browesr default link")) != "undefined") ? api.memory.get("Browser default link") : "https://");
                        }
                    }
                    onClicked: {
                        browserButton.focus = true;
                        homeSwitcher.currentIndex = -1;
                        navSound.play();
                        Qt.openUrlExternally((typeof (api.memory.get("Browesr default link")) != "undefined") ? api.memory.get("Browser default link") : "https://");
                    }
                }

                MenuButton {
                    id: galleryButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Gallery"
                    icon: "../assets/images/navigation/Gallery.svg"
                    visible: (api.memory.get("Gallery Button Show") === "Yes")

                    Keys.onUpPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                    }
                    Keys.onLeftPressed: root.moveFocus(3, "left")
                    Keys.onRightPressed: root.moveFocus(3, "right")
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

                    Keys.onUpPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                    }
                    Keys.onLeftPressed: root.moveFocus(4, "left")
                    Keys.onRightPressed: root.moveFocus(4, "right")
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                        }
                    }
                    onClicked: {
                        backlogButton.focus = true;
                        homeSwitcher.currentIndex = -1;
                        navSound.play();
                    }
                }

                MenuButton {
                    id: controllerButton
                    width: vpx(56)
                    height: vpx(56)
                    label: "Files"
                    icon: "../assets/images/navigation/Controller.svg"
                    visible: (api.memory.get("Files Button Show") === "Yes")

                    Keys.onUpPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                    }
                    Keys.onLeftPressed: root.moveFocus(5, "left")
                    Keys.onRightPressed: root.moveFocus(5, "right")
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

                    Keys.onUpPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                    }
                    Keys.onLeftPressed: root.moveFocus(6, "left")
                    Keys.onRightPressed: root.moveFocus(6, "right")
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

                    Keys.onUpPressed: {
                        navSound.play();
                        homeSwitcher.focus = true;
                    }
                    Keys.onLeftPressed: root.moveFocus(7, "left")
                    Keys.onRightPressed: root.moveFocus(7, "right")
                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                            event.accepted = true;
                        }
                    }
                    onClicked: {
                        suspendButton.focus = true;
                        homeSwitcher.currentIndex = -1;
                        navSound.play();
                    }
                }
            }
        }
    }
}
