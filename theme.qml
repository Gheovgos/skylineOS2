// skylineOS v2

import QtQuick 2.12
import QtQuick.Layouts 1.11
import SortFilterProxyModel 0.2
import QtMultimedia 5.9
import QtGraphicalEffects 1.12
import "qrc:/qmlutils" as PegasusUtils
import "utils.js" as Utils
import "layer_home"
import "layer_grid"
import "layer_settings"
import "layer_help"
import "layer_buttons"
import "Lists"
import "resources" as Resources

FocusScope {
    id: root

    // Load settings
    property var settings: {
        return {
            gameBackground: api.memory.has("Game Background") ? api.memory.get("Game Background") : "Screenshot",
            timeFormat: api.memory.has("Time Format") ? api.memory.get("Time Format") : "12hr",
            wordWrap: api.memory.has("Word Wrap on Titles") ? api.memory.get("Word Wrap on Titles") : "Yes",
            batteryPercentSetting: api.memory.has("Display Battery Percentage") ? api.memory.get("Display Battery Percentage") : "No",
            enableDropShadows: api.memory.has("Enable DropShadows") ? api.memory.get("Enable DropShadows") : "Yes",
            showWifi: api.memory.has("Display Wifi Icon") ? api.memory.get("Display Wifi Icon") : "Yes",
            username: api.memory.has("Username") ? api.memory.get("Username") : "",
            darkMode: api.memory.has("Dark Mode") ? api.memory.get("Dark Mode") : "No",
            homeCardSize: api.memory.has("Home Card Size") ? api.memory.get("Home Card Size") : "35",
            softCount: api.memory.has("Max games on Home Screen") ? parseInt(api.memory.get("Max games on Home Screen")) : 12,
            playBGM: api.memory.has("Background Music") ? api.memory.get("Background Music") : "No",
            showFeed: api.memory.has("Feed Button Show") ? api.memory.get("Feed Button Show") : "Yes",
            showStore: api.memory.has("Store Button Show") ? api.memory.get("Store Button Show") : "Yes",
            showGallery: api.memory.has("Gallery Button Show") ? api.memory.get("Gallery Button Show") : "Yes",
            showController: api.memory.has("Controller Button Show") ? api.memory.get("Controller Button Show") : "Yes",
            showSettings: api.memory.has("Settings Button Show") ? api.memory.get("Settings Button Show") : "Yes",
            showSuspend: api.memory.has("Suspend Button Show") ? api.memory.get("Suspend Button Show") : "Yes"
        };
    }

    // number of games that appear on the homescreen, not including the All Software button
    property int softCount: settings.softCount

    ListLastPlayed {
        id: listRecent
        max: softCount
    }
    ListLastPlayed {
        id: listByLastPlayed
    }
    ListMostPlayed {
        id: listByMostPlayed
    }
    ListPublisher {
        id: listByPublisher
    }
    ListFavorites {
        id: listFavorites
    }
    ListAllGames {
        id: listByTitle
    }
    Resources.Music {
        id: music
    }

    property int currentCollection: api.memory.has('Last Collection') ? api.memory.get('Last Collection') : -1
    property int nextCollection: api.memory.has('Last Collection') ? api.memory.get('Last Collection') : -1
    property var currentGame
    property var softwareList: [listByLastPlayed, listByMostPlayed, listByTitle, listByPublisher, listFavorites]
    property int sortByIndex: api.memory.has('sortIndex') ? api.memory.get('sortIndex') : 0
    property string searchtext
    property bool wordWrap: (settings.wordWrap === "Yes") ? true : false
    property bool showPercent: (settings.batteryPercentSetting === "Yes") ? true : false
    property bool enableDropShadows: (settings.enableDropShadows === "Yes") ? true : false
    property bool playBGM: (settings.playBGM === "Yes") ? true : false

    onNextCollectionChanged: {
        changeCollection();
    }

    function changeCollection() {
        if (nextCollection != currentCollection) {
            currentCollection = nextCollection;
            searchtext = "";
            //gameGrid.currentIndex = 0;
        }
    }

    property int collectionIndex: 0
    property int currentGameIndex: 0
    property int screenmargin: vpx(30)
    property real screenwidth: width
    property real screenheight: height
    property bool widescreen: ((height / width) < 0.7)
    property real helpbarheight: Math.round(screenheight * 0.1041) // Calculated manually based on mockup
    property bool darkThemeActive

    function refreshSettings() {
        settings = {
            gameBackground: api.memory.has("Game Background") ? api.memory.get("Game Background") : "Screenshot",
            timeFormat: api.memory.has("Time Format") ? api.memory.get("Time Format") : "12hr",
            wordWrap: api.memory.has("Word Wrap on Titles") ? api.memory.get("Word Wrap on Titles") : "Yes",
            batteryPercentSetting: api.memory.has("Display Battery Percentage") ? api.memory.get("Display Battery Percentage") : "No",
            enableDropShadows: api.memory.has("Enable DropShadows") ? api.memory.get("Enable DropShadows") : "Yes",
            playBGM: api.memory.has("Background Music") ? api.memory.get("Background Music") : "No",
            showWifi: api.memory.has("Display Wifi Icon") ? api.memory.get("Display Wifi Icon") : "No",
            homeCardSize: api.memory.has("Home Card Size") ? api.memory.get("Home Card Size") : "35"
        };
    }

    function showSoftwareScreen() {
        /*homeScreen.visible = false;
        softwareScreen.visible = true;*/
        refreshSettings();
        softwareScreen.focus = true;
        toSoftware.play();
    }

    function showSettingsScreen() {
        settingsScreen.focus = true;
        settingsSfx.play();
    }

    function showButtonScreen(menu) {
        switch (menu) {
            case "info":
                infoScreen.focus = true;
                break;
            case "backlog":
                backlogScreen.focus = true;
                break;
            case "suspend":
                suspendScreen.focus = true;
                break;
            default:
                break;
        }
        settingsSfx.play();
    }

    function showHomeScreen() {
        refreshSettings();
        homeScreen.focus = true;
        currentCollection = -1;
        homeSfx.play();
    }

    function playGame() {
        root.state = "playgame";

        launchSfx.play();
    }

    function playSoftware() {
        root.state = "playsoftware";

        launchSfx.play();
    }

    function pushToStackTimer(game) {
        api.memory.set("STACK_TIMER", [game.title, Math.floor(Date.now() / 1000)]);
        api.memory.set("LAST_STACK_ITEM", game.title);
        console.log("Timer started for:", game.title, "at:", Math.floor(Date.now() / 1000));
    }

    function popToStackTimer() {
        if (api.memory.has("LAST_STACK_ITEM")) {
            var last = api.memory.get("LAST_STACK_ITEM");
            var startTime = api.memory.get("STACK_TIMER")[1];
            var elapsed = Math.floor(Date.now() / 1000) - startTime;

            console.log("Elapsed seconds:", elapsed, "for game:", last);

            var prevTime = api.memory.has(last) ? parseInt(api.memory.get(last)) : 0;
            api.memory.set(last, prevTime + elapsed);

            console.log("Nuovo totale per", last, ":", api.memory.get(last));
        }

        api.memory.unset("LAST_STACK_ITEM");
        api.memory.unset("STACK_TIMER");
    }

    // Launch the current game from HomeBar
    function launchGame(game) {
        console.log("Launching Game: ", game.title);
        pushToStackTimer(game);

        api.memory.set('Last Collection', currentCollection);
        if (game != null)
            game.launch();
        else
            currentGame.launch();
    }

    // Launch current game from SoftwareScreen
    function launchSoftware() {
        api.memory.set('Last Collection', currentCollection);
        softwareList[sortByIndex].currentGame(currentGameIndex).launch();
        //currentGame.launch();
    }

    // Preference order for Game Backgrounds, tiles always come first due to assumption that it's set manually
    function getGameBackground(gameData, preference) {
        switch (preference) {
        case "Screenshot":
            return gameData ? gameData.assets.tile || gameData.assets.screenshots[0] || gameData.assets.background || gameData.assets.boxFront || "" : "";
        case "Fanart":
            return gameData ? gameData.assets.tile || gameData.assets.background || gameData.assets.screenshots[0] || gameData.assets.boxFront || "" : "";
        case "Boxart":
            return gameData ? gameData.assets.tile || gameData.assets.boxFront || gameData.assets.screenshots[0] || gameData.assets.background || "" : "";
        default:
            return "";
        }
    }

    // Theme settings
    FontLoader {
        id: titleFont
        source: "assets/fonts/Nintendo_Switch_UI_Font.ttf"
    }

    property var themeLight: {
        return {
            main: "#EBEBEB",
            secondary: "#2D2D2D",
            accent: "#10AEBE",
            highlight: "white",
            text: "#2C2C2C",
            button: "white",
            icon: "#7e7e7e",
            press: "#7Fc0f0f3"
        };
    }

    property var themeDark: {
        return {
            main: "#2D2D2D",
            secondary: "#EBEBEB",
            accent: "#1d9bf3",
            highlight: "black",
            text: "white",
            button: "#515151",
            icon: "white",
            press: "#591d9bf3"
        };
    }

    property var theme: api.memory.get("Dark Mode") === "No" ? themeLight : themeDark

    // State settings
    states: [
        State {
            name: "homescreen"
            when: homeScreen.focus == true
        },
        State {
            name: "softwarescreen"
            when: softwareScreen.focus == true
        },
        State {
            name: "settingsscreen"
            when: settingsScreen.focus == true
        },
        State {
            name: "infoscreen"
            when: infoScreen.focus == true
        },
        State {
            name: "backlogscreen"
            when: backlogScreen.focus == true
        },
        State {
            name: "suspendscreen"
            when: suspendScreen.focus == true
        },
        State {
            name: "playgame"
        },
        State {
            name: "playsoftware"
        }
    ]

    property int currentScreenID: -3

    transitions: [
        Transition {
            from: "homescreen"
            to: "softwarescreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: softwareScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: softwareScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
            }
        },
        Transition {
            from: "homescreen"
            to: "settingsscreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: settingsScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: settingsScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
            }
        },
        Transition {
            from: "softwarescreen"
            to: "homescreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: softwareScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: softwareScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
            }
        },
        Transition {
            from: "settingsscreen"
            to: "homescreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: settingsScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: settingsScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
            }
        },
        Transition {
            to: "playgame"
            SequentialAnimation {
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PauseAnimation {
                    duration: 200
                }
                ScriptAction {
                    script: launchGame(currentGame)
                }
            }
        },
        Transition {
            to: "playsoftware"
            SequentialAnimation {
                PropertyAnimation {
                    target: softwareScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PauseAnimation {
                    duration: 200
                }
                ScriptAction {
                    script: launchSoftware()
                }
            }
        },
        Transition {
            from: "homescreen"
            to: "infoscreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: infoScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: infoScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
            }
        },
        Transition {
            from: "infoscreen"
            to: "homescreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: infoScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: infoScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
            }
        },
        Transition {
            from: "homescreen"
            to: "backlogscreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: backlogScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: backlogScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
            }
        },
        Transition {
            from: "backlogscreen"
            to: "homescreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: backlogScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: backlogScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
            }
        },
        Transition {
            from: "homescreen"
            to: "suspendscreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: suspendScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: suspendScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
            }
        },
        Transition {
            from: "suspendscreen"
            to: "homescreen"
            SequentialAnimation {
                PropertyAnimation {
                    target: suspendScreen
                    property: "opacity"
                    to: 0
                    duration: 200
                }
                PropertyAction {
                    target: suspendScreen
                    property: "visible"
                    value: false
                }
                PropertyAction {
                    target: homeScreen
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    target: homeScreen
                    property: "opacity"
                    to: 1
                    duration: 200
                }
            }
        },
        Transition {
            from: ""
            to: "homescreen"
            ParallelAnimation {
                NumberAnimation {
                    target: homeScreen
                    property: "scale"
                    from: 1.2
                    to: 1.0
                    duration: 200
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: homeScreen
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                }
            }
        }
    ]

    // Background
    Rectangle {
        id: background
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        color: theme.main
    }

    //starting collection is set here
    Component.onCompleted: {
        state: "homescreen";
        refreshSettings();
        popToStackTimer();
        currentCollection = -1;
        api.memory.unset('Last Collection');
        homeSfx.play();
    }

    // Home screen
    HomeScreen {
        id: homeScreen
        focus: true
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: helpBar.top
        }
    }

    // List specific input
    /*Keys.onPressed: {
        // disabled
        /*if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            toggleDarkMode();
        }
    }*/

    SettingsScreen {
        id: settingsScreen
        opacity: 0
        visible: false
        anchors {
            left: parent.left
            leftMargin: screenmargin
            right: parent.right
            rightMargin: screenmargin
            top: parent.top
            bottom: helpBar.top
        }
    }

    InfoScreen {
        id: infoScreen
        opacity: 0
        visible: false
        anchors {
            left: parent.left
            leftMargin: screenmargin
            right: parent.right
            rightMargin: screenmargin
            top: parent.top
            bottom: helpBar.top
        }
    }

    BacklogScreen {
        id: backlogScreen
        opacity: 0
        visible: false
        anchors {
            left: parent.left
            leftMargin: screenmargin
            right: parent.right
            rightMargin: screenmargin
            top: parent.top
            bottom: helpBar.top
        }
    }

    SuspendScreen {
        id: suspendScreen
        opacity: 0
        visible: false
        anchors {
            left: parent.left
            leftMargin: screenmargin
            right: parent.right
            rightMargin: screenmargin
            top: parent.top
            bottom: helpBar.top
        }
    }

    // All Software screen
    SoftwareScreen {
        id: softwareScreen
        opacity: 0
        visible: false
        anchors {
            left: parent.left// leftMargin: screenmargin
            right: parent.right// rightMargin: screenmargin
            top: parent.top
            bottom: helpBar.top
        }
    }

    //Changes Sort Option
    function cycleSort() {
        selectSfx.play();
        if (sortByIndex < softwareList.length - 1)
            sortByIndex++;
        else
            sortByIndex = 0;
        api.memory.set('sortIndex', sortByIndex);
    }

    // Help bar
    Item {
        id: helpBar
        anchors {
            left: parent.left
            leftMargin: screenmargin
            right: parent.right
            rightMargin: screenmargin
            bottom: parent.bottom
        }
        height: helpbarheight

        Rectangle {

            anchors.fill: parent
            color: theme.main
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: theme.secondary
        }

        ControllerHelp {
            id: controllerHelp
            width: parent.width
            height: parent.height
            anchors {
                bottom: parent.bottom
            }
            showBack: !homeScreen.focus
            showCollControls: softwareScreen.focus
            showFav: softwareScreen.focus || homeScreen.focus
            showDetails: homeScreen.focus 
        }
    }

    SoundEffect {
        id: navSound
        source: "assets/audio/Klick.wav"
        volume: 1.0
    }

    SoundEffect {
        id: toSoftware
        source: "assets/audio/EnterBack.wav"
        volume: 1.0
    }

    SoundEffect {
        id: fillList
        source: "assets/audio/Icons.wav"
        volume: 1.0
    }

    SoundEffect {
        id: backSfx
        source: "assets/audio/Nock.wav"
        volume: 1.0
    }

    SoundEffect {
        id: launchSfx
        source: "assets/audio/PopupRunTitle.wav"
        volume: 1.0
    }

    SoundEffect {
        id: homeSfx
        source: "assets/audio/Home.wav"
        volume: 1.0
    }

    SoundEffect {
        id: turnOnSfx
        source: "assets/audio/Turn On.wav"
        volume: 1.0
    }

    SoundEffect {
        id: turnOffSfx
        source: "assets/audio/Turn Off.wav"
        volume: 1.0
    }

    SoundEffect {
        id: selectSfx
        source: "assets/audio/This One.wav"
        volume: 1.0
    }

    SoundEffect {
        id: settingsSfx
        source: "assets/audio/Settings.wav"
        volume: 1.0
    }

    /* This sound effect is broken on RetroPie on Raspberry Pi 4. Reason unknown.
    SoundEffect {
        id: menuNavSfx
        source: "assets/audio/Tick.wav"
        volume: 1.0
    }*/

    SoundEffect {
        id: borderSfx
        source: "assets/audio/Border.wav"
        volume: 0.25
    }
}
