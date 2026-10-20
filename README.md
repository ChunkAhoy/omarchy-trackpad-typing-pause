# omarchy-trackpad-typing-pause

A bar widget for [Omarchy](https://omarchy.org) (Hyprland) that puts a trackpad
icon in the bar with a popup switch for Hyprland's
`input:touchpad:disable_while_typing` setting.

- **On** — the trackpad ignores taps and movement while you type, so palm rests
  don't move the cursor.
- **Off** — the trackpad stays live at all times.

The icon dims when the pause is off. The state is read live from `hyprctl`, so
keybinds, config edits, or `hyprctl` calls made elsewhere keep the icon honest.
Your choice is persisted as a Lua override in Omarchy's Hyprland toggles
directory, so it survives config reloads and reboots.

## Requirements

- Omarchy (or Quickshell + Hyprland with the Omarchy shell)
- Hyprland with `hyprctl eval` support (0.53+)

## Install

```sh
git clone https://github.com/ChunkAhoy/omarchy-trackpad-typing-pause \
  ~/.config/omarchy/plugins/chunkahoy.trackpad-typing-pause
```

Then add the widget to your bar layout in `~/.config/omarchy/shell.json`, e.g.
in the bar's `right` section, after an existing entry:

```json
"chunkahoy.trackpad-typing-pause"
```

Restart the shell:

```sh
omarchy-restart-shell
```

## How it works

- Reads state: `hyprctl getoption input:touchpad:disable_while_typing` (polled
  every 5 s).
- Toggles: `hyprctl eval 'hl.config({ input = { touchpad = {
  disable_while_typing = true|false } } })'` — a partial merge, so other
  touchpad options (natural scroll, tap-to-click, etc.) are untouched.
- Persists: writes `~/.local/state/omarchy/toggles/hypr/touchpad-typing-pause.lua`,
  which Omarchy's Hyprland config auto-loads after your own config, so the
  choice sticks across restarts.

## Uninstall

Remove the plugin directory and the layout entry from `shell.json`, then run
`omarchy-restart-shell`. Optionally delete the persistence file
`~/.local/state/omarchy/toggles/hypr/touchpad-typing-pause.lua` if you want to
go back to whatever your Hyprland config says.
