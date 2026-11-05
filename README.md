# Lights Out

"Turn off" specific screens in KDE Plasma 6 (Wayland) without disconnecting
them, by covering them with black. Useful on OLED and local-dimming panels,
where black pixels or zones are off. `kscreen-doctor --dpms off` can only blank
every screen at once.

It's a KWin script: KWin itself draws a black window over each covered output,
above panels and fullscreen windows. Outputs stay enabled and in the layout,
so windows and the desktop don't get rearranged.

## Install

```bash
./install.sh
```

This installs the script with `kpackagetool6`, enables it, and links the
`lights-out` CLI into `~/.local/bin`. You can also toggle the script in
System Settings > Window Management > KWin Scripts ("Lights Out").

KWin caches QML files until it restarts, so after upgrading a running script,
log out and back in.

## Use

Global shortcuts (change them in System Settings > Keyboard > Shortcuts > KWin):

| Shortcut            | Action                             |
| ------------------- | ---------------------------------- |
| `Meta+Ctrl+L`       | toggle the screen under the cursor |
| `Meta+Ctrl+Shift+L` | uncover all screens                |
| `Meta+Ctrl+Alt+L`   | power off all screens (DPMS); any input wakes them |
| (unbound)           | "Lights Out: Toggle OUTPUT", one per output |

From a terminal:

```bash
lights-out on HDMI-A-1 DP-3   # cover outputs (names from `lights-out list`)
lights-out off [OUTPUT...]    # uncover (no args = all)
lights-out toggle [OUTPUT...] # no args = the screen under the cursor
lights-out status
lights-out list
```

The CLI needs `qdbus6`, `kscreen-doctor` and systemd's journal. It triggers the
script's shortcuts over D-Bus and reads the script's state back from the KWin
journal (`journalctl --user -u plasma-kwin_wayland`).

## Limitations

- Covers can't take keyboard focus (KWin never focuses its own windows), so
  there's no "press Esc to uncover". Use `Meta+Ctrl+Shift+L` instead. On the
  plus side, a cover never takes keystrokes away from your other screens.
- The mouse pointer stays visible over a covered screen: KWin doesn't apply
  cursor shapes to its own windows yet.
- Clicks and scrolling on a covered screen are swallowed. They don't reach
  the windows underneath.
- An unplugged or disabled output is uncovered. Restarting KWin uncovers
  everything.
