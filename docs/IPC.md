# Flui IPC Interface

Flui exposes its IPC target under `flui`. Call it from anywhere via the Quickshell CLI:

```bash
qs ipc call flui <command>
```

Or using the wrapped Nix binary:

```bash
flui ipc <command>
```

## Available Commands

### Shell & Core Panels

| Command | Description |
|---|---|
| `openExpandedHome` | Open the expanded island view (clock, media, system status) |
| `openControlCenter` | Open the Control Center panel |
| `openPowerMenu` | Open the system power menu (lock, sleep, reboot, shutdown) |
| `openWallpaperSelector`| Open the 3-column wallpaper grid & theme inspector |
| `openThemeSelector` | Open the theme switcher |
| `openWifiMenu` | Open the Wi-Fi connections menu |
| `openBluetoothMenu` | Open the Bluetooth device pairing menu |
| `openMedia` | Open rich media player controls |
| `openNotifications` | Open the notifications history center |
| `openPluginsMenu` | Open the plugin manager and settings pane |
| `cycleLayout` | Cycle active layout: Pill → Notch → Bar |
| `focusToggle` | Toggle Do Not Disturb (DND) focus state |
| `reset` | Close any active panel and return to idle state |

### Generic Plugin Interface

Flui provides completely generic, decoupled IPC commands for managing and interacting with plugins without hardcoded function names:

```bash
# Call via the 'plugins' scope:
qs ipc call plugins list                     # List all discovered plugins, versions, and statuses
qs ipc call plugins open <plugin_id>         # Open a plugin's panel view (e.g. qs ipc call plugins open weather)
qs ipc call plugins toggle <plugin_id>       # Toggle a plugin on or off
qs ipc call plugins menu                     # Open the plugins management menu
qs ipc call plugins scan                     # Force re-scan and reload of the plugins directory

# Or via the 'flui' scope:
qs ipc call flui plugins <action> [args]     # Generic dispatcher to plugin actions
```

## Compositor Keybindings

### Hyprland (`hyprland.conf` or `hyprland.lua`)

```ini
bind = SUPER, P, exec, qs ipc call flui openPowerMenu
bind = SUPER, W, exec, qs ipc call flui openWallpaperSelector
bind = SUPER, T, exec, qs ipc call flui openThemeSelector
bind = SUPER, C, exec, qs ipc call flui openControlCenter
bind = SUPER, N, exec, qs ipc call flui openNotifications
```

### Niri (`config.kdl`)

```kdl
Mod+P { spawn "qs" "ipc" "call" "flui" "openPowerMenu"; }
Mod+W { spawn "qs" "ipc" "call" "flui" "openWallpaperSelector"; }
Mod+T { spawn "qs" "ipc" "call" "flui" "openThemeSelector"; }
Mod+C { spawn "qs" "ipc" "call" "flui" "openControlCenter"; }
Mod+N { spawn "qs" "ipc" "call" "flui" "openNotifications"; }
```

A ready-made configuration block is available in `config/niri/flui.kdl`.
