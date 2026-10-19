// MenuWidget.qml — opens the bombshell settings/menu panel. The icon is
// selectable from that panel (bomb, omarchy, arch, hyprland, gitkraken, rebel,
// the bundled cat / rockstar / mjolnir / vaultboy artwork, or an image file).

import QtQuick
import QtQuick.Effects

WidgetButton {
    id: menu
    tooltip: "Menu"
    padH: 8

    readonly property bool imageMode: menu.theme.menuIconIsImage(menu.theme.menuIcon)
    readonly property bool tintMode: menu.theme.menuIconIsTinted(menu.theme.menuIcon)

    Text {
        visible: !menu.imageMode
        text: menu.theme.menuIconGlyph()
        font.family: menu.theme.menuIconFont()
        font.pixelSize: menu.theme.fontSize + 3
        color: menu.theme.barFg
        anchors.verticalCenter: parent.verticalCenter
    }

    Image {
        visible: menu.imageMode
        source: menu.theme.menuIconSource()
        sourceSize: Qt.size(128, 128)
        height: Math.round(menu.theme.fontSize * 1.5)
        width: height
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        anchors.verticalCenter: parent.verticalCenter
        // Bundled icons are white masks: colorize them to the bar foreground.
        layer.enabled: menu.tintMode
        layer.effect: MultiEffect {
            colorization: 1
            colorizationColor: menu.theme.barFg
        }
    }

    onPressed: (button) => {
        if (button === Qt.RightButton)
            menu.theme.run("omarchy-menu 2>/dev/null || rofi -show drun 2>/dev/null || true")
        else
            menu.theme.togglePanel("menu", menu.mapToItem(null, menu.width / 2, 0).x)
    }
}
