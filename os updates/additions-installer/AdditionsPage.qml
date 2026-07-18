pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// HyperWebster: Settings → Additions — layer mod toggles + optional software.
// Status cache exposes per-section `toggles` and `installs` arrays so each
// kind uses the correct row type (ToggleRow vs NavRow). Mixing kinds in one
// Repeater left every row as NavRow (chevrons) and install() failed on toggles.
PageBase {
    id: root

    title: qsTr("Additions")

    property var status: ({})
    readonly property var sections: status.sections || []

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Process {
            id: readProc

            running: true
            command: ["sh", "-c", "cat \"${XDG_STATE_HOME:-$HOME/.local/state}/hyperwebster/additions-status.json\" 2>/dev/null"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        root.status = JSON.parse(text);
                    } catch (e) {
                        root.status = {};
                    }
                }
            }
        }

        Process {
            id: checkProc

            command: ["sh", "-c", "\"$HOME/.local/bin/hyperwebster-additions\" status >/dev/null 2>&1"]
            onExited: readProc.running = true
        }

        Process {
            id: installProc

            property string addId: ""

            command: ["kitty", "--class", "TUI.float", "-e", "sh", "-c", "\"$HOME/.local/bin/hyperwebster-additions\" install " + addId + "; printf '\\nPress Enter to close...'; read _"]
            onExited: readProc.running = true
        }

        Process {
            id: toggleProc

            property string addId: ""
            property bool turnOn: false

            command: ["sh", "-c", "\"$HOME/.local/bin/hyperwebster-additions\" " + (turnOn ? "enable " : "disable ") + addId]
            onExited: readProc.running = true
        }

        Repeater {
            model: root.sections

            delegate: ColumnLayout {
                id: sectionBlock

                required property var modelData
                required property int index

                readonly property var toggleItems: modelData.toggles || []
                readonly property var installItems: modelData.installs || []

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    text: sectionBlock.modelData.label || ""
                }

                Repeater {
                    model: sectionBlock.toggleItems

                    ToggleRow {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        first: index === 0
                        last: index === sectionBlock.toggleItems.length - 1
                        text: modelData.name || ""
                        subtext: modelData.desc || ""
                        checked: modelData.enabled === true
                        onToggled: {
                            if (toggleProc.running)
                                return;
                            toggleProc.addId = modelData.id;
                            toggleProc.turnOn = checked;
                            toggleProc.running = true;
                        }
                    }
                }

                Repeater {
                    model: sectionBlock.installItems

                    NavRow {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        first: index === 0
                        last: index === sectionBlock.installItems.length - 1
                        icon: modelData.icon || "extension"
                        label: modelData.name || ""
                        status: modelData.installed ? qsTr("Installed") : (modelData.desc || "")
                        onClicked: {
                            if (!modelData.installed && !installProc.running) {
                                installProc.addId = modelData.id;
                                installProc.running = true;
                            }
                        }
                    }
                }
            }
        }

        InfoRow {
            visible: root.sections.length === 0
            first: true
            last: true
            label: qsTr("No additions manifest")
            value: "—"
        }

        SectionHeader {
            text: qsTr("Actions")
        }

        NavRow {
            first: true
            last: true
            icon: "refresh"
            label: qsTr("Re-check installed state")
            status: installProc.running ? qsTr("Install running in terminal…") : (toggleProc.running ? qsTr("Applying toggle…") : (checkProc.running ? qsTr("Checking…") : qsTr("Refreshes the list above")))
            onClicked: {
                if (!checkProc.running)
                    checkProc.running = true;
            }
        }
    }
}
