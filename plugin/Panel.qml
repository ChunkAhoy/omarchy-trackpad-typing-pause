import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Trackpad "pause while typing" toggle.
//   left click -> popup with a switch for Hyprland's
//                 input:touchpad:disable_while_typing
// The live value is read from hyprctl so keybinds or config edits made
// elsewhere keep the icon honest. The click is persisted as a Lua override
// in Omarchy's Hyprland toggles directory, the same mechanism as the
// input-device toggles, so the choice survives config reloads and restarts.
BarWidget {
  id: root
  moduleName: "chunkahoy.trackpad-typing-pause"

  property bool enabled: true
  property bool pending: false
  property bool pendingValue: true
  property bool popupOpen: false

  readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME")
    || ((Quickshell.env("HOME") || "") + "/.local/state"))
    + "/omarchy/toggles/hypr/touchpad-typing-pause.lua"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Component.onCompleted: {
    mkdirProc.running = true
    root.readState()
  }

  Process {
    id: mkdirProc
    command: ["mkdir", "-p", root.stateFile.slice(0, root.stateFile.lastIndexOf("/"))]
    stdout: StdioCollector { waitForEnd: true }
  }

  function readState() {
    if (stateProc.running) stateProc.running = false
    stateProc.running = true
  }

  function toggle() {
    if (root.pending) return
    root.pending = true
    root.pendingValue = !root.enabled
    applyProc.command = ["hyprctl", "eval",
      "hl.config({ input = { touchpad = { disable_while_typing = "
      + (root.pendingValue ? "true" : "false") + " } } })"]
    if (applyProc.running) applyProc.running = false
    applyProc.running = true
  }

  function persistFor(value) {
    return "-- Managed by the chunkahoy.trackpad-typing-pause bar widget.\n"
      + "-- Toggle it from the bar; edits here are cosmetic and are not read back.\n"
      + "hl.config({ input = { touchpad = { disable_while_typing = "
      + (value ? "true" : "false") + " } } })\n"
  }

  Process {
    id: stateProc
    command: ["hyprctl", "getoption", "input:touchpad:disable_while_typing"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.enabled = text.indexOf("bool: true") >= 0
        root.pending = false
      }
    }
  }

  Process {
    id: applyProc
    stdout: StdioCollector { waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode === 0) stateFile.setText(root.persistFor(root.pendingValue))
      // Re-read on every monitor's instance of this widget.
      root.broadcast("readState")
    }
  }

  FileView {
    id: stateFile
    path: root.stateFile
    watchChanges: false
    printErrors: false
  }

  // Keep the icon in sync with changes made outside the widget (config
  // reloads, hyprctl from a terminal).
  Timer {
    interval: 5000
    running: !root.pending
    repeat: true
    onTriggered: root.readState()
  }

  function close() {
    root.popupOpen = false
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    iconComponent: root.trackpadGlyph
    dimmed: !root.enabled
    tooltipText: "Trackpad pause while typing: " + (root.enabled ? "on" : "off")
    onPressed: function(b) {
      if (b === Qt.LeftButton) root.popupOpen = !root.popupOpen
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(300))
    contentHeight: popup.fittedContentHeight(cardColumn.implicitHeight)

    Column {
      id: cardColumn
      anchors.fill: parent
      spacing: Style.space(10)

      Row {
        width: parent.width
        spacing: Style.space(10)

        Column {
          spacing: Style.space(3)
          width: parent.width - switchControl.implicitWidth - parent.spacing

          Text {
            textFormat: Text.PlainText
            text: "Pause trackpad while typing"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }

          Text {
            textFormat: Text.PlainText
            text: "When on, the trackpad ignores taps and movement while you type, so palm rests don't move the cursor. When off, the trackpad stays live at all times."
            color: Qt.darker(root.bar.foreground, 1.35)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.Wrap
            width: parent.width
          }
        }

        ToggleSwitch {
          id: switchControl
          anchors.verticalCenter: parent.verticalCenter
          foreground: root.bar.foreground
          accent: root.bar.urgent
          checked: root.enabled
          busy: root.pending
          onToggled: root.toggle()
        }
      }

      Text {
        textFormat: Text.PlainText
        text: "Your choice is saved and stays active across restarts."
        color: Qt.darker(root.bar.foreground, 1.6)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        width: parent.width
        wrapMode: Text.Wrap
      }
    }
  }

  // Classic trackpad: rounded outline with a two-button strip split at the
  // bottom. Colored by hand (dimmed when the pause is off) so it reads the
  // same as the font glyphs around it.
  readonly property Component trackpadGlyph: Component {
    Item {
      id: glyph
      width: parent ? parent.width : Style.bar.iconCanvas
      height: parent ? parent.height : Style.bar.iconCanvas
      readonly property real stroke: Math.max(1, Math.round(Math.min(width, height) / 13))
      readonly property color ink: !root.bar ? Style.foreground
        : root.enabled ? root.bar.foreground : Qt.darker(root.bar.foreground, 1.7)

      Rectangle {
        id: body
        anchors.fill: parent
        radius: Math.min(width, height) * 0.14
        color: "transparent"
        border.width: glyph.stroke
        border.color: glyph.ink
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: glyph.stroke
        anchors.rightMargin: glyph.stroke
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(parent.height * 0.26)
        height: glyph.stroke
        color: glyph.ink
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: glyph.stroke
        height: Math.round(parent.height * 0.26) - glyph.stroke
        width: glyph.stroke
        color: glyph.ink
      }
    }
  }
}
