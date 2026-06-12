import QtQuick 2.12

FocusScope {
    id: infoScreenRoot

    // 1. CHOOSE THE FEED URL
    property string rawFeeds: api.memory.has("Feed RSS List") ? api.memory.get("Feed RSS List") : "https://www.polygon.com/rss/index.xml"
    property var feedsArray: rawFeeds.split("§")
    property string activeFeedUrl: feedsArray[0].trim()
    property bool isLoading: true

    // 2. PROPERTIES TO HOLD THE SELECTED ARTICLE DATA FOR THE POPUP
    property string selectedTitle: ""
    property string selectedDate: ""
    property string selectedDescription: ""
    property string selectedImageUrl: ""

    // Helper function to open popup and fill data safely
    function openArticle(title, date, desc, img) {
        infoScreenRoot.selectedTitle = title;
        infoScreenRoot.selectedDate = date;
        infoScreenRoot.selectedDescription = desc ? desc : "No description text available for this article.";
        infoScreenRoot.selectedImageUrl = img;
        articleContentPopup.visible = true;
    }

    // 3. THE DYNAMIC CONTAINER FOR REAL ARTICLES
    ListModel {
        id: articlesModel
    }

    // 4. JAVASCRIPT NETWORK FETCH & REGEX PARSER
    function fetchRSSContent() {
        infoScreenRoot.isLoading = true;
        articlesModel.clear();

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    parseXMLText(xhr.responseText);
                } else {
                    articlesModel.append({
                        "articleTitle": "Error connection to feed server",
                        "articleDate": "HTTP Status: " + xhr.status,
                        "articleImageUrl": "",
                        "articleDescription": ""
                    });
                    infoScreenRoot.isLoading = false;
                }
            }
        }
        xhr.open("GET", infoScreenRoot.activeFeedUrl);
        xhr.send();
    }

    function parseXMLText(xmlText) {
        var itemRegex = /<(item|entry)>([\s\S]*?)<\/\1>/g;
        var match;
        var count = 0;

        while ((match = itemRegex.exec(xmlText)) !== null && count < 15) {
            var itemContent = match[2];

            var titleMatch = itemContent.match(/<title>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?<\/title>/);
            var dateMatch = itemContent.match(/<(pubDate|published)>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?<\/\1>/);
            var imageMatch = itemContent.match(/<enclosure[\s\S]*?url=["']([\s\S]*?)["']/) || itemContent.match(/<media:content[\s\S]*?url=["']([\s\S]*?)["']/) || itemContent.match(/<img[\s\S]*?src=["']([\s\S]*?)["']/);
            var descriptionMatch = itemContent.match(/<description>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?<\/description>/) || itemContent.match(/<summary>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?<\/summary>/);

            var title = titleMatch ? titleMatch[1].trim() : "No Title available";
            var date = dateMatch ? dateMatch[1].trim() : "Recent news";
            var imageUrl = imageMatch ? imageMatch[1].trim() : "";
            var description = descriptionMatch ? descriptionMatch[1].trim() : "";

            title = title.replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"');
            description = description.replace(/<[^>]*>?/gm, ''); 
            description = description.replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"');

            if (date.length > 25) date = date.substring(0, 25);

            articlesModel.append({
                "articleTitle": title,
                "articleDate": date,
                "articleImageUrl": imageUrl,
                "articleDescription": description
            });
            count++;
        }

        if (articlesModel.count === 0) {
            articlesModel.append({
                "articleTitle": "No articles found in this feed",
                "articleDate": "Check if the URL structure is a valid RSS endpoint.",
                "articleImageUrl": "",
                "articleDescription": ""
            });
        }
        infoScreenRoot.isLoading = false;
    }

    Component.onCompleted: fetchRSSContent()
    onActiveFeedUrlChanged: fetchRSSContent()

    // --- VISUAL LAYOUT ---
    Item {
        anchors.fill: parent
        anchors.margins: vpx(40)

        // Nintendo Switch Header
        Text {
            id: headerTitle
            text: "Gaming Live Feed"
            color: theme.text
            font.family: titleFont.name
            font.pixelSize: vpx(36)
            font.bold: true
        }

        Text {
            id: headerSubtitle
            anchors.top: headerTitle.bottom
            anchors.topMargin: vpx(8)
            text: infoScreenRoot.isLoading ? "Downloading live data stream..." : "Source: " + infoScreenRoot.activeFeedUrl
            color: theme.icon
            font.family: titleFont.name
            font.pixelSize: vpx(16)
            elide: Text.ElideRight
            width: parent.width
        }

        Rectangle {
            id: headerSeparator
            anchors.top: headerSubtitle.bottom
            anchors.topMargin: vpx(20)
            width: parent.width
            height: vpx(2)
            color: theme.secondary
        }

        Row {
            anchors.top: headerSeparator.bottom
            anchors.topMargin: vpx(30)
            anchors.bottom: parent.bottom
            width: parent.width
            spacing: vpx(40)

            // LEFT SIDE: Interactive Image Box
            Rectangle {
                width: vpx(420)
                height: vpx(260)
                color: theme.button
                border.color: theme.secondary
                border.width: vpx(2)
                radius: vpx(8)
                clip: true
                anchors.verticalCenter: parent.verticalCenter
                // Sicuro e reattivo basato sulle proprietà estratte dal modello
                visible: feedsListView.currentItem && articlesModel.count > 0 && articlesModel.get(feedsListView.currentIndex).articleImageUrl !== ""

                Image {
                    anchors.fill: parent
                    source: (feedsListView.currentItem && articlesModel.count > 0) ? articlesModel.get(feedsListView.currentIndex).articleImageUrl : ""
                    fillMode: Image.PreserveAspectCrop
                }
                
                Rectangle {
                    width: vpx(95)
                    height: vpx(26)
                    color: "#E60012"
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: vpx(12)
                    radius: vpx(4)
                    
                    Text {
                        text: "ONLINE NEWS"
                        color: "white"
                        font.bold: true
                        font.pixelSize: vpx(11)
                        anchors.centerIn: parent
                    }
                }
            }

            // RIGHT SIDE: ListView mapping the parsed real headlines
            ListView {
                id: feedsListView
                // Cambia larghezza dinamicamente se l'articolo corrente ha un'immagine valida nel modello
                width: parent.width - ((feedsListView.currentItem && articlesModel.count > 0 && articlesModel.get(feedsListView.currentIndex).articleImageUrl !== "") ? vpx(460) : 0)
                height: parent.height
                spacing: vpx(12)
                clip: true
                model: articlesModel
                focus: !articleContentPopup.visible

                delegate: Rectangle {
                    width: feedsListView.width
                    height: vpx(75)
                    color: ListView.isCurrentItem ? theme.accent : theme.button
                    border.color: theme.secondary
                    border.width: vpx(2)
                    radius: vpx(6)

                    Item {
                        anchors.fill: parent
                        anchors.margins: vpx(12)
                        
                        Rectangle {
                            id: statusDot
                            width: vpx(8)
                            height: vpx(8)
                            radius: 4
                            color: ListView.isCurrentItem ? "white" : "#E60012"
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.left: statusDot.right
                            anchors.leftMargin: vpx(15)
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: vpx(4)

                            Text {
                                text: model.articleTitle
                                color: ListView.isCurrentItem ? "white" : theme.text
                                font.family: titleFont.name
                                font.pixelSize: vpx(15)
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: model.articleDate
                                color: ListView.isCurrentItem ? "white" : theme.icon
                                font.family: titleFont.name
                                font.pixelSize: vpx(12)
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            feedsListView.currentIndex = index
                            infoScreenRoot.openArticle(model.articleTitle, model.articleDate, model.articleDescription, model.articleImageUrl)
                        }
                    }
                }
            }
        }
    }

    // --- NAVIGATION CONTROL ---
    Keys.onPressed: {
        if (articleContentPopup.visible) {
            if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                event.accepted = true;
                backSfx.play();
                articleContentPopup.visible = false;
            }
        } else {
            if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                event.accepted = true;
                backSfx.play();
                showHomeScreen();
            } else if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true;
                if (feedsListView.currentItem && articlesModel.count > 0) {
                    var currentData = articlesModel.get(feedsListView.currentIndex);
                    navSound.play();
                    infoScreenRoot.openArticle(currentData.articleTitle, currentData.articleDate, currentData.articleDescription, currentData.articleImageUrl);
                }
            }
        }
    }

    // --- CUSTOM COMPATIBLE POPUP BLOCK ---
    Rectangle {
        id: articleContentPopup
        anchors.fill: parent
        color: "#AA000000"
        visible: false

        Rectangle {
            width: parent.width * 0.8
            height: parent.height * 0.8
            color: theme.main
            border.color: theme.secondary
            border.width: vpx(3)
            radius: vpx(12)
            anchors.centerIn: parent

            Item {
                anchors.fill: parent
                anchors.margins: vpx(30)

                Flickable {
                    anchors.fill: parent
                    contentWidth: parent.width
                    contentHeight: contentColumn.height
                    clip: true

                    Column {
                        id: contentColumn
                        width: parent.width
                        spacing: vpx(15)

                        Text {
                            text: infoScreenRoot.selectedTitle
                            color: theme.text
                            font.family: titleFont.name
                            font.pixelSize: vpx(24)
                            font.bold: true
                            wrapMode: Text.Wrap
                            width: parent.width
                        }

                        Text {
                            text: infoScreenRoot.selectedDate
                            color: theme.icon
                            font.family: titleFont.name
                            font.pixelSize: vpx(14)
                            wrapMode: Text.Wrap
                            width: parent.width
                        }

                        Rectangle {
                            width: parent.width
                            height: vpx(2)
                            color: theme.secondary
                        }

                        Text {
                            text: infoScreenRoot.selectedDescription
                            color: theme.text
                            font.family: titleFont.name
                            font.pixelSize: vpx(18)
                            wrapMode: Text.Wrap
                            width: parent.width
                        }
                    }
                }
            }
            
            Text {
                text: "Press B"
                color: theme.icon
                font.pixelSize: vpx(12)
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: vpx(15)
            }
        }
        
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: articleContentPopup.visible = false
        }
    }
}