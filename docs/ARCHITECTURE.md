# Flui Architecture

Flui is an adaptive desktop shell and dynamic island built with Quickshell for modern Wayland compositors (Hyprland, Niri, Sway). It runs as a single Quickshell `ShellRoot` (`shell.qml`) managing long-lived data services, layer-shell windows, and on-demand modal panels.

```
shell.qml                 entry point (ShellRoot)
├── core/                 singletons: shared state, Placement, IslandController
├── island/               dynamic island engine: state, interaction, ViewHost
├── services/             headless data & event providers (zero UI)
├── windows/              Wayland layer-shell surfaces (Island, OSD, EdgeReveal)
├── views/                layout-specific and panel views (Pill, Notch, Bar, Panels)
├── components/           reusable UI primitives and sections
├── styles/               active theme tokens, geometry metrics, and theme palettes
├── scripts/              lightweight system helpers (volume, brightness, Cava)
├── config/               compositor configuration templates (Hyprland, Niri)
├── templates/            bundled Matugen Material You template files
└── assets/               icons, app rules, and graphic assets
```

## Core Engine

- **`IslandState`**: In-memory state tracking active island layout (`pill`, `notch`, `bar`), active panel modes, and transient interaction states.
- **`IslandController`**: Centralized state dispatcher handling all panel transitions (`openExpanded`, `openWallpaperSelector`, `cycleLayout`, `reset`).
- **`StatusManager`**: Event-driven OSD coordinator for volume, brightness, workspace, and device connectivity toasts.

## Services (Headless & Event-Driven)

Data services operate independently from visual UI layers:
- **Audio & Media**: `AudioService`, `MicrophoneService`, `MediaService` (MPRIS), `CavaService` (visualizer with PipeWire integration).
- **Appearance**:
  - `WallpaperService`: Directory scanner, `awww` transition manager, automatic interval shuffling, and 5-second ephemeral palette preview.
  - `ThemeService`: Dynamic Matugen file reader (`Theme.qml`) and external theme switcher.
- **Hardware & Environment**:
  - `StorageService`: `lsblk`-based filesystem and storage device monitor with percentage thresholds.
  - `WeatherService`: Multi-provider engine (Open-Meteo, wttr.in, MET Norway, Aggregator) with stale-cache fallback.
  - `NightLightService`: Temperature and gamma ramp controller with custom S-curve and linear easing.
  - `BatteryService` & `LowBatteryService`: Hardware power monitor prioritizing low-battery alerts in the secondary bubble.
- **IPC & System**:
  - `IslandIPC`: Quickshell Unix socket listener bound to target `flui`.
  - `NotificationService` & `NotificationStore`: Desktop notification daemon with persistent avatar caching and daily history.

## Windows & Layout Surfaces

- **`IslandWindow`**: Anchored layer-shell container dynamically adjusting width and shape across Pill, Notch, and Bar layouts.
- **`OsdWindow`**: Non-interactive overlay rendering transient hardware feedback toasts.
- **`EdgeTriggerWindow`**: Border hover strip activating the shell when autohide is enabled.
- **`FirstRunWindow`**: Compact floating setup card for wallpaper folder discovery and permission-gated app theming.

## Packaging & Deployment

- **`package.nix`**: Hermetic Nix derivation installing the shell source into `$out/share/flui` with runtime binary wrappers.
- **`flake.nix`**: Flake exporting `packages.default` and `homeManagerModules.default` (`programs.flui`).
- **`settings.json` / `settings.json.example`**: Persistent JSON configuration for wallpaper paths, layout choices, and app theming permissions.
