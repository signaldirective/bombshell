// UiDivider.qml — a thin separator line.

import QtQuick

Rectangle {
    required property var theme
    height: 1
    implicitHeight: 1
    implicitWidth: parent ? parent.width : 1
    width: parent ? parent.width : 1
    color: theme.sep
}
