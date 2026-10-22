// EditOverlay.qml — the backdrop shown while the bar is being edited.
//
// The bar itself is only a strip along one edge of the screen, so the
// backdrop lives on its own full-screen overlay: everything outside the bar
// is dimmed, and a click out there finishes the edit.
//
// The bar strip is left out of the overlay's input region, so the widgets in
// it stay clickable and draggable while the overlay is up. The overlay sits
// above the bar in the layer order, so it would otherwise swallow every
// click meant for the widgets.

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: overlay
    required property var theme

    // The screen the edit was started on: the one whose menu opened it.
    screen: overlay.theme.editScreen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bombshell-edit"
    // The bar keeps the keyboard, so Escape still finishes the edit.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    visible: overlay.theme.editMode

    readonly property bool bottomBar: overlay.theme.barPosition === "bottom"
    readonly property int strip: overlay.theme.barReserve

    // Everything except the bar strip.
    readonly property int dimY: overlay.bottomBar ? 0 : overlay.strip
    readonly property int dimH: Math.max(0, overlay.height - overlay.strip)

    mask: Region {
        x: 0
        y: overlay.dimY
        width: overlay.width
        height: overlay.dimH
    }

    Rectangle {
        x: 0
        y: overlay.dimY
        width: overlay.width
        height: overlay.dimH
        color: "#000000"
        opacity: 0.32
    }

    MouseArea {
        x: 0
        y: overlay.dimY
        width: overlay.width
        height: overlay.dimH
        onClicked: overlay.theme.exitEditMode()
    }

    // A quiet reminder of how to leave the edit.
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: overlay.bottomBar ? overlay.height - overlay.strip - 26 : overlay.dimY + 24
        text: "Drag widgets to rearrange · Esc to finish"
        color: overlay.theme.ink
        font.family: overlay.theme.mono
        font.pixelSize: overlay.theme.fontSize
        opacity: 0.75
    }
}
