# Flui Architecture

Flui is an adaptive desktop shell and dynamic island built with Quickshell for modern Wayland compositors (Hyprland, Niri, Sway). It runs as a single Quickshell `ShellRoot` (`shell.qml`) managing long-lived data services, layer-shell windows, and on-demand modal panels.

```
shell.qml                 entry point (ShellRoot)
├── core/                 singletons: shared state, Placement, IslandController
├── island/               dynamic island engine: state, interaction, ViewHost
├── services/             headless data & event providers (zero UI) + PluginService
├── plugins/              hot-pluggable self-contained plugins (gcal-sync, nightlight-curve)
├── helpers/              high-performance Rust backend (flui-helper)
├── windows/              Wayland layer-shell surfaces (Island, OSD, EdgeReveal)
├── views/                layout-specific and panel views (Pill, Notch, Bar, Panels)
├── components/           reusable UI primitives, sections, and ExtensionSlot
├── styles/               active theme tokens, qmldir, and theme palettes
├── scripts/              lightweight system helpers (volume, Cava)
├── config/               compositor configuration templates (Hyprland, Niri)
├── templates/            bundled Matugen Material You template files
└── assets/               icons, app rules, and graphic assets
```

## Core Engine

- **`IslandState`**: In-memory state tracking active island layout (`pill`, `notch`, `bar`), active panel modes (including `pluginsMenuMode` and `pluginViewMode`), and transient interaction states.
- **`IslandController`**: Centralized state dispatcher handling all panel transitions (`openExpanded`, `openWallpaperSelector`, `openPluginsMenu`, `openPluginView`, `cycleLayout`, `reset`).
- **`StatusManager`**: Event-driven OSD coordinator for volume, brightness, workspace, and device connectivity toasts.

## Services (Headless & Event-Driven)

Data services operate independently from visual UI layers:
- **Audio & Media**: `AudioService`, `MicrophoneService`, `MediaService` (MPRIS), `CavaService` (visualizer with PipeWire integration).
- **Appearance**:
  - `WallpaperService`: Directory scanner, `awww` transition manager, automatic interval shuffling, and 5-second ephemeral palette preview.
  - `ThemeService`: Dynamic Matugen file reader (`Theme.qml`) and external theme switcher.
- **Hardware & Environment**:
  - `StorageService`: `lsblk`-based filesystem and storage device monitor with percentage thresholds.
  - `NightLightService`: Binary Wayland gamma schedule daemon (3500K–5500K targets). Advanced curve progression is modularized into `plugins/nightlight-curve`.
  - `BatteryService` & `LowBatteryService`: Hardware power monitor prioritizing low-battery alerts in the secondary bubble.
- **Plugins & Extensibility**:
  - `PluginService`: Registry scanner and dynamic lifecycle controller for hot-pluggable extensions (`plugins/weather`, `plugins/quote`, `plugins/nightlight-curve`, `plugins/gcal-sync`).
  - `ExtensionSlot`: Zero-cost declarative component injection point for bar, CC, settings, calendar, and notification slots.
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

## Plug-and-Play Plugin System

Flui enforces a strict **zero-hotwiring** policy: core views provide named declarative extension slots, but remain permanently blind to what plugins exist.
- Manifest schema, lifecycle contracts, and security rules are detailed in [docs/PLUGIN_DIRECTIVE.md](PLUGIN_DIRECTIVE.md).
- User cache and credentials must reside in `~/.cache/quickshell/<plugin_id>/`.
- When disabled, plugins are completely inert: 0 slot injections, 0 background services, and settings panels are inaccessible.

## Native Rust Backend (`flui-helper`)

Background metrics, hardware polling, and manifest validation are delegated to a unified Rust binary (`helpers/`):
- Eliminates Python runtime overhead in hot paths.
- Provides sub-millisecond JSON outputs for storage, battery, quotes, brightness, system monitoring, and plugin discovery.
- Documented in [docs/helper.md](helper.md).
