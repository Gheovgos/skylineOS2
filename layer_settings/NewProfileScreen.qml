import QtQuick 2.0
import QtGraphicalEffects 1.0

FocusScope {
    id: root
    anchors.fill: parent
    visible: false
    z: 150

    property string imageValue: ""

    property string usernameValue: ""
    property bool editing: false
    property int focusedRow: 0
    property string errorText: ""

    function open() {
        usernameValue = "";
        errorText = "";
        focusedRow = 0;
        editing = false;
        visible = true;
        imageValue = "";
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

    function nextProfileIndex() {
        var n = 1;
        while (api.memory.has("profile_" + n))
            n++;
        return n;
    }

    function createProfile() {
        var name = usernameValue.trim();
        if (name === "") {
            errorText = "Enter a username";
            return;
        }
        var n = nextProfileIndex();
        api.memory.set("profile_" + n, name);
        api.memory.set("profile_" + n + "_img", root.imageValue);
        selectSfx.play();
        homeScreen.refreshSatellites();
        close();
    }

    function startEditing() {
        errorText = "";
        editing = true;
        hiddenInput.forceActiveFocus();
        Qt.inputMethod.show();
    }

    function stopEditing() {
        editing = false;
        Qt.inputMethod.hide();
        hiddenInput.focus = false;
        root.forceActiveFocus();
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
        height: vpx(450)
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
                    root.usernameValue = root.usernameValue.slice(0, -1);
                    return;
                }
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    event.accepted = true;
                    root.stopEditing();
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
                    root.usernameValue += text;
                    text = "";
                }
            }
        }

        Column {
            anchors {
                fill: parent
                margins: vpx(28)
            }
            spacing: vpx(20)

            Text {
                text: "New profile"
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
                    text: root.usernameValue.trim() !== "" ? root.usernameValue.trim().charAt(0).toUpperCase() : "?"
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

                        Rectangle {
                width: parent.width
                height: vpx(52)
                radius: vpx(12)
                color: theme.main
                border.width: root.focusedRow === 0 ? vpx(3) : 0
                border.color: theme.accent

                Row {
                    anchors {
                        fill: parent
                        leftMargin: vpx(14)
                        rightMargin: vpx(14)
                    }
                    spacing: vpx(4)

                    Text {
                        text: root.usernameValue !== "" ? root.usernameValue : (root.editing ? "" : "Username")
                        color: root.usernameValue !== "" ? theme.text : theme.icon
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.026)
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: vpx(2)
                        height: vpx(24)
                        color: theme.accent
                        visible: root.editing
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
                        root.focusedRow = 0;
                        root.startEditing();
                    }
                }
            }

            Rectangle {
                width: vpx(180)
                height: vpx(44)
                radius: height / 2
                color: theme.main
                anchors.horizontalCenter: parent.horizontalCenter
                border.width: root.focusedRow === 1 ? vpx(3) : 0
                border.color: theme.accent

                Text {
                    anchors.centerIn: parent
                    text: root.imageValue !== "" ? "Change image" : "Choose image"
                    color: theme.text
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.022)
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.focusedRow = 1;
                        avatarPicker.open();
                    }
                }
            }

            Rectangle {
                width: vpx(180)
                height: vpx(48)
                radius: height / 2
                color: theme.accent
                anchors.horizontalCenter: parent.horizontalCenter
                border.width: root.focusedRow === 2 ? vpx(3) : 0
                border.color: theme.text

                Text {
                    anchors.centerIn: parent
                    text: "Create"
                    color: "white"
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.024)
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.focusedRow = 2;
                        root.createProfile();
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
            if (focusedRow === 0)
                startEditing();
            else if (focusedRow === 1)
                avatarPicker.open();
            else
                createProfile();
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
        onPicked: root.imageValue = url
        onClosed: root.forceActiveFocus()
    }
}
