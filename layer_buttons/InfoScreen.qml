import QtQuick 2.12

FocusScope {
    id: infoScreenRoot

    property string rawFeeds: api.memory.has("Feed RSS List")
        ? api.memory.get("Feed RSS List")
        : "https://www.polygon.com/rss/index.xml§https://feeds.arstechnica.com/arstechnica/index"
    property var feedsArray: rawFeeds.split("§").map(function(s){ return s.trim(); })
    property int activeFeedIndex: 0
    property string activeFeedUrl: feedsArray[activeFeedIndex]
    property bool isLoading: true

    property string selectedTitle: ""
    property string selectedDate: ""
    property string selectedDescription: ""
    property string selectedImageUrl: ""

    function openArticle(title, date, desc, img) {
        infoScreenRoot.selectedTitle  = title;
        infoScreenRoot.selectedDate   = date;
        infoScreenRoot.selectedDescription = (desc && desc.length > 0)
            ? desc
            : "No description available for this article.";
        infoScreenRoot.selectedImageUrl = img;
        articleContentPopup.visible = true;
        popupFlickable.contentY = 0; 
    }

    function cleanText(raw) {
        if (!raw) return "";
        var s = raw.replace(/<[^>]*>/gm, "");
        s = s.replace(/&amp;/g,    "&")
             .replace(/&lt;/g,     "<")
             .replace(/&gt;/g,     ">")
             .replace(/&quot;/g,   "\"")
             .replace(/&apos;/g,   "'")
             .replace(/&#8230;/g,  "…")
             .replace(/&#8217;/g,  "'")
             .replace(/&#8216;/g,  "'")
             .replace(/&#8220;/g,  "\u201C")
             .replace(/&#8221;/g,  "\u201D")
             .replace(/&#(\d+);/g, function(_, code){ return String.fromCharCode(parseInt(code)); })
             .replace(/&nbsp;/g,   " ");
        s = s.replace(/\s{2,}/g, " ").trim();
        return s;
    }

    ListModel { id: articlesModel }

    // ── FETCH ──────────────────────────────────────────────
    function fetchRSSContent() {
        infoScreenRoot.isLoading = true;
        articlesModel.clear();
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status === 200) {
                parseXMLText(xhr.responseText);
            } else {
                articlesModel.append({
                    articleTitle: "Connection error",
                    articleDate:  "HTTP Status: " + xhr.status,
                    articleImageUrl: "",
                    articleDescription: "Could not reach: " + infoScreenRoot.activeFeedUrl
                });
                infoScreenRoot.isLoading = false;
            }
        };
        xhr.open("GET", infoScreenRoot.activeFeedUrl);
        xhr.send();
    }

    function parseXMLText(xmlText) {
        var itemRegex = /<(item|entry)([\s\S]*?)<\/\1>/g;
        var match;
        var count = 0;

        while ((match = itemRegex.exec(xmlText)) !== null && count < 15) {
            var block = match[0];

            var titleM = block.match(/<title[^>]*>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?<\/title>/);

            var dateM  = block.match(/<(?:pubDate|published|updated|dc:date)[^>]*>([\s\S]*?)<\/(?:pubDate|published|updated|dc:date)>/);

            var imgM   = block.match(/enclosure[^>]+url=["'](https?[^"']+)["']/)
                      || block.match(/media:(?:content|thumbnail)[^>]+url=["'](https?[^"']+)["']/)
                      || block.match(/<img[^>]+src=["'](https?[^"']+)["']/);

            var descM  = block.match(/<(?:description|summary|content(?::encoded)?)[^>]*>\s*<!\[CDATA\[([\s\S]*?)\]\]>\s*<\/(?:description|summary|content(?::encoded)?)>/)
                      || block.match(/<(?:description|summary|content(?::encoded)?)[^>]*>([\s\S]*?)<\/(?:description|summary|content(?::encoded)?)>/);

            var title   = cleanText(titleM ? titleM[1] : "No Title");
            var date    = dateM  ? dateM[1].trim().substring(0, 30) : "Recent";
            var img     = imgM   ? imgM[1].trim()  : "";
            var desc    = cleanText(descM ? (descM[1] || descM[2] || "") : "");

            // Se la descrizione è troppo corta (feed che mettono solo il titolo), segnalalo
            if (desc.length < 10) desc = "No extended description in this feed.";

            articlesModel.append({
                articleTitle:       title,
                articleDate:        date,
                articleImageUrl:    img,
                articleDescription: desc
            });
            count++;
        }

        if (articlesModel.count === 0) {
            articlesModel.append({
                articleTitle: "No articles found",
                articleDate:  "Check the RSS URL",
                articleImageUrl: "",
                articleDescription: "The parser did not find <item> or <entry> blocks."
            });
        }
        infoScreenRoot.isLoading = false;
    }

    Component.onCompleted:   fetchRSSContent()
    onActiveFeedUrlChanged:  fetchRSSContent()

    Item {
        anchors.fill: parent
        anchors.margins: vpx(40)

        // ── HEADER ──
        Text {
            id: headerTitle
            text: "Live News Feed"
            color: theme.text
            font.family: titleFont.name
            font.pixelSize: vpx(34)
            font.bold: true
        }

        Text {
            id: headerSubtitle
            anchors.top: headerTitle.bottom
            anchors.topMargin: vpx(6)
            text: infoScreenRoot.isLoading
                ? "Loading feed…"
                : "Source: " + infoScreenRoot.activeFeedUrl
            color: theme.icon
            font.pixelSize: vpx(14)
            elide: Text.ElideRight
            width: parent.width
        }

        Row {
            id: feedTabs
            anchors.top: headerSubtitle.bottom
            anchors.topMargin: vpx(12)
            spacing: vpx(8)

            Repeater {
                model: infoScreenRoot.feedsArray.length
                delegate: Rectangle {
                    property bool active: infoScreenRoot.activeFeedIndex === index
                    width: feedTabLabel.implicitWidth + vpx(20)
                    height: vpx(28)
                    color:  active ? theme.accent : theme.button
                    border.color: theme.secondary
                    border.width: vpx(1)
                    radius: vpx(5)

                    Text {
                        id: feedTabLabel
                        anchors.centerIn: parent
                        text: {
                            var url = infoScreenRoot.feedsArray[index];
                            var m = url.match(/https?:\/\/(?:www\.)?([^\/]+)/);
                            return m ? m[1] : "Feed " + (index + 1);
                        }
                        color: parent.active ? "white" : theme.text
                        font.pixelSize: vpx(11)
                        font.bold: parent.active
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: infoScreenRoot.activeFeedIndex = index
                    }
                }
            }
        }

        Rectangle {
            id: headerSeparator
            anchors.top: feedTabs.bottom
            anchors.topMargin: vpx(14)
            width: parent.width
            height: vpx(2)
            color: theme.secondary
        }

        Row {
            id: bodyRow
            anchors.top: headerSeparator.bottom
            anchors.topMargin: vpx(20)
            anchors.bottom: parent.bottom
            width: parent.width
            spacing: vpx(30)

            property bool hasImage: feedsListView.currentItem
                                 && articlesModel.count > 0
                                 && articlesModel.get(feedsListView.currentIndex).articleImageUrl !== ""

            // Img
            Rectangle {
                width: vpx(380)
                height: vpx(240)
                visible: bodyRow.hasImage
                color: theme.button
                border.color: theme.secondary
                border.width: vpx(2)
                radius: vpx(8)
                clip: true
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.fill: parent
                    source: (articlesModel.count > 0)
                        ? articlesModel.get(feedsListView.currentIndex).articleImageUrl
                        : ""
                    fillMode: Image.PreserveAspectCrop
                }

                Rectangle {
                    width: liveBadge.implicitWidth + vpx(16)
                    height: vpx(24)
                    color: "#E60012"
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: vpx(10)
                    radius: vpx(4)
                    Text {
                        id: liveBadge
                        text: "LIVE NEWS"
                        color: "white"
                        font.bold: true
                        font.pixelSize: vpx(10)
                        anchors.centerIn: parent
                    }
                }
            }

            // List
            ListView {
                id: feedsListView
                width: parent.width - (bodyRow.hasImage ? vpx(410) : 0)
                height: parent.height
                spacing: vpx(10)
                clip: true
                model: articlesModel
                focus: !articleContentPopup.visible

                highlight: Rectangle {
                    color: theme.accent
                    radius: vpx(6)
                }
                highlightMoveDuration: 120

                delegate: Rectangle {
                    id: articleRow
                    width: feedsListView.width
                    height: vpx(72)
                    color: "transparent"      // il highlight si vede sotto
                    border.color: ListView.isCurrentItem ? "transparent" : theme.secondary
                    border.width: vpx(1)
                    radius: vpx(6)

                    Row {
                        anchors.fill: parent
                        anchors.margins: vpx(12)
                        spacing: vpx(10)

                        Rectangle {
                            width: vpx(7); height: vpx(7); radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: ListView.isCurrentItem ? "white" : "#E60012"
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - vpx(20)
                            spacing: vpx(4)

                            Text {
                                text: model.articleTitle
                                color: "white"
                                font.family: titleFont.name
                                font.pixelSize: vpx(14)
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: model.articleDate
                                color: theme.icon
                                font.pixelSize: vpx(11)
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            feedsListView.currentIndex = index;
                            infoScreenRoot.openArticle(
                                model.articleTitle, model.articleDate,
                                model.articleDescription, model.articleImageUrl);
                        }
                    }
                }
            }
        }
    }

    // Article
    Rectangle {
        id: articleContentPopup
        anchors.fill: parent
        color: "#BB000000"
        visible: false

        Rectangle {
            id: popupBox
            width:  parent.width  * 0.78
            height: parent.height * 0.82
            color:  theme.main
            border.color: theme.secondary
            border.width: vpx(3)
            radius: vpx(12)
            anchors.centerIn: parent
            clip: true

            Image {
                id: popupImage
                source: infoScreenRoot.selectedImageUrl
                visible: infoScreenRoot.selectedImageUrl !== ""
                width:  parent.width
                height: vpx(180)
                fillMode: Image.PreserveAspectCrop
                anchors.top: parent.top
                layer.enabled: true
            }

            Flickable {
                id: popupFlickable
                anchors.top:    popupImage.visible ? popupImage.bottom : parent.top
                anchors.bottom: closeHint.top
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.margins: vpx(24)
                anchors.topMargin: popupImage.visible ? vpx(16) : vpx(24)

                contentWidth:  width
                contentHeight: popupContent.implicitHeight
                clip: true
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: popupContent
                    width: popupFlickable.width
                    spacing: vpx(12)

                    Text {
                        text: infoScreenRoot.selectedTitle
                        color: theme.text
                        font.family: titleFont.name
                        font.pixelSize: vpx(22)
                        font.bold: true
                        wrapMode: Text.Wrap
                        width: parent.width
                    }

                    Text {
                        text: infoScreenRoot.selectedDate
                        color: theme.icon
                        font.pixelSize: vpx(13)
                        width: parent.width
                    }

                    Rectangle {
                        width: parent.width; height: vpx(1)
                        color: theme.secondary
                    }

                    Text {
                        text: infoScreenRoot.selectedDescription
                        color: theme.text
                        font.family: titleFont.name
                        font.pixelSize: vpx(16)
                        wrapMode: Text.Wrap
                        width: parent.width
                        lineHeight: 1.4
                    }
                }
            }
            Text {
                id: closeHint
                text: "B  ·  close     ↕  scroll"
                color: theme.icon
                font.pixelSize: vpx(11)
                anchors.bottom:  parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: vpx(10)
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: articleContentPopup.visible = false
        }
    }

    //  KEYBOARD NAV
    Keys.onPressed: {
        if (articleContentPopup.visible) {
            if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                event.accepted = true;
                backSfx.play();
                articleContentPopup.visible = false;
            }
            if (api.keys.isUp(event)) {
                popupFlickable.contentY = Math.max(0, popupFlickable.contentY - vpx(40));
                event.accepted = true;
            }
            if (api.keys.isDown(event)) {
                popupFlickable.contentY = Math.min(
                    popupFlickable.contentHeight - popupFlickable.height,
                    popupFlickable.contentY + vpx(40));
                event.accepted = true;
            }
        } else {
            if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                event.accepted = true;
                backSfx.play();
                showHomeScreen();
            }
            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true;
                if (articlesModel.count > 0) {
                    var d = articlesModel.get(feedsListView.currentIndex);
                    navSound.play();
                    infoScreenRoot.openArticle(d.articleTitle, d.articleDate,
                                               d.articleDescription, d.articleImageUrl);
                }
            }
            if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
                event.accepted = true;
                infoScreenRoot.activeFeedIndex = Math.max(0, infoScreenRoot.activeFeedIndex - 1);
            }
            if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
                event.accepted = true;
                infoScreenRoot.activeFeedIndex = Math.min(
                    infoScreenRoot.feedsArray.length - 1,
                    infoScreenRoot.activeFeedIndex + 1);
            }
        }
    }
}