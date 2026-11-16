# Niri Smoke Checklist

Use this checklist on a live Niri session to verify Flui functionality end-to-end.

Environment: **niri** with Quickshell, single/multi-output, shell started via `qs` or systemd `flui.service`.

## 1. Startup & Hot Reload

- [x] Shell starts cleanly and the island renders on the top or bottom screen edge.
- [x] Touching `shell.qml` or editing any QML file triggers `Reloading configuration…` → `Configuration Loaded` with zero errors.
- [x] Missing or custom wallpaper folders fall back gracefully without blank screens.

## 2. IPC Functionality (`qs ipc call flui <command>`)

All commands must exit with code `0`:

| Command | Expected Result |
|---|---|
| `openExpandedHome` | Opens expanded island view |
| `openControlCenter` | Opens Control Center card grid |
| `openPowerMenu` | Opens system session power menu |
| `openWallpaperSelector` | Opens 3-column wallpaper grid & theme inspector |
| `openThemeSelector` | Opens theme picker |
| `openWifiMenu` | Opens NetworkManager / Wi-Fi menu |
| `openBluetoothMenu` | Opens BlueZ Bluetooth device menu |
| `openMedia` | Opens media player controls & waveform |
| `openNotifications` | Opens notification history pane |
| `cycleLayout` | Smoothly cycles Pill → Notch → Bar |
| `focusToggle` | Toggles Do Not Disturb mode |
| `reset` | Collapses any open panel back to idle island |

## 3. Layouts & Docking

- [x] **Pill**: Compact pill shape displaying time/weather; expands smoothly on hover.
- [x] **Notch**: Sits flush with top display boundary.
- [x] **Bar**: Spans monitor width with FlowCorner edge blending.
- [x] **Autohide**: Hides island offscreen when focus is lost; EdgeTriggerWindow reveals it on mouse approach.

## 4. Theming & Wallpapers

- [x] Wallpaper grid shows 3-column thumbnails with aspect ratio preservation.
- [x] Clicking a wallpaper card enters the detail view and extracts Matugen palettes.
- [x] "Preview (5s)" applies wallpaper and theme in-memory for 5 seconds and rolls back automatically.
- [x] Pressing `Esc` immediately cancels active preview.
- [x] "Apply" writes wallpaper and theme permanently.
- [x] Shuffle timer triggers at configured interval (`15m`, `30m`, `1h`, `3h`, `6h`, `12h`, `1d`).

## 5. System Health & Process Cleanliness

- [x] No zombie subprocesses from `cava`, `pw-dump`, or `lsblk`.
- [x] Night Light toggles cleanly without leaving residual `gammastep` processes.
