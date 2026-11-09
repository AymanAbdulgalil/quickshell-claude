import QtQuick

// SDDM login screen in the active Quickshell preset's look: its wallpaper, colors and font, laid out like the
// lock screen (time, date, password field, keyboard language). Colors come from theme.conf, written by
// Quickshell's themes/apply.py whenever the preset changes. On success the form fades and the dimming lifts,
// leaving only the wallpaper, which is what the desktop starts with.
Rectangle {
    id: root

    readonly property color surface: config.surface || "#2e3440"
    readonly property color raised: config.surfaceRaised || "#3b4252"
    readonly property color text: config.foreground || "#d8dee9"
    readonly property color strong: config.foregroundStrong || "#eceff4"
    readonly property color muted: config.muted || "#81a1c1"
    readonly property color accent: config.accent || "#88c0d0"
    readonly property color error: config.error || "#bf616a"
    readonly property string font: config.font || "monospace"

    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    readonly property string userName: userModel.data(userModel.index(userIndex, 0), Qt.UserRole + 1) ?? ""
    readonly property string realName: userModel.data(userModel.index(userIndex, 0), Qt.UserRole + 2) ?? ""
    property bool leaving: false
    property bool failed: false
    property bool showPassword: false

    width: 1920
    height: 1080
    color: surface

    // The greeter is closed the moment the login succeeds, too soon to animate. So the screen fades to the theme's
    // background first and the login happens then; Hyprland starts on that same color and fades its wallpaper in.
    function login() {
        if (password.text === "" || leaving)
            return;
        failed = false;
        leaving = true;
        leaveDelay.restart();
    }

    Timer {
        id: leaveDelay

        interval: 340
        onTriggered: sddm.login(root.userName, password.text, sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0)
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.leaving = false;
            root.failed = true;
            password.text = "";
            password.forceActiveFocus();
            shake.restart();
        }

        function onLoginSucceeded() {
        }
    }

    Image {
        anchors.fill: parent
        source: config.background ? "file://" + config.background : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        smooth: true
    }

    // Dims the wallpaper behind the form; on login it closes to the theme's background, where Hyprland starts.
    Rectangle {
        anchors.fill: parent
        color: root.surface
        opacity: root.leaving ? 1 : 0.45

        Behavior on opacity {
            NumberAnimation {
                duration: 320
                easing.type: Easing.InOutQuad
            }
        }
    }

    Item {
        id: form

        anchors.fill: parent
        opacity: root.leaving ? 0 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuad
            }
        }

        Text {
            id: clock

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: date.top
            anchors.bottomMargin: 6
            color: root.strong
            font.family: root.font
            font.pixelSize: 75
            font.bold: true
            // 12-hour without AM or PM, like the lock screen.
            text: (now.time.getHours() % 12 || 12) + ":" + String(now.time.getMinutes()).padStart(2, "0")
        }

        Text {
            id: date

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.verticalCenter
            anchors.bottomMargin: -20
            color: root.text
            font.family: root.font
            font.pixelSize: 17
            font.letterSpacing: 3.5
            text: Qt.formatDate(now.time, "dddd, dd MMMM yyyy").toUpperCase()
        }

        Timer {
            id: now

            property date time: new Date()

            interval: 1000
            running: true
            repeat: true
            onTriggered: time = new Date()
        }

        Text {
            id: who

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: field.top
            anchors.bottomMargin: 10
            color: root.accent
            font.family: root.font
            font.pixelSize: 15
            font.weight: Font.DemiBold
            text: root.realName || root.userName

            // With more than one account, a click moves to the next.
            MouseArea {
                anchors.fill: parent
                enabled: userModel.count > 1
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.userIndex = (root.userIndex + 1) % userModel.count
            }
        }

        Rectangle {
            id: field

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.verticalCenter
            anchors.topMargin: 64
            width: 320
            height: 36
            radius: 12
            color: Qt.rgba(root.raised.r, root.raised.g, root.raised.b, 0.92)
            border.width: 2
            border.color: root.failed ? root.error : root.accent

            Behavior on border.color {
                ColorAnimation {
                    duration: 200
                }
            }

            transform: Translate {
                id: shift
            }

            SequentialAnimation {
                id: shake

                loops: 2
                NumberAnimation { target: shift; property: "x"; to: -8; duration: 50 }
                NumberAnimation { target: shift; property: "x"; to: 8; duration: 70 }
                NumberAnimation { target: shift; property: "x"; to: 0; duration: 50 }
            }

            TextInput {
                id: password

                anchors.fill: parent
                // The same on both sides, so the text stays centred past the language and eye on the right.
                anchors.leftMargin: 74
                anchors.rightMargin: 74
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                passwordCharacter: "●"
                color: root.strong
                font.family: root.font
                font.pixelSize: 14
                // Only the dots are spread; a shown password reads normally.
                font.letterSpacing: root.showPassword ? 0 : 5
                focus: true
                clip: true
                enabled: !root.leaving
                onTextChanged: if (text !== "")
                    root.failed = false
                Keys.onReturnPressed: root.login()
                Keys.onEnterPressed: root.login()
            }

            // Shows or hides the password. Drawn, like every icon in this setup.
            Item {
                id: eye

                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 26
                opacity: 0.45

                Canvas {
                    id: eyeGlyph

                    readonly property bool shown: root.showPassword

                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    onShownChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = root.text;
                        ctx.fillStyle = root.text;
                        ctx.lineWidth = 1.5;
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";
                        ctx.beginPath();
                        ctx.moveTo(1.5, 9);
                        ctx.quadraticCurveTo(9, 1.5, 16.5, 9);
                        ctx.quadraticCurveTo(9, 16.5, 1.5, 9);
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.arc(9, 9, 2.2, 0, Math.PI * 2);
                        ctx.fill();
                        if (shown) {
                            ctx.beginPath();
                            ctx.moveTo(3, 15);
                            ctx.lineTo(15, 3);
                            ctx.stroke();
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.showPassword = !root.showPassword;
                        password.forceActiveFocus();
                    }
                }
            }

            // Keyboard language. A click switches layout.
            Text {
                id: layout

                readonly property var current: keyboard.layouts[keyboard.currentLayout]

                anchors.right: eye.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    const name = (current?.shortName ?? "").toLowerCase();
                    return name === "ara" || name === "ar" ? "AR" : name.slice(0, 2).toUpperCase();
                }
                color: root.muted
                opacity: 0.7
                font.family: root.font
                font.pixelSize: 12

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    enabled: keyboard.layouts.length > 1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length;
                        password.forceActiveFocus();
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: password.text === ""
                text: root.failed ? "Wrong password" : (keyboard.capsLock ? "Caps Lock is on" : "Password")
                color: root.failed ? root.error : root.muted
                font.family: root.font
                font.pixelSize: 13
            }
        }

        // Sleep, restart, power off, bottom right. Drawn, like every icon in this setup.
        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 24
            spacing: 6

            Repeater {
                model: [["sleep", sddm.canSuspend], ["reboot", sddm.canReboot], ["power", sddm.canPowerOff]]

                Rectangle {
                    id: button

                    required property var modelData

                    visible: modelData[1]
                    width: 36
                    height: 36
                    radius: 10
                    color: area.containsMouse ? Qt.rgba(root.raised.r, root.raised.g, root.raised.b, 0.9) : "transparent"

                    Canvas {
                        id: glyph

                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = root.text;
                            ctx.lineWidth = 1.5;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            if (button.modelData[0] === "sleep") {
                                ctx.arc(9, 9, 6.5, Math.PI * 0.2, Math.PI * 1.45);
                                ctx.quadraticCurveTo(6.5, 8, 14.2, 12.8);
                            } else if (button.modelData[0] === "reboot") {
                                ctx.arc(9, 9.5, 6, Math.PI * 1.7, Math.PI * 1.25);
                                ctx.moveTo(12.2, 1.9);
                                ctx.lineTo(12.5, 4.6);
                                ctx.lineTo(15.2, 4.2);
                            } else {
                                ctx.arc(9, 9.8, 6, Math.PI * 1.65, Math.PI * 1.35);
                                ctx.moveTo(9, 2.2);
                                ctx.lineTo(9, 8.5);
                            }
                            ctx.stroke();
                        }
                    }

                    MouseArea {
                        id: area

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: button.modelData[0] === "sleep" ? sddm.suspend() : button.modelData[0] === "reboot" ? sddm.reboot() : sddm.powerOff()
                    }
                }
            }
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
