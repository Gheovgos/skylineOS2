import QtQuick 2.0
import QtGraphicalEffects 1.0

FocusScope {
    id: root
    anchors.fill: parent
    visible: false
    z: 150

    property int profileIndex: 0
    property string nameValue: ""
    property string imageValue: ""
    property string editValue: ""
    property bool editing: false
    property int focusedRow: 0
    property string errorText: ""

    signal confirmRequested(string title, string subtitle, var action, var focusItem)

    QtObject {
        id: focusReturn
        function forceActiveFocus() {
            if (root.visible)
                root.forceActiveFocus();
            else
                homeScreen.forceActiveFocus();
        }
    }

    function open(n) {
        profileIndex = n;
        nameValue = String(api.memory.get("profile_" + n));
        imageValue = api.memory.has("profile_" + n + "_img") ? String(api.memory.get("profile_" + n + "_img")) : "";
        editValue = "";
        errorText = "";
        focusedRow = 0;
        editing = false;
        visible = true;
        root.forceActiveFocus();
    }

    function close() {
        Qt.inputMethod.hide();
        editing = false;
        hiddenInput.focus = false;
        avatarPicker.visible = false;
        visible = false;
        homeScreen.forceActiveFocus();
    }

    function startEditing() {
        errorText = "";
        editValue = nameValue;
        editing = true;
        hiddenInput.forceActiveFocus();
        Qt.inputMethod.show();
    }

    function stopEditing() {
        editing = false;
        errorText = "";
        Qt.inputMethod.hide();
        hiddenInput.focus = false;
        root.forceActiveFocus();
    }

    function saveName() {
        var name = editValue.trim();
        if (name === "") {
            errorText = "Enter a username";
            return;
        }
        nameValue = name;
        api.memory.set("profile_" + profileIndex, name);
        homeScreen.updateSatellite(profileIndex - 1, name, imageValue);
        selectSfx.play();
        stopEditing();
    }

    function saveImage(url) {
        imageValue = url;
        api.memory.set("profile_" + profileIndex + "_img", url);
        homeScreen.updateSatellite(profileIndex - 1, nameValue, url);
    }

    function deleteProfile() {
        var total = 0;
        while (api.memory.has("profile_" + (total + 1)))
            total++;
        for (var k = profileIndex; k < total; k++) {
            api.memory.set("profile_" + k, api.memory.get("profile_" + (k + 1)));
            api.memory.set("profile_" + k + "_img", api.memory.has("profile_" + (k + 1) + "_img") ? api.memory.get("profile_" + (k + 1) + "_img") : "");
        }
        api.memory.unset("profile_" + total);
        api.memory.unset("profile_" + total + "_img");
        homeScreen.focusProfileSlot(0);
        homeScreen.refreshSatellites();
        close();
    }

    function requestDelete() {
        confirmRequested("Delete \"" + nameValue + "\"?", "This profile will be removed", function () {
            root.deleteProfile();
        }, focusReturn);
    }

    function activateRow() {
        if (focusedRow === 0) {
            selectSfx.play();
            avatarPicker.open();
        } else if (focusedRow === 1) {
            selectSfx.play();
            startEditing();
        } else {
            requestDelete();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.5
        MouseArea {
            anchors.fill: parent
        }
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.max(vpx(420), Math.round(screenwidth * 0.4))
        height: vpx(540)
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
                    root.editValue = root.editValue.slice(0, -1);
                    return;
                }
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    event.accepted = true;
                    root.saveName();
                    return;
                }
                if (event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    root.stopEditing();
                    return;
                }
            }
            onTextChanged: {
                if (text !== "") {
                    root.editValue += text;
                    text = "";
                }
            }
        }

        Column {
            anchors {
                fill: parent
                margins: vpx(28)
            }
            spacing: vpx(14)

            Text {
                text: "Edit profile"
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: theme.text
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.032)
                font.bold: true
            }

            Item {
                width: vpx(96)
                height: width
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: theme.main
                }

                Text {
                    anchors.centerIn: parent
                    visible: previewImg.status !== Image.Ready
                    text: root.nameValue.trim() !== "" ? root.nameValue.trim().charAt(0).toUpperCase() : "?"
                    color: theme.icon
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.045)
                    font.bold: true
                }

                Image {
                    id: previewImg
                    anchors.fill: parent
                    source: root.imageValue
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(192, 192)
                    visible: false
                }

                Rectangle {
                    id: previewMask
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: previewImg
                    maskSource: previewMask
                    visible: previewImg.status === Image.Ready
                }
            }

            Text {
                text: root.nameValue
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: theme.accent
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.026)
                font.bold: true
            }

            Repeater {
                model: [
                    {
                        label: "Change image"
                    },
                    {
                        label: "Change username"
                    },
                    {
                        label: "Delete profile"
                    }
                ]

                Rectangle {
                    width: parent.width
                    height: vpx(52)
                    radius: vpx(12)
                    color: theme.main
                    border.width: root.focusedRow === index ? vpx(3) : 0
                    border.color: index === 2 ? "#EF4444" : theme.accent

                    Text {
                        anchors.centerIn: parent
                        visible: !(index === 1 && root.editing)
                        text: modelData.label
                        color: index === 2 ? "#EF4444" : theme.text
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.024)
                        font.bold: true
                    }

                    Row {
                        anchors {
                            fill: parent
                            leftMargin: vpx(14)
                            rightMargin: vpx(14)
                        }
                        spacing: vpx(4)
                        visible: index === 1 && root.editing

                        Text {
                            text: root.editValue
                            color: theme.text
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.026)
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: vpx(2)
                            height: vpx(24)
                            color: theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                            SequentialAnimation on opacity {
                                running: root.editing
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

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.editing)
                                return;
                            root.focusedRow = index;
                            root.activateRow();
                        }
                    }
                }
            }

            Text {
                text: root.errorText
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: "#EF4444"
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.018)
                visible: root.errorText !== ""
            }
        }
    }

    Keys.onPressed: {
        if (avatarPicker.visible || event.isAutoRepeat)
            return;
        if (api.keys.isCancel(event)) {
            event.accepted = true;
            backSfx.play();
            close();
            return;
        }
        if (api.keys.isAccept(event)) {
            event.accepted = true;
            activateRow();
            return;
        }
    }
    Keys.onUpPressed: {
        if (avatarPicker.visible)
            return;
        navSound.play();
        focusedRow = Math.max(0, focusedRow - 1);
    }
    Keys.onDownPressed: {
        if (avatarPicker.visible)
            return;
        navSound.play();
        focusedRow = Math.min(2, focusedRow + 1);
    }

    AvatarPicker {
        id: avatarPicker
        onPicked: root.saveImage(url)
        onClosed: root.forceActiveFocus()
    }
}