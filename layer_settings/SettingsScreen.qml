import QtQuick 2.0
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.0

FocusScope {
    id: root

    ListModel {
        id: settingsModel

        ListElement {
            settingName: "Username"
            settingSubtitle: ""
            setting: ""
            type: "input"
        }

        ListElement {
            settingName: "Game Background"
            settingSubtitle: ""
            setting: "Screenshot,Fanart,Boxart"
            type: "toggle"
        }

        ListElement {
            settingName: "Background Music"
            settingSubtitle: "(Requires Reload)"
            setting: "No,Yes"
            type: "toggle"
        }

        ListElement {
            settingName: "Word Wrap on Titles"
            settingSubtitle: "(Requires Reload)"
            setting: "Yes,No"
            type: "toggle"
        }
    }

    property var generalPage: {
        return {
            pageName: "General",
            listmodel: settingsModel
        };
    }

    ListModel {
        id: homeSettingsModel
        ListElement {
            settingName: "Dark Mode"
            settingSubtitle: ""
            setting: "No,Yes"
            type: "toggle"
        }
        ListElement {
            settingName: "Time Format"
            settingSubtitle: ""
            setting: "12hr,24hr"
            type: "toggle"
        }
        ListElement {
            settingName: "Display Battery Percentage"
            settingSubtitle: "(%)"
            setting: "No,Yes"
            type: "toggle"
        }
        ListElement {
            settingName: "Display Wifi Icon"
            settingSubtitle: ""
            setting: "No,Yes"
            type: "toggle"
        }
        ListElement {
            settingName: "Home Card Size"
            settingSubtitle: "%"
            setting: "35"
            type: "input"
        }
        ListElement {
            settingName: "Max games on Home Screen"
            settingSubtitle: ""
            setting: "35"
            type: "input"
        }
    }

    property var homePage: {
        return {
            pageName: "Home Screen",
            listmodel: homeSettingsModel
        };
    }

    ListModel {
        id: menuButtonModel

        ListElement {
            settingName: "Feed Button Show"
            settingSubtitle: ""
            setting: "Yes,No"
            type: "toggle"
        }

        ListElement {
            settingName: "Store Button Show"
            settingSubtitle: ""
            setting: "Yes,No"
            type: "toggle"
        }

        ListElement {
            settingName: "Gallery Button Show"
            settingSubtitle: ""
            setting: "Yes,No"
            type: "toggle"
        }

        ListElement {
            settingName: "Backlog Button Show"
            settingSubtitle: ""
            setting: "Yes,No"
            type: "toggle"
        }

        ListElement {
            settingName: "Controller Button Show"
            settingSubtitle: ""
            setting: "Yes,No"
            type: "toggle"
        }

/*         ListElement {
            settingName: "Settings Button Show"
            settingSubtitle: ""
            setting: "Yes,No"
            type: "toggle"
        } */

        ListElement {
            settingName: "Suspend Button Show"
            settingSubtitle: ""
            setting: "Yes,No"
            type: "toggle"
        }
    }

    property var buttonModelPage: {
        return {
            pageName: "Buttons Settings",
            listmodel: menuButtonModel
        };
    }

    ListModel {
        id: raModel
        ListElement {
            settingName: "RetroAchievements Username"
            settingSubtitle: ""
            setting: ""
            type: "input"
        }
        ListElement {
            settingName: "RetroAchievements API Key"
            settingSubtitle: ""
            setting: ""
            type: "input"
        }
        ListElement {
            settingName: "Login"
            settingSubtitle: ""
            setting: "OK"
            type: "button"
        }

        ListElement {
            settingName: "Logout"
            settingSubtitle: ""
            setting: "Logout"
            type: "button"
        }
    }

    property var raPage: {
        return {
            pageName: "Retroachievements",
            listmodel: raModel
        };
    }

    ListModel {
        id: perfSettingsModel
        ListElement {
            settingName: "Enable DropShadows"
            settingSubtitle: ""
            setting: "Yes, No"
            type: "toggle"
        }
        ListElement {
            settingName: "Restore All Settings"
            settingSubtitle: ""
            setting: "Reset"
            type: "button"
        }
    }

    property var performancePage: {
        return {
            pageName: "Advanced Settings",
            listmodel: perfSettingsModel
        };
    }

    property var settingsArr: [generalPage, homePage, buttonModelPage, raPage, performancePage]

    property real itemheight: vpx(50)

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
            source: "../assets/images/navigation/Settings.png"
            sourceSize.width: vpx(64)
            sourceSize.height: vpx(64)

            anchors {
                top: parent.top
                topMargin: Math.round(screenheight * 0.0416)
                left: parent.left
                leftMargin: vpx(38)
            }

            Text {
                id: collectionTitle
                text: "Theme Settings"
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

        ColorOverlay {
            anchors.fill: headerIcon
            source: headerIcon
            color: theme.text
            cached: true
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: false
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

    ListView {
        id: pagelist

        focus: true
        anchors {
            top: topBar.bottom
            bottom: parent.bottom //bottomMargin: helpMargin
            left: parent.left //leftMargin: globalMargin
        }
        width: vpx(300)
        model: settingsArr
        delegate: Component {
            id: pageDelegate

            Item {
                id: pageRow

                property bool selected: ListView.isCurrentItem

                width: ListView.view.width
                height: itemheight

                // Page name
                Text {
                    id: pageNameText

                    text: modelData.pageName
                    color: theme.text
                    //font.family: subtitleFont.name
                    font.pixelSize: vpx(22)
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                    opacity: selected ? 1 : 0.2

                    width: contentWidth
                    height: parent.height
                    anchors {
                        left: parent.left
                        leftMargin: vpx(25)
                    }
                }

                // Mouse/touch functionality
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: false
                    onEntered: { /*navSound.play();*/}
                    onClicked: {
                        navSound.play();
                        pagelist.currentIndex = index;
                        settingsList.focus = true;
                    }
                }
            }
        }
        Keys.onUpPressed: {
            navSound.play();
            decrementCurrentIndex();
        }
        Keys.onDownPressed: {
            navSound.play();
            incrementCurrentIndex();
        }
        Keys.onPressed: {
            // Accept
            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true;
                navSound.play();
                settingsList.focus = true;
            }
            // Back
            if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                event.accepted = true;
                showHomeScreen();
            }
        }
    }

    Rectangle {
        anchors {
            left: pagelist.right
            top: pagelist.top
            bottom: pagelist.bottom
        }
        width: vpx(1)
        color: theme.text
        opacity: 0.1
    }

    ListView {
        id: settingsList

        model: settingsArr[pagelist.currentIndex].listmodel
        delegate: settingsDelegate

        anchors {
            top: topBar.bottom
            bottom: parent.bottom
            left: pagelist.right //leftMargin: globalMargin
            right: parent.right //rightMargin: globalMargin
        }
        width: vpx(500)

        spacing: vpx(0)
        orientation: ListView.Vertical

        preferredHighlightBegin: settingsList.height / 2 - itemheight
        preferredHighlightEnd: settingsList.height / 2
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 100
        clip: false

        Component {
            id: settingsDelegate

            Item {
                id: settingRow

                property bool selected: ListView.isCurrentItem && settingsList.focus
                property variant settingList: setting.split(',')
                property int savedIndex: api.memory.get(settingName + 'Index') || 0

                property bool editMode: false
                property string currentInput: api.memory.get(settingName) || setting

                function saveSetting() {
                    if (type === "input") {
                        api.memory.set(settingName, currentInput);
                    } else {
                        console.log("-----------------")
                        api.memory.set(settingName + 'Index', savedIndex);
                        api.memory.set(settingName, settingList[savedIndex]);
                        console.log(settingList[savedIndex])
                        console.log(api.memory.get(settingName))
                        console.log("-----------------")
                    }
                }

                function nextSetting() {
                    if (savedIndex != settingList.length - 1)
                        savedIndex++;
                    else
                        savedIndex = 0;
                }

                function prevSetting() {
                    if (savedIndex > 0)
                        savedIndex--;
                    else
                        savedIndex = settingList.length - 1;
                }

                function handleKey(event) {
                    if (event.key === Qt.Key_Backspace) {
                        currentInput = currentInput.slice(0, -1);
                        return;
                    }
                    if (api.keys.isAccept(event) || event.key === Qt.Key_Return) {
                        api.memory.set(settingName, currentInput);
                        editMode = false;
                        return;
                    }
                    if (api.keys.isCancel(event)) {
                        currentInput = api.memory.get(settingName) || setting;
                        editMode = false;
                        return;
                    }
                    var inputChar = event.text;
                    if (inputChar && inputChar.length === 1)
                        currentInput += inputChar;
                }

                width: ListView.view.width
                height: itemheight

                // Setting name
                Text {
                    id: settingNameText

                    text: settingSubtitle != "" ? settingName + " " + settingSubtitle + ": " : settingName + ": "
                    color: theme.text
                    //font.family: subtitleFont.name
                    font.pixelSize: vpx(20)
                    verticalAlignment: Text.AlignVCenter
                    opacity: selected ? 1 : 0.2

                    width: contentWidth
                    height: parent.height
                    anchors {
                        left: parent.left
                        leftMargin: vpx(25)
                    }
                }
                // Setting value
                Loader {
                    id: valueLoader
                    anchors {
                        right: parent.right
                        rightMargin: vpx(25)
                        verticalCenter: parent.verticalCenter
                    }
                    opacity: selected ? 1 : 0.2

                    sourceComponent: {
                        if (type === "input")
                            return inputComponent;
                        if (type === "button")
                            return buttonComponent;
                        return toggleComponent;
                    }

                    Component {
                        id: toggleComponent
                        Text {
                            text: settingList[savedIndex]
                            color: theme.accent
                            font.pixelSize: vpx(20)
                            verticalAlignment: Text.AlignVCenter
                            height: itemheight
                        }
                    }

                    Component {
                        id: inputComponent
                        Text {
                            text: api.memory.get(settingName) || setting
                            color: theme.accent
                            font.pixelSize: vpx(20)
                            verticalAlignment: Text.AlignVCenter
                            height: itemheight
                        }
                    }

                    Component {
                        id: buttonComponent
                        Rectangle {
                            width: btnText.width + vpx(24)
                            height: vpx(30)
                            radius: height / 2
                            color: theme.accent

                            Text {
                                id: btnText
                                anchors.centerIn: parent
                                text: setting
                                color: "white"
                                font.family: titleFont.name
                                font.pixelSize: vpx(18)
                                font.bold: true
                            }
                        }
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        leftMargin: vpx(25)
                        right: parent.right
                        rightMargin: vpx(25)
                        bottom: parent.bottom
                    }
                    color: theme.text
                    opacity: selected ? 0.1 : 0
                    height: vpx(1)
                }

                // Input handling
                // Next setting
                Keys.onRightPressed: {
                    selectSfx.play();
                    nextSetting();
                    saveSetting();
                }
                // Previous setting
                Keys.onLeftPressed: {
                    selectSfx.play();
                    prevSetting();
                    saveSetting();
                }

                Keys.onPressed: {
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        if(typeof type != "undefined") {
                            if (type === "input") {
                            inputPanel.open(settingName, setting);
                            } else if (type === "button") {
                                selectSfx.play();
                                if (settingName === "Login") {
                                    selectSfx.play();
                                    tryRALogin();
                                } else if (settingName === "Restore All Settings") {
                                    restoreAllSettings();
                                } else if (settingName === "Logout") {
                                    api.memory.unset("RA_LoggedIn");
                                    api.memory.unset("RA_Username");
                                    raLoginStatus = "";
                                    selectSfx.play();
                                }
                            }
                        } else {
                            selectSfx.play();
                            nextSetting();
                            saveSetting();
                        } 
                    }
                    if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        navSound.play();
                        pagelist.focus = true;
                    }
                }

                // Mouse/touch functionality
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: false //settings.MouseHover == "Yes"
                    onEntered: { /*navSound.play();*/ }
                    onClicked: {
                        if (selected) {
                            selectSfx.play();
                            nextSetting();
                            saveSetting();
                        } else {
                            navSound.play();
                            settingsList.focus = true;
                            settingsList.currentIndex = index;
                        }
                    }
                    onPressAndHold: {
                        if (type === "input") {
                            inputPanel.open(settingName, setting);
                        } else if (type === "button") {
                            selectSfx.play();
                            if (settingName === "Login") {
                                tryRALogin();
                            }
                        } else {
                            selectSfx.play();
                            nextSetting();
                            saveSetting();
                        }
                    }
                }
            }
        }

        Keys.onUpPressed: {
            var cur = settingsList.currentItem;
            if (cur && cur.editMode) {
                event.accepted = true;
                return;
            }
            navSound.play();
            decrementCurrentIndex();
        }
        Keys.onDownPressed: {
            var cur = settingsList.currentItem;
            if (cur && cur.editMode) {
                event.accepted = true;
                return;
            }
            navSound.play();
            incrementCurrentIndex();
        }
        Keys.onPressed: {
            var cur = settingsList.currentItem;
            if (cur && cur.editMode) {
                event.accepted = true;
                cur.handleKey(event);
            }
        }
    }

    property string raLoginStatus: ""

    function tryRALogin() {
        var username = api.memory.get("RetroAchievements Username") || "";
        var apiKey = api.memory.get("RetroAchievements API Key") || "";

        if (!username || !apiKey) {
            raLoginStatus = "error";
            return;
        }

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            console.log(xhr.status);
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        if (data && data.User) {
                            raLoginStatus = "ok";
                            api.memory.set("RA_LoggedIn", "Yes");
                            api.memory.set("RA_Username", data.User);
                        } else {
                            raLoginStatus = "error";
                            api.memory.set("RA_LoggedIn", "No");
                        }
                    } catch (e) {
                        raLoginStatus = "error";
                    }
                } else {
                    raLoginStatus = "error";
                }
            }
        };

        raLoginStatus = "loading";
        xhr.open("GET", "https://retroachievements.org/API/API_GetUserProfile.php?u=" + username + "&y=" + apiKey);
        xhr.send();
    }

    Text {
        anchors {
            bottom: inputPanel.top
            horizontalCenter: parent.horizontalCenter
            bottomMargin: vpx(16)
        }
        text: {
            if (raLoginStatus === "ok")
                return "Login OK";
            if (raLoginStatus === "error")
                return "Invalid credentials";
            if (raLoginStatus === "loading")
                return "Loading...";
            return "";
        }
        color: {
            if (raLoginStatus === "ok")
                return "#10B981";
            if (raLoginStatus === "error")
                return "#EF4444";
            return theme.icon;
        }
        font.family: titleFont.name
        font.pixelSize: Math.round(screenheight * 0.020)
        font.bold: raLoginStatus === "ok"
        visible: raLoginStatus !== ""
        z: 101
    }

    function restoreAllSettings() {
        api.memory.unset("Game Background");
        api.memory.unset("Game BackgroundIndex");
        api.memory.unset("Background Music");
        api.memory.unset("Background MusicIndex");
        api.memory.unset("Word Wrap on Titles");
        api.memory.unset("Word Wrap on TitlesIndex");
        api.memory.unset("Dark Mode");
        api.memory.unset("Dark ModeIndex");
        api.memory.unset("Time Format");
        api.memory.unset("Time FormatIndex");
        api.memory.unset("Display Battery Percentage");
        api.memory.unset("Display Battery PercentageIndex");
        api.memory.unset("Display Wifi Icon");
        api.memory.unset("Display Wifi IconIndex");
        api.memory.unset("Home Card Size");
        api.memory.unset("Max games on Home Screen");
        api.memory.unset("Enable DropShadows");
        api.memory.unset("Enable DropShadowsIndex");
        api.memory.unset("Username");
        raLoginStatus = "";
        selectSfx.play();
    }

    // INPUT
    Rectangle {
        id: inputPanel
        visible: false
        anchors.centerIn: parent
        width: Math.round(screenwidth * 0.4)
        height: vpx(180)
        radius: vpx(20)
        color: theme.button
        z: 100

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: vpx(6)
            radius: 20
            samples: 32
            color: "#60000000"
        }

        // Overlay
        Rectangle {
            parent: root
            anchors.fill: parent
            color: "black"
            opacity: inputPanel.visible ? 0.5 : 0
            z: 99
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
            MouseArea {
                anchors.fill: parent
                enabled: inputPanel.visible
            }
        }

        property string settingKey: ""
        property string settingDefault: ""
        property string inputValue: ""

        TextInput {
            id: hiddenInput
            visible: false
            focus: inputPanel.visible
            Keys.onPressed: {
                if (event.key === Qt.Key_Backspace) {
                    event.accepted = true;
                    inputPanel.inputValue = inputPanel.inputValue.slice(0, -1);
                    return;
                }
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    event.accepted = true;
                    api.memory.set(inputPanel.settingKey, inputPanel.inputValue);
                    inputPanel.close();
                    return;
                }
                if (event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    inputPanel.close();
                    return;
                }
            }
            onTextChanged: {
                if (text !== "") {
                    inputPanel.inputValue += text;
                    text = "";
                }
            }
        }

        function open(key, defaultVal) {
            settingKey = key;
            settingDefault = defaultVal;
            inputValue = api.memory.get(key) || defaultVal;
            visible = true;
            hiddenInput.focus = true;
            Qt.inputMethod.show();
        }

        function close() {
            Qt.inputMethod.hide();
            visible = false;
            settingsList.focus = true;
        }

        Column {
            anchors {
                fill: parent
                margins: vpx(24)
            }
            spacing: vpx(16)

            Text {
                text: inputPanel.settingKey
                color: theme.text
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.022)
                font.bold: true
                opacity: 0.6
            }

            // Input
            Rectangle {
                width: parent.width
                height: vpx(48)
                radius: vpx(10)
                color: theme.main

                Row {
                    anchors {
                        fill: parent
                        leftMargin: vpx(12)
                        rightMargin: vpx(12)
                    }
                    spacing: vpx(4)

                    Text {
                        text: inputPanel.inputValue
                        color: theme.text
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.028)
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: vpx(2)
                        height: vpx(24)
                        color: theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on opacity {
                            running: inputPanel.visible
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: 0
                                duration: 500
                            }
                            NumberAnimation {
                                to: 1
                                duration: 500
                            }
                        }
                    }
                }
            }

            // Hint
            Text {
                text: "Enter to confirm • Esc to undo"
                color: theme.icon
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.016)
                opacity: 0.5
            }
        }

        Keys.onPressed: {
            if (!visible)
                return;
            event.accepted = true;

            if (event.key === Qt.Key_Backspace) {
                inputValue = inputValue.slice(0, -1);
                return;
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || api.keys.isAccept(event)) {
                api.memory.set(settingKey, inputValue);
                close();
                return;
            }
            if (event.key === Qt.Key_Escape || api.keys.isCancel(event)) {
                close();
                return;
            }
            var inputChar = event.text;
            if (inputChar && inputChar.length === 1)
                inputValue += inputChar;
        }
    }
}
