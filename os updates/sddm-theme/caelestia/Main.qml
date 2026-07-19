import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

// HyperWebster / Starman SDDM greeter — lock-screen twin.
// Same frosted wallpaper, ken-burns, ambient orbs, centered clock + avatar +
// password glass as LockSurface.qml. Colours / wallpaper / face from theme.conf
// (sddm-theme-sync). Pure QtQuick — no Controls/SddmComponents deps.
Item {
    id: root
    anchors.fill: parent

    property int sessionIndex: sessionModel.lastIndex
    property var sessionNames: ({})
    property var sessionFiles: ({})
    property string sessionName: ""
    property string brandTitle: config.brandTitle || "HyperWebster"
    property string brandSub: config.brandSub || "Starman"
    property int gamingSessionIndex: -1
    property bool passErrored: false
    property int pendingDigit: 0

    readonly property string avatarPath: config.avatar || ""
    readonly property string logoPath: config.logo || ""
    readonly property bool avatarOk: avatarImg.status === Image.Ready
    readonly property string avatarSource: {
        if (root.avatarOk)
            return root.avatarPath.indexOf("file://") === 0 ? root.avatarPath : ("file://" + root.avatarPath)
        if (root.logoPath.length)
            return root.logoPath.indexOf("file://") === 0 ? root.logoPath : ("file://" + root.logoPath)
        return ""
    }

    function hexRgb(hex, a) {
        var h = String(hex || "#000000").replace("#", "")
        if (h.length < 6)
            return Qt.rgba(0, 0, 0, a)
        var r = parseInt(h.substring(0, 2), 16) / 255
        var g = parseInt(h.substring(2, 4), 16) / 255
        var b = parseInt(h.substring(4, 6), 16) / 255
        return Qt.rgba(r, g, b, a)
    }

    function isAllowed(i) {
        var n = sessionNames[i]
        return n !== undefined && n !== "Hyprland" && !/gam(ing|escope)|steam|big picture/i.test(n)
    }

    function isGamingSession(i) {
        var f = sessionFiles[i] || ""
        var n = sessionNames[i] || ""
        if (/gamescope|steam-session|steam\.desktop/i.test(f))
            return true
        if (/gamescope|gaming mode|steam big picture/i.test(n))
            return true
        return false
    }

    function refreshGamingIndex() {
        var found = -1
        for (var i in sessionFiles) {
            var idx = parseInt(i)
            if (isGamingSession(idx)) {
                found = idx
                var f = String(sessionFiles[idx] || "")
                if (/gamescope-session\.desktop$/i.test(f)) {
                    gamingSessionIndex = idx
                    return
                }
            }
        }
        gamingSessionIndex = found
    }

    function allowedCount() {
        var total = 0
        for (var i in sessionNames)
            if (isAllowed(parseInt(i)))
                total++
        return total
    }

    function nextAllowed(from) {
        var count = sessionModel.rowCount()
        for (var step = 1; step <= count; step++) {
            var i = (from + step) % count
            if (isAllowed(i))
                return i
        }
        return from
    }

    function refreshSessionName() {
        if (sessionNames[sessionIndex] !== undefined && !isAllowed(sessionIndex))
            sessionIndex = nextAllowed(sessionIndex)
        sessionName = sessionNames[sessionIndex] !== undefined ? sessionNames[sessionIndex] : "Default"
    }

    function tryLogin() {
        errorText.text = ""
        passErrored = false
        sddm.login(userInput.text, passInput.text, sessionIndex)
    }

    function loginGaming() {
        refreshGamingIndex()
        if (gamingSessionIndex < 0) {
            errorText.text = "Gamescope session missing — install Deckify / Chimera"
            passErrored = true
            return
        }
        if (passInput.text.length === 0) {
            errorText.text = "Enter password, then Starman (or Guide+A)"
            passErrored = true
            passInput.forceActiveFocus()
            shakeAnim.restart()
            return
        }
        sessionIndex = gamingSessionIndex
        sessionName = sessionNames[gamingSessionIndex] || "Gamescope"
        errorText.text = ""
        passErrored = false
        sddm.login(userInput.text, passInput.text, sessionIndex)
    }

    function handleGreeterKeys(event) {
        if (event.key === Qt.Key_F12) {
            root.loginGaming()
            event.accepted = true
        }
    }

    FontLoader {
        id: uiFont
        source: config.fontFile ? "file://" + config.fontFile : ""
    }
    property string fontFamily: uiFont.status === FontLoader.Ready ? uiFont.name : (config.fontFallback || "sans-serif")

    // Hidden probe so avatarOk can flip when the synced face loads
    Image {
        id: avatarImg
        source: root.avatarPath.length
                ? (root.avatarPath.indexOf("file://") === 0 ? root.avatarPath : ("file://" + root.avatarPath))
                : ""
        asynchronous: true
        cache: false
        visible: false
    }

    Repeater {
        model: sessionModel
        delegate: Item {
            visible: false
            Component.onCompleted: {
                root.sessionNames[index] = name
                root.sessionFiles[index] = file
                root.refreshGamingIndex()
                root.refreshSessionName()
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorText.text = "Incorrect — try again"
            passErrored = true
            passInput.text = ""
            passInput.forceActiveFocus()
            shakeAnim.restart()
        }
    }

    // Pending digit from hyperwebster-greeter-pad (lock-screen twin).
    Timer {
        interval: 150
        running: true
        repeat: true
        onTriggered: {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///run/hyperwebster-greeter-pad.digit")
            xhr.onreadystatechange = function () {
                if (xhr.readyState !== XMLHttpRequest.DONE)
                    return
                var n = parseInt(String(xhr.responseText || "").trim(), 10)
                if (!isNaN(n))
                    root.pendingDigit = ((n % 10) + 10) % 10
            }
            xhr.send()
        }
    }

    // ── Live-feeling wallpaper (ken burns) + heavy blur ───────────────────
    Rectangle {
        anchors.fill: parent
        color: "#080a0e"
        z: 0
    }

    Item {
        id: wallHost
        anchors.fill: parent
        clip: true
        z: 1

        Image {
            id: wallImg
            anchors.centerIn: parent
            width: parent.width * 1.12
            height: parent.height * 1.12
            source: config.background
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true

            SequentialAnimation on scale {
                running: wallImg.status === Image.Ready
                loops: Animation.Infinite
                NumberAnimation {
                    from: 1.0
                    to: 1.08
                    duration: 28000
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    from: 1.08
                    to: 1.0
                    duration: 28000
                    easing.type: Easing.InOutSine
                }
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 96
            blurMultiplier: 1.15
            brightness: -0.18
            saturation: 0.18
            contrast: 0.05
        }
    }

    // Soft vignette / scrim
    Rectangle {
        anchors.fill: parent
        z: 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(4 / 255, 6 / 255, 10 / 255, 0.35) }
            GradientStop { position: 0.45; color: Qt.rgba(8 / 255, 10 / 255, 14 / 255, 0.25) }
            GradientStop { position: 1.0; color: Qt.rgba(4 / 255, 6 / 255, 10 / 255, 0.55) }
        }
    }

    // Ambient orbs
    Repeater {
        model: 3
        delegate: Rectangle {
            required property int index
            width: 280 + index * 90
            height: width
            radius: width / 2
            z: 3
            opacity: 0.14 - index * 0.03
            color: index === 0 ? config.primary
                 : (index === 1 ? (config.tertiary || config.primary)
                                : (config.secondary || config.primary))

            x: root.width * (0.15 + index * 0.28) - width / 2
            y: root.height * (0.25 + index * 0.18) - height / 2

            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation {
                    to: root.width * (0.25 + index * 0.2)
                    duration: 16000 + index * 4000
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: root.width * (0.1 + index * 0.25)
                    duration: 16000 + index * 4000
                    easing.type: Easing.InOutSine
                }
            }
            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation {
                    to: root.height * (0.35 + index * 0.12)
                    duration: 18000 + index * 3500
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: root.height * (0.2 + index * 0.15)
                    duration: 18000 + index * 3500
                    easing.type: Easing.InOutSine
                }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1
                blurMax: 64
            }
        }
    }

    // Top status
    RowLayout {
        z: 11
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 22
        anchors.leftMargin: 28
        anchors.rightMargin: 28

        Text {
            text: root.brandTitle + " · Sign in"
            color: root.hexRgb(config.subtext, 0.85)
            font.family: root.fontFamily
            font.pixelSize: 13
        }

        Item { Layout.fillWidth: true }

        Text {
            visible: root.gamingSessionIndex >= 0
            text: "★ Starman ready · Guide+A"
            color: root.hexRgb(config.subtext, 0.7)
            font.family: root.fontFamily
            font.pixelSize: 12
        }
    }

    // Centre — lock twin
    ColumnLayout {
        z: 11
        anchors.centerIn: parent
        spacing: 0

        Text {
            id: clock
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(new Date(), "hh:mm")
            color: config.text
            font.family: root.fontFamily
            font.pixelSize: 108
            font.weight: Font.ExtraLight
            font.letterSpacing: 3
            style: Text.Raised
            styleColor: Qt.rgba(0, 0, 0, 0.35)
        }

        Text {
            id: dateText
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(new Date(), "ddd, d MMMM yyyy")
            color: root.hexRgb(config.subtext, 0.9)
            font.family: root.fontFamily
            font.pixelSize: 15
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                clock.text = Qt.formatTime(new Date(), "hh:mm")
                dateText.text = Qt.formatDate(new Date(), "ddd, d MMMM yyyy")
            }
        }

        // Circular avatar (face → Starman logo → primary disc)
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 56
            implicitWidth: 86
            implicitHeight: 86

            Rectangle {
                anchors.centerIn: parent
                width: 86
                height: 86
                radius: 43
                color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.18)

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 0.6
                    shadowOpacity: 0.45
                    shadowColor: Qt.rgba(0, 0, 0, 0.7)
                    shadowVerticalOffset: 8
                }
            }

            Rectangle {
                id: avatarMask
                anchors.centerIn: parent
                width: 72
                height: 72
                radius: 36
                visible: false
                layer.enabled: true
            }

            Item {
                anchors.centerIn: parent
                width: 72
                height: 72
                visible: root.avatarSource.length > 0
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: avatarMask
                }

                Image {
                    anchors.fill: parent
                    source: root.avatarSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 72
                height: 72
                radius: 36
                visible: root.avatarSource.length === 0
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0; color: config.primary }
                    GradientStop { position: 1; color: config.tertiary || config.primary }
                }
                Text {
                    anchors.centerIn: parent
                    text: (userInput.text || "?").charAt(0).toUpperCase()
                    color: config.onPrimary
                    font.family: root.fontFamily
                    font.pixelSize: 28
                    font.weight: Font.Medium
                }
            }
        }

        // Username (editable on click — looks like lock label)
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 14
            implicitWidth: Math.max(userLabel.implicitWidth, 120)
            implicitHeight: 22

            Text {
                id: userLabel
                anchors.centerIn: parent
                visible: !userInput.activeFocus
                text: userInput.text || "user"
                color: config.text
                font.family: root.fontFamily
                font.pixelSize: 14
            }

            TextInput {
                id: userInput
                anchors.fill: parent
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                font.family: root.fontFamily
                font.pixelSize: 14
                color: config.text
                selectionColor: config.primary
                selectedTextColor: config.onPrimary
                text: userModel.lastUser
                opacity: activeFocus ? 1 : 0
                KeyNavigation.tab: passInput
                Keys.onPressed: function (event) { root.handleGreeterKeys(event) }
            }

            MouseArea {
                anchors.fill: parent
                enabled: !userInput.activeFocus
                cursorShape: Qt.IBeamCursor
                onClicked: {
                    userInput.forceActiveFocus()
                    userInput.selectAll()
                }
            }
        }

        // Frosted password glass
        Rectangle {
            id: passGlass
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 18
            implicitWidth: 340
            implicitHeight: 48
            radius: 16
            color: root.hexRgb(config.surfaceContainer, 0.55)
            border.width: 1
            border.color: root.passErrored
                         ? root.hexRgb(config.error, 0.65)
                         : Qt.rgba(1, 1, 1, 0.16)

            transform: Translate { id: glassShake; x: 0 }

            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: glassShake; property: "x"; to: -10; duration: 40 }
                NumberAnimation { target: glassShake; property: "x"; to: 10; duration: 40 }
                NumberAnimation { target: glassShake; property: "x"; to: -6; duration: 40 }
                NumberAnimation { target: glassShake; property: "x"; to: 6; duration: 40 }
                NumberAnimation { target: glassShake; property: "x"; to: 0; duration: 40 }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 0.8
                shadowOpacity: 0.35
                shadowColor: "#000000"
                shadowVerticalOffset: 10
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 14
                spacing: 10

                Text {
                    text: "▸"
                    color: root.hexRgb(config.subtext, 0.55)
                    font.family: root.fontFamily
                    font.pixelSize: 12
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextInput {
                        id: passInput
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: root.fontFamily
                        font.pixelSize: 15
                        font.letterSpacing: text.length > 0 ? 2 : 0
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: config.text
                        selectionColor: config.primary
                        selectedTextColor: config.onPrimary
                        clip: true
                        focus: true
                        KeyNavigation.tab: userInput
                        onAccepted: root.tryLogin()
                        onTextChanged: {
                            if (root.passErrored && text.length > 0) {
                                root.passErrored = false
                                errorText.text = ""
                            }
                        }
                        Keys.onPressed: function (event) { root.handleGreeterKeys(event) }
                    }

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: passInput.text.length === 0 && !passInput.activeFocus
                        font.family: root.fontFamily
                        font.pixelSize: 15
                        color: root.hexRgb(config.subtext, 0.55)
                        text: "Enter password"
                    }
                }

                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 8
                    color: passInput.text.length > 0 ? root.hexRgb(config.primary, 0.25) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "→"
                        color: passInput.text.length > 0 ? config.primary : root.hexRgb(config.subtext, 0.4)
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (passInput.text.length > 0)
                            root.tryLogin()
                    }
                }
            }
        }

        Text {
            id: errorText
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            Layout.preferredHeight: 14
            text: ""
            color: config.error
            font.family: root.fontFamily
            font.pixelSize: 12
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            text: "Pad digit  " + root.pendingDigit + "   ·  A / RT confirm"
            color: root.hexRgb(config.subtext, 0.7)
            font.family: root.fontFamily
            font.pixelSize: 13
            font.letterSpacing: 1
        }

        // Starman — frosted pill under the glass (greeter-only)
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 18
            visible: root.gamingSessionIndex >= 0
            implicitWidth: starmanCol.implicitWidth + 36
            implicitHeight: 44
            radius: 14
            color: starmanArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: starmanArea.containsMouse ? root.hexRgb(config.primary, 0.55) : Qt.rgba(1, 1, 1, 0.14)

            Column {
                id: starmanCol
                anchors.centerIn: parent
                spacing: 1
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: config.text
                    text: "★  Starman · Gamescope"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    color: root.hexRgb(config.subtext, 0.75)
                    text: "Guide+A · F12"
                }
            }
            MouseArea {
                id: starmanArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.loginGaming()
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            visible: root.sessionName !== "" && root.allowedCount() > 1
            font.family: root.fontFamily
            font.pixelSize: 12
            color: sessionArea.containsMouse ? config.text : root.hexRgb(config.subtext, 0.7)
            text: "Session · " + root.sessionName + "  ⟳"

            MouseArea {
                id: sessionArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.sessionIndex = root.nextAllowed(root.sessionIndex)
                    root.refreshSessionName()
                }
            }
        }
    }

    // Bottom strip
    RowLayout {
        z: 11
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 26
        anchors.leftMargin: 28
        anchors.rightMargin: 28

        Text {
            text: "Enter · D-pad digit · A/RT type · B/LT delete · Start sign in"
            color: root.hexRgb(config.subtext, 0.45)
            font.family: root.fontFamily
            font.pixelSize: 11
        }

        Item { Layout.fillWidth: true }

        Row {
            spacing: 10
            Repeater {
                model: [
                    { label: "Sleep",     enabled: sddm.canSuspend,  act: function() { sddm.suspend() } },
                    { label: "Restart",   enabled: sddm.canReboot,   act: function() { sddm.reboot() } },
                    { label: "Shut down", enabled: sddm.canPowerOff, act: function() { sddm.powerOff() } }
                ]
                delegate: Rectangle {
                    visible: modelData.enabled
                    width: powerLabel.implicitWidth + 28
                    height: 36
                    radius: 12
                    color: powerArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.12)

                    Text {
                        id: powerLabel
                        anchors.centerIn: parent
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        color: powerArea.containsMouse ? config.text : root.hexRgb(config.subtext, 0.85)
                        text: modelData.label
                    }
                    MouseArea {
                        id: powerArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.act()
                    }
                }
            }
        }
    }

    Component.onCompleted: passInput.forceActiveFocus()
}
