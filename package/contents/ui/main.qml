/*
    Lights Out: "turn off" individual screens by covering them with a black
    window drawn by KWin itself. The outputs stay enabled and in the layout,
    so windows and the desktop don't get rearranged. Useful on OLED and
    local-dimming panels, where black pixels or zones are off.

    Notes on KWin internal windows (checked against KWin 6.8):
    - They stack in the overlay layer, above panels and fullscreen windows.
    - They never take keyboard focus, so a cover can't steal keystrokes (and
      can't react to Esc either; use the global shortcuts).
    - Cursor shapes aren't implemented for them, so the pointer stays visible.
*/
import QtQuick
import QtQuick.Window as QQW // `Window` alone resolves to KWin's (uncreatable) type
import QtQml.Models
import org.kde.kwin

Item {
    id: root

    // Connector names (DP-3, HDMI-A-1, ...) of the covered outputs, sorted.
    property var covered: []

    function isCovered(name) {
        return covered.indexOf(name) >= 0;
    }

    function setCovered(name, on) {
        if (isCovered(name) === on)
            return;
        const list = covered.filter(n => n !== name);
        if (on)
            list.push(name);
        covered = list.sort();
    }

    function toggle(name) {
        setCovered(name, !isCovered(name));
    }

    // The `lights-out` CLI reads the state back from these journal lines.
    onCoveredChanged: console.info("lights-out: covered=" + covered.join(","))
    Component.onCompleted: console.info("lights-out: covered=")

    // Forget outputs that were unplugged or disabled, so they come back
    // uncovered.
    Connections {
        target: Workspace
        function onScreensChanged() {
            const present = Workspace.screens.map(s => s.name);
            const list = root.covered.filter(n => present.indexOf(n) >= 0);
            if (list.length !== root.covered.length)
                root.covered = list;
        }
    }

    // ------------------------------------------------------------ covers ---
    Instantiator {
        model: Workspace.screens
        delegate: QQW.Window {
            readonly property var output: modelData

            visible: root.isCovered(output.name)
            flags: Qt.BypassWindowManagerHint | Qt.FramelessWindowHint
            color: "black"
            x: output.geometry.x
            y: output.geometry.y
            width: output.geometry.width
            height: output.geometry.height

            // Swallow clicks and scrolling, so the hidden windows underneath
            // don't receive them.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onWheel: wheel => wheel.accepted = true
            }
        }
    }

    // --------------------------------------------------------- shortcuts ---
    // The `lights-out` CLI invokes these by name; keep the names stable.
    ShortcutHandler {
        name: "Lights Out: Toggle Screen Under Cursor"
        text: "Lights Out: Toggle the screen under the cursor"
        sequence: "Meta+Ctrl+L"
        onActivated: {
            const screen = Workspace.screenAt(Workspace.cursorPos);
            if (screen)
                root.toggle(screen.name);
        }
    }

    ShortcutHandler {
        name: "Lights Out: Uncover All"
        text: "Lights Out: Uncover all screens"
        sequence: "Meta+Ctrl+Shift+L"
        onActivated: root.covered = []
    }

    // Really power off every screen (DPMS), like `kscreen-doctor --dpms off`.
    // Scripts can't run commands, so ask PowerDevil through its own "Turn Off
    // Screen" action. Any input wakes the screens. If PowerDevil isn't
    // reachable, cover every screen instead.
    ShortcutHandler {
        name: "Lights Out: Turn Off All Screens"
        text: "Lights Out: Turn off all screens (power off)"
        sequence: "Meta+Ctrl+Alt+L"
        onActivated: dpmsOff.call()
    }

    DBusCall {
        id: dpmsOff
        service: "org.kde.kglobalaccel"
        path: "/component/org_kde_powerdevil"
        dbusInterface: "org.kde.kglobalaccel.Component"
        method: "invokeShortcut"
        arguments: ["Turn Off Screen"]
        onFailed: root.covered = Workspace.screens.map(s => s.name).sort()
    }

    Instantiator {
        model: Workspace.screens
        delegate: ShortcutHandler {
            name: "Lights Out: Toggle " + modelData.name
            text: "Lights Out: Toggle " + modelData.name
            onActivated: root.toggle(modelData.name)
        }
    }
}
