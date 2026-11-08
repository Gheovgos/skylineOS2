import QtQuick 2.0
import QtGraphicalEffects 1.0

FocusScope {
    id: memRoot

    property var models: []
    property bool editing: false
    property string editValue: ""
    signal closed

    anchors.fill: parent
    visible: false
    z: 110

    function display(v) {
        return (typeof v === "object") ? JSON.stringify(v) : String(v);
    }

    function candidateKeys() {
        var set = {};
        var fixed = ["Last Collection", "sortIndex", "HiddenApps", "RA_LoggedIn", "RA_Username", "STACK_TIMER", "LAST_STACK_ITEM"];
        for (var f = 0; f < fixed.length; f++)
            set[fixed[f]] = true;

        for (var m = 0; m < models.length; m++) {
            for (var i = 0; i < models[m].count; i++) {
                var n = models[m].get(i).settingName;
                set[n] = true;
                set[n + "Index"] = true;
            }
        }

        var prefixes = ["SGDB_BG::", "SGDB_ID::", "RA_ID::", "RA_GameID::", ""];
        for (var g = 0; g < api.allGames.count; g++) {
            var t = api.allGames.get(g).title;
            for (var p = 0; p < prefixes.length; p++)
                set[prefixes[p] + t] = true;
        }
        return Object.keys(set).sort();
    }

    function refresh() {
        memModel.clear();
        var keys = candidateKeys();
        for (var i = 0; i < keys.length; i++) {
            if (!api.memory.has(keys[i]))
                continue;
            var v = api.memory.get(keys[i]);
            memModel.append({
                key: keys[i],
                value: display(v),
                vtype: typeof v
            });
        }
    }

    function open() {
        refresh();
        editing = false;
        visible = true;
        memList.forceActiveFocus();
    }

    function close() {
        Qt.inputMethod.hide();
        editing = false;
        visible = false;
        closed();
    }

    function startEdit() {
        if (memList.currentIndex < 0)
            return;
        editValue = memModel.get(memList.currentIndex).value;
        editing = true;
        Qt.inputMethod.show();
    }

    function commit() {
        var item = memModel.get(memList.currentIndex);
        var v = editValue;
        if (item.vtype === "object") {
            try {
                v = JSON.parse(v);
            } catch (e) {
                return;
            }
        } else if (item.vtype === "number") {
            v = Number(v);
            if (isNaN(v))
                return;
        } else if (item.vtype === "boolean") {
            v = (v === "true");
        }
        api.memory.set(item.key, v);
        memModel.set(memList.currentIndex, { value: display(v) });
        editing = false;
        Qt.inputMethod.hide();
    }

    function removeCurrent() {
        if (memList.currentIndex < 0)
            return;
        var idx = memList.currentIndex;
        var k = memModel.get(idx).key;
        requestConfirm("Delete this key?", k, function () {
            api.memory.unset(k);
            memModel.remove(idx);
        }, memList);
    }

    ListModel {
        id: memModel
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.6
        MouseArea {
            anchors.fill: parent
        }
    }

    Rectangle {
        id: memPanel
        anchors.centerIn: parent
        width: Math.round(screenwidth * 0.75)
        height: Math.round(screenheight * 0.8)
        radius: vpx(20)
        color: theme.button

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            verticalOffset: vpx(6)
            radius: 20
            samples: 32
            color: "#60000000"
        }

        Text {
            id: memTitle
            anchors {
                top: parent.top
                left: parent.left
                margins: vpx(24)
            }
            text: "Memory (" + memModel.count + ")"
            color: theme.text
            font.family: titleFont.name
            font.pixelSize: Math.round(screenheight * 0.026)
            font.bold: true
        }

        ListView {
            id: memList
            anchors {
                top: memTitle.bottom
                topMargin: vpx(12)
                left: parent.left
                right: parent.right
                bottom: memHint.top
                leftMargin: vpx(24)
                rightMargin: vpx(24)
                bottomMargin: vpx(8)
            }
            clip: true
            model: memModel
            focus: true
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 80

            delegate: Item {
                property bool sel: ListView.isCurrentItem
                width: memList.width
                height: vpx(44)

                Rectangle {
                    anchors.fill: parent
                    radius: vpx(8)
                    color: theme.accent
                    opacity: sel ? 0.3 : 0
                }

                Text {
                    id: keyText
                    anchors {
                        left: parent.left
                        leftMargin: vpx(12)
                        verticalCenter: parent.verticalCenter
                    }
                    width: parent.width * 0.4
                    text: key
                    color: theme.text
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.019)
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    anchors {
                        left: keyText.right
                        leftMargin: vpx(12)
                        right: parent.right
                        rightMargin: vpx(12)
                        verticalCenter: parent.verticalCenter
                    }
                    text: (sel && memRoot.editing) ? memRoot.editValue + "|" : value
                    color: (sel && memRoot.editing) ? theme.accent : theme.icon
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.019)
                    elide: (sel && memRoot.editing) ? Text.ElideLeft : Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (sel && !memRoot.editing)
                            memRoot.startEdit();
                        else if (!memRoot.editing)
                            memList.currentIndex = index;
                    }
                }
            }

            Keys.onPressed: {
                event.accepted = true;

                if (memRoot.editing) {
                    if (event.key === Qt.Key_Backspace) {
                        memRoot.editValue = memRoot.editValue.slice(0, -1);
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || api.keys.isAccept(event)) {
                        memRoot.commit();
                    } else if (event.key === Qt.Key_Escape || api.keys.isCancel(event)) {
                        memRoot.editing = false;
                        Qt.inputMethod.hide();
                    } else if (event.text && event.text.length === 1) {
                        memRoot.editValue += event.text;
                    }
                    return;
                }

                if (event.key === Qt.Key_Up) {
                    navSound.play();
                    decrementCurrentIndex();
                } else if (event.key === Qt.Key_Down) {
                    navSound.play();
                    incrementCurrentIndex();
                } else if (event.key === Qt.Key_Delete || (api.keys.isDetails(event) && !event.isAutoRepeat)) {
                    memRoot.removeCurrent();
                } else if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    selectSfx.play();
                    memRoot.startEdit();
                } else if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                    backSfx.play();
                    memRoot.close();
                }
            }
        }

        Text {
            id: memHint
            anchors {
                bottom: parent.bottom
                left: parent.left
                margins: vpx(24)
            }
            text: memRoot.editing ? "Enter: save  •  Esc: undo" : "A: edit  •  X: remove  •  B: close"
            color: theme.icon
            font.family: titleFont.name
            font.pixelSize: Math.round(screenheight * 0.016)
            opacity: 0.6
        }
    }
}