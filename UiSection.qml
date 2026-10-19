// UiSection.qml — small uppercase section label inside a panel.

import QtQuick

Text {
    required property var theme
    property string title: ""

    width: parent ? parent.width : implicitWidth
    text: title
    color: theme.muted
    font.family: theme.mono
    font.pixelSize: theme.fontSize - 2
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 1
    topPadding: 4
    bottomPadding: 0
}
