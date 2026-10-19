// Widget.qml — a bombshell bar-widget for the stock Omarchy bar. Shows a bomb
// glyph; clicking it brings the bombshell bar back.

import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "bombshell.switch"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uf1e2"
    fontFamily: "JetBrainsMono Nerd Font"
    horizontalMargin: 7.5
    tooltipText: "Switch to bombshell"
    onPressed: function(button) {
      if (!root.bar) return
      root.bar.run("bombshell")
    }
  }
}
