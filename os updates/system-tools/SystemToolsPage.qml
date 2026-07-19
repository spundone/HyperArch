pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.components.filedialog
import qs.services
import qs.utils
import qs.modules.nexus
import qs.modules.nexus.common

// HyperWebster: Settings → System tools — account photo + hardware / kernel apps + drives.
PageBase {
    id: root

    title: qsTr("System tools")

    readonly property string facePath: `${Paths.home}/.face`
    readonly property string logoPath: Quickshell.shellDir + "/assets/hyperwebster-logo.png"
    property bool faceReady: false
    property int faceEpoch: 0
    readonly property string avatarSource: (faceReady ? `file://${facePath}` : logoPath) + "?t=" + faceEpoch
    property var drivesStatus: ({ ok: false, service_enabled: false, drives: [] })

    function refreshFace(): void {
        faceEpoch++;
    }

    function refreshDrives(): void {
        drivesProc.running = false;
        drivesProc.running = true;
    }

    function driveStatusText(d): string {
        if (d.ignored)
            return qsTr("Ignored");
        if (d.automounted)
            return qsTr("Mounted · %1").arg(d.mountpoint || d.automount_path || "");
        if (d.mounted)
            return qsTr("Mounted · %1").arg(d.mountpoint || "");
        if (d.automount_path)
            return qsTr("Will mount · %1").arg(d.automount_path);
        return qsTr("Not mounted");
    }

    function openTui(argv): void {
        // Quickshell often inherits PATH without ~/.local/bin. Resolve
        // HyperWebster helpers to absolute paths so kitty does not flash-exit.
        const home = Paths.home;
        const resolved = argv.map(a => {
            if (typeof a !== "string")
                return a;
            if (a.startsWith("/") || a.startsWith("-"))
                return a;
            if (a.indexOf("hyperwebster-") === 0)
                return `${home}/.local/bin/${a}`;
            return a;
        });
        // Dismiss Nexus first — layer-shell settings sit above normal windows,
        // so a TUI.float launched while Settings is open looks like a no-op.
        try {
            root.nState.close();
        } catch (e) {}
        Quickshell.execDetached(["kitty", "--class", "TUI.float", "-e"].concat(resolved));
    }

    function openGui(bin): void {
        // Dismiss Nexus so Qt apps are not hidden under the settings layer.
        try {
            root.nState.close();
        } catch (e) {}
        // Launch in background; only notify if the process dies within ~1s
        // (missing binary, ABI crash). Do not wait for a normal GUI exit.
        Quickshell.execDetached(["sh", "-c",
            'bin="$1"; command -v "$bin" >/dev/null || { notify-send -u critical "System tools" "$bin is not installed"; exit 1; }; '
            + 'err=$(mktemp); "$bin" >"$err" 2>&1 & pid=$!; sleep 0.9; '
            + 'if kill -0 "$pid" 2>/dev/null; then rm -f "$err"; exit 0; fi; '
            + 'wait "$pid" 2>/dev/null || true; msg=$(head -c 240 "$err"); rm -f "$err"; '
            + 'case "$msg" in *alpm_pkg_get_installed_db*) '
            + 'notify-send -u critical "Kernel manager" "Needs CachyOS pacman. Run: sudo hyperwebster-cachy-repo fix-pacman";; '
            + '*) notify-send -u critical "System tools" "${msg:-$bin failed to start}";; esac',
            "sh", bin]);
    }

    // Non-visual objects MUST live inside the layout. PageBase's default
    // property is a single Item — a page-level FileDialog kills the whole
    // shell when Nexus compiles SystemToolsPage ("Cannot assign … to QQuickItem*").
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Process {
            id: drivesProc

            running: true
            command: ["hyperwebster-drives", "status", "--json"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        root.drivesStatus = JSON.parse(text);
                    } catch (e) {
                        root.drivesStatus = ({ ok: false, service_enabled: false, drives: [] });
                    }
                }
            }
        }

        Process {
            id: drivesActionProc

            onExited: root.refreshDrives()
        }

        FileDialog {
            id: facePicker

            title: qsTr("Select a profile picture")
            filterLabel: qsTr("Image files")
            filters: Images.validImageExtensions
            onAccepted: path => {
                if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`))) {
                    root.faceReady = true;
                    root.refreshFace();
                    Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, qsTr("Profile picture changed"), qsTr("Lock screen and dashboard will use this photo.")]);
                } else {
                    Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", qsTr("Unable to change profile picture"), qsTr("Copy to ~/.face failed.")]);
                }
            }
        }

        FileView {
            path: root.facePath
            watchChanges: true
            onFileChanged: {
                reload();
                root.refreshFace();
            }
            onLoaded: {
                root.faceReady = true;
                root.refreshFace();
            }
            onLoadFailed: root.faceReady = false
        }

        SectionHeader {
            text: qsTr("Account")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: accountCol.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: accountCol

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                spacing: Tokens.spacing.medium

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 88
                    implicitHeight: 88

                    Rectangle {
                        id: previewMask

                        anchors.centerIn: parent
                        width: 80
                        height: 80
                        radius: 40
                        visible: false
                        layer.enabled: true
                    }

                    Item {
                        anchors.centerIn: parent
                        width: 80
                        height: 80
                        layer.enabled: true
                        layer.effect: Mask {
                            maskSource: previewMask
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
                        width: 80
                        height: 80
                        radius: 40
                        color: "transparent"
                        border.width: 1
                        border.color: Colours.palette.m3outlineVariant
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: SysInfo.user || qsTr("user")
                    font: Tokens.font.title.medium
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("Shown on the lock screen and dashboard. Photos are cropped to a circle.")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }
            }
        }

        NavRow {
            first: true
            icon: "image"
            label: qsTr("Change profile photo")
            status: qsTr("Saved to ~/.face")
            onClicked: facePicker.open()
        }

        NavRow {
            last: true
            icon: "refresh"
            label: qsTr("Reset to Starman mark")
            status: faceReady ? qsTr("Removes custom photo") : qsTr("Already using Starman")
            onClicked: {
                Quickshell.execDetached(["rm", "-f", root.facePath]);
                root.faceReady = false;
                root.refreshFace();
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", qsTr("Profile picture reset"), qsTr("Lock screen will show the Starman mark.")]);
            }
        }

        SectionHeader {
            text: qsTr("Drives")
        }

        InfoRow {
            first: true
            label: qsTr("Secondary drive automount")
            subtext: qsTr("Premount under /mnt/<label> before login · master switch in Additions")
            value: root.drivesStatus.service_enabled ? qsTr("On") : qsTr("Off")
        }

        NavRow {
            icon: "sync"
            label: qsTr("Remount data drives now")
            status: qsTr("Applies uid/gid for Steam on exFAT/NTFS")
            last: !(root.drivesStatus.drives && root.drivesStatus.drives.length)
            onClicked: {
                drivesActionProc.command = ["hyperwebster-drives", "remount"];
                drivesActionProc.running = true;
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", qsTr("Drives"), qsTr("Remounting secondary disks...")]);
            }
        }

        Repeater {
            model: root.drivesStatus.drives || []

            NavRow {
                required property var modelData
                required property int index

                first: false
                last: index === (root.drivesStatus.drives.length - 1)
                icon: modelData.ignored ? "visibility_off" : "hard_drive"
                label: {
                    const name = (modelData.label && String(modelData.label).length) ? String(modelData.label) : (modelData.name || qsTr("Disk"));
                    const fs = modelData.fstype ? (" · " + modelData.fstype) : "";
                    return name + fs;
                }
                status: {
                    let s = root.driveStatusText(modelData);
                    if (modelData.fat_family)
                        s += qsTr(" · no exFAT symlinks");
                    return s;
                }
                onClicked: {
                    if (modelData.ignored) {
                        drivesActionProc.command = ["hyperwebster-drives", "unignore", modelData.uuid];
                        drivesActionProc.running = true;
                        Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", qsTr("Drives"), qsTr("Including in automount")]);
                    } else {
                        drivesActionProc.command = ["hyperwebster-drives", "ignore", modelData.uuid];
                        drivesActionProc.running = true;
                        Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", qsTr("Drives"), qsTr("Ignored for automount - tap again to include")]);
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraSmall
            wrapMode: Text.WordWrap
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            text: qsTr("Tap a drive to ignore or include it in boot automount. Point Steam at /mnt/<label>/… after remount (not /run/media/…).")
        }

        SectionHeader {
            text: qsTr("Display & input")
        }

        NavRow {
            first: true
            icon: "monitor"
            label: qsTr("Display")
            status: qsTr("hyprmoncfg · Super+Ctrl+H")
            onClicked: root.openTui([
                "hyprmoncfg",
                "--hypr-config", `${Paths.home}/.config/caelestia/hypr-user.conf`,
                "--monitors-conf", `${Paths.home}/.config/hypr/monitors.conf`
            ])
        }

        NavRow {
            icon: "keyboard"
            label: qsTr("Keyboard & mouse")
            status: qsTr("keyd remap · Super+Ctrl+I")
            onClicked: root.openTui(["hyperwebster-input-remap"])
        }

        NavRow {
            icon: "volume_up"
            label: qsTr("Sound settings")
            status: qsTr("pavucontrol")
            onClicked: root.openGui("pavucontrol")
        }

        NavRow {
            last: true
            icon: "bluetooth"
            label: qsTr("Bluetooth")
            status: qsTr("Open Connected devices")
            onClicked: {
                const pages = PageRegistry.pages;
                for (let i = 0; i < pages.length; i++) {
                    if (pages[i].icon === "devices_other") {
                        root.nState.currentPageIdx = i;
                        return;
                    }
                }
                root.openGui("blueman-manager");
            }
        }

        SectionHeader {
            text: qsTr("System")
        }

        NavRow {
            first: true
            icon: "memory"
            label: qsTr("CachyOS kernel manager")
            status: qsTr("Install / switch kernels")
            onClicked: root.openGui("cachyos-kernel-manager")
        }

        NavRow {
            icon: "terminal"
            label: qsTr("System monitor")
            status: qsTr("btop")
            onClicked: root.openTui(["btop"])
        }

        NavRow {
            icon: "history"
            label: qsTr("Btrfs snapshots")
            status: qsTr("hyperwebster-snapshots")
            onClicked: root.openTui(["hyperwebster-snapshots"])
        }

        NavRow {
            last: true
            icon: "build"
            label: qsTr("Maintenance menu")
            status: qsTr("Super+Ctrl+Shift+M")
            onClicked: Quickshell.execDetached(["hyperwebster-maint"])
        }
    }
}
