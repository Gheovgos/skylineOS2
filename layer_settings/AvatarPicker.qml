import QtQuick 2.0
import QtGraphicalEffects 1.0

FocusScope {
    id: picker
    anchors.fill: parent
    visible: false
    z: 10

    property bool editing: false
    property string pathValue: ""
    signal picked(string url)
    signal closed

    ListModel {
        id: avatarModel
    }

    function normalizePath(p) {
        var s = p.trim();
        if (s === "")
            return "";
        if (s.indexOf("://") !== -1)
            return s;
        if (/^[A-Za-z]:/.test(s))
            return "file:///" + s.replace(/\\/g, "/");
        if (s.charAt(0) === "/")
            return "file://" + s;
        return s;
    }

    function build() {
        avatarModel.clear();
        avatarModel.append({
            src: "",
            custom: true
        });
        var seen = {};
        var limit = Math.min(api.allGames.count, 150);
        for (var i = 0; i < limit; i++) {
            var g = api.allGames.get(i);
            var s = g.assets.boxFront || g.assets.tile || g.assets.logo || g.assets.screenshots[0] || "";
            if (s === "" || seen[s])
                continue;
            seen[s] = true;
            avatarModel.append({
                src: String(s),
                custom: false
            });
        }
    }

    function open() {
        build();
        pathValue = "";
        editing = false;
        grid.currentIndex = avatarModel.count > 1 ? 1 : 0;
        visible = true;
        grid.forceActiveFocus();
    }

    function close() {
        Qt.inputMethod.hide();
        editing = false;
        hiddenInput.focus = false;
        visible = false;
        closed();
    }

    function startEditing() {
        editing = true;
        hiddenInput.forceActiveFocus();
        Qt.inputMethod.show();
    }

    function stopEditing() {
        editing = false;
        Qt.inputMethod.hide();
        hiddenInput.focus = false;
        grid.forceActiveFocus();
    }

    function confirmPath() {
        var url = normalizePath(pathValue);
        stopEditing();
        if (url !== "") {
            picked(url);
            close();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.4
        MouseArea {
            anchors.fill: parent
        }
    }

    Rectangle {
        id: pickerPanel
        anchors.centerIn: parent
        width: Math.round(screenwidth * 0.6)
        height: Math.round(screenheight * 0.75)
        radius: vpx(24)
        color: theme.button

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: vpx(6)
            radius: 20
            samples: 32
            color: "#60000000"
        }

        TextInput {
            id: hiddenInput
            visible: false
            Keys.onPressed: {
                if (event.key === Qt.Key_Backspace) {
                    event.accepted = true;
                    picker.pathValue = picker.pathValue.slice(0, -1);
                    return;
                }
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    event.accepted = true;
                    picker.confirmPath();
                    return;
                }
                if (event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    picker.stopEditing();
                    return;
                }
            }
            onTextChanged: {
                if (text !== "") {
                    picker.pathValue += text;
                    text = "";
                }
            }
        }

        Text {
            id: pickerTitle
            anchors {
                top: parent.top
                left: parent.left
                margins: vpx(24)
            }
            text: "Choose an image"
            color: theme.text
            font.family: titleFont.name
            font.pixelSize: Math.round(screenheight * 0.028)
            font.bold: true
        }

        Rectangle {
            id: pathBar
            anchors {
                left: parent.left
                right: parent.right
                bottom: pickerHint.top
                leftMargin: vpx(24)
                rightMargin: vpx(24)
                bottomMargin: vpx(8)
            }
            height: vpx(44)
            radius: vpx(10)
            color: theme.main
            visible: picker.editing

            Text {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: vpx(12)
                    rightMargin: vpx(12)
                }
                text: picker.pathValue + "|"
                color: theme.accent
                elide: Text.ElideLeft
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.02)
                font.bold: true
            }
        }

        GridView {
            id: grid
            focus: true
            clip: true
            anchors {
                top: pickerTitle.bottom
                topMargin: vpx(12)
                left: parent.left
                right: parent.right
                bottom: picker.editing ? pathBar.top : pickerHint.top
                leftMargin: vpx(24)
                rightMargin: vpx(24)
                bottomMargin: vpx(8)
            }
            property int columns: Math.max(1, Math.floor(width / vpx(110)))
            cellWidth: width / columns
            cellHeight: vpx(110)
            model: avatarModel
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 80

            Keys.onLeftPressed: {
                navSound.play();
                moveCurrentIndexLeft();
            }
            Keys.onRightPressed: {
                navSound.play();
                moveCurrentIndexRight();
            }
            Keys.onUpPressed: {
                navSound.play();
                moveCurrentIndexUp();
            }
            Keys.onDownPressed: {
                navSound.play();
                moveCurrentIndexDown();
            }
            Keys.onPressed: {
                if (event.isAutoRepeat)
                    return;
                if (api.keys.isAccept(event)) {
                    event.accepted = true;
                    var item = avatarModel.get(currentIndex);
                    if (item.custom) {
                        selectSfx.play();
                        picker.startEditing();
                    } else {
                        selectSfx.play();
                        picker.picked(item.src);
                        picker.close();
                    }
                    return;
                }
                if (api.keys.isCancel(event)) {
                    event.accepted = true;
                    backSfx.play();
                    picker.close();
                }
            }

            delegate: Item {
                id: cell
                width: grid.cellWidth
                height: grid.cellHeight
                property bool sel: GridView.isCurrentItem

                Rectangle {
                    anchors.centerIn: parent
                    width: vpx(96)
                    height: width
                    radius: width / 2
                    color: theme.accent
                    opacity: cell.sel ? 1 : 0
                }

                Item {
                    id: avatarBox
                    anchors.centerIn: parent
                    width: vpx(88)
                    height: width

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: theme.main
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: custom
                        text: "Path"
                        color: theme.icon
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.022)
                        font.bold: true
                    }

                    Image {
                        id: cellImg
                        anchors.fill: parent
                        source: src
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(128, 128)
                        visible: false
                    }

                    Rectangle {
                        id: cellMask
                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: cellImg
                        maskSource: cellMask
                        visible: !custom && cellImg.status === Image.Ready
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        grid.currentIndex = index;
                        if (custom) {
                            picker.startEditing();
                        } else {
                            picker.picked(src);
                            picker.close();
                        }
                    }
                }
            }
        }

        Text {
            id: pickerHint
            anchors {
                bottom: parent.bottom
                left: parent.left
                margins: vpx(24)
            }
            text: picker.editing ? "Enter: confirm  •  Esc: undo" : "A: select  •  B: close"
            color: theme.icon
            font.family: titleFont.name
            font.pixelSize: Math.round(screenheight * 0.016)
            opacity: 0.6
        }
    }
}