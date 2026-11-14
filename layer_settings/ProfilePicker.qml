import QtQuick 2.0
import QtGraphicalEffects 1.0

FocusScope {
    id: picker
    anchors.fill: parent
    opacity: shown ? 1 : 0
    visible: opacity > 0
    z: 160

    property bool shown: false
    property int currentIndex: 0
    property real avatarSize: Math.round(screenheight * 0.13)
    signal chosen(string name)
    signal cancelled

    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }

    ListModel {
        id: pickerModel
    }

    function mainImage() {
        if (api.memory.get("RA_LoggedIn") === "Yes")
            return "https://media.retroachievements.org/UserPic/" + api.memory.get("RA_Username") + ".png";
        return "../assets/images/profile_icon.png";
    }

    function open() {
        pickerModel.clear();
        var mainName = currentUsername();
        pickerModel.append({
            profileName: mainName,
            displayName: mainName !== "" ? mainName : "Main",
            profileImg: mainImage()
        });
        var n = 1;
        while (api.memory.has("profile_" + n)) {
            var name = String(api.memory.get("profile_" + n));
            pickerModel.append({
                profileName: name,
                displayName: name,
                profileImg: api.memory.has("profile_" + n + "_img") ? String(api.memory.get("profile_" + n + "_img")) : ""
            });
            n++;
        }
        var preferred = api.memory.has("Launcher User") ? String(api.memory.get("Launcher User")) : "";
        currentIndex = 0;
        for (var i = 0; i < pickerModel.count; i++) {
            if (pickerModel.get(i).profileName === preferred) {
                currentIndex = i;
                break;
            }
        }
        shown = true;
        picker.forceActiveFocus();
    }

    function choose() {
        var item = pickerModel.get(currentIndex);
        selectSfx.play();
        shown = false;
        chosen(item.profileName);
    }

    function cancel() {
        backSfx.play();
        shown = false;
        cancelled();
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.6
        MouseArea {
            anchors.fill: parent
            onClicked: picker.cancel()
        }
    }

    Rectangle {
        id: panel
        width: parent.width
        height: Math.round(screenheight * 0.45)
        color: theme.main
        y: picker.shown ? parent.height - height : parent.height

        Behavior on y {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Text {
            anchors {
                top: parent.top
                left: parent.left
                topMargin: vpx(32)
                leftMargin: vpx(48)
            }
            text: "Who's using the software?"
            color: theme.text
            font.family: titleFont.name
            font.pixelSize: Math.round(screenheight * 0.026)
            font.bold: true
        }

        Row {
            anchors.centerIn: parent
            spacing: vpx(44)

            Repeater {
                model: pickerModel

                Item {
                    id: cell
                    width: picker.avatarSize
                    height: picker.avatarSize + vpx(56)
                    property bool sel: picker.currentIndex === index

                    Rectangle {
                        width: picker.avatarSize + vpx(12)
                        height: width
                        radius: width / 2
                        color: theme.accent
                        x: -vpx(6)
                        y: -vpx(6)
                        opacity: cell.sel ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                            }
                        }
                    }

                    Rectangle {
                        width: picker.avatarSize
                        height: width
                        radius: width / 2
                        color: theme.button

                        Text {
                            anchors.centerIn: parent
                            text: displayName.trim() !== "" ? displayName.trim().charAt(0).toUpperCase() : "?"
                            color: theme.icon
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.05)
                            font.bold: true
                        }
                    }

                    Image {
                        id: avImg
                        width: picker.avatarSize
                        height: width
                        source: profileImg
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(256, 256)
                        visible: false
                    }

                    Rectangle {
                        id: avMask
                        width: picker.avatarSize
                        height: width
                        radius: width / 2
                        visible: false
                    }

                    OpacityMask {
                        width: picker.avatarSize
                        height: width
                        source: avImg
                        maskSource: avMask
                        visible: avImg.status === Image.Ready
                    }

                    Text {
                        anchors {
                            top: parent.top
                            topMargin: picker.avatarSize + vpx(20)
                            horizontalCenter: parent.horizontalCenter
                        }
                        text: displayName
                        color: theme.text
                        visible: cell.sel
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.024)
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            picker.currentIndex = index;
                            picker.choose();
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: vpx(56)
                leftMargin: vpx(48)
                rightMargin: vpx(48)
            }
            height: 1
            color: theme.secondary
            opacity: 0.3
        }

        Row {
            anchors {
                right: parent.right
                bottom: parent.bottom
                rightMargin: vpx(48)
                bottomMargin: vpx(16)
            }
            spacing: vpx(28)

            Text {
                text: "B  Back"
                color: theme.text
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.022)
            }
            Text {
                text: "A  OK"
                color: theme.text
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.022)
            }
        }
    }

    Keys.onLeftPressed: {
        if (currentIndex > 0) {
            navSound.play();
            currentIndex--;
        }
    }
    Keys.onRightPressed: {
        if (currentIndex < pickerModel.count - 1) {
            navSound.play();
            currentIndex++;
        }
    }
    Keys.onPressed: {
        if (event.isAutoRepeat)
            return;
        if (api.keys.isAccept(event)) {
            event.accepted = true;
            choose();
        } else if (api.keys.isCancel(event)) {
            event.accepted = true;
            cancel();
        }
    }
}