# Flui Plugin Development Directive

> **Canonical reference for building plugins for the Flui/Quickshell shell.**
> Core shell files must remain permanently blind to this folder. This document defines the full contract between a plugin and the shell.

---

## 1. Principles

| Rule | Meaning |
|------|---------|
| **Zero hotwiring** | No plugin ID, file path, or assumption about any plugin ever appears in core (`views/`, `services/`, `island/`, `config/`, `components/`). |
| **Strict Disabled State** | When disabled, the plugin is 100% inert: zero views, zero bar items, zero slot injections, zero background services, and its settings panel is completely hidden/inaccessible. Only when enabled does the shell render anything from it. |
| **Fail-safe** | Disabling or deleting a plugin reverts every surface it touched to stock Flui. No crashes, no layout breaks, no residual UI. |
| **Self-contained** | A plugin lives entirely inside `~/.config/quickshell/plugins/<id>/`. It may reference core styles and config via relative paths, but core never references it back. |
| **XDG cache for data** | All tokens, credentials, cached API responses, and user data go to `~/.cache/quickshell/<plugin_id>/`. Never inside the plugin folder or the Flui source tree. |
| **Ponytail** | Build the minimum needed. No code for "later". If a feature isn't wired to real UI it doesn't ship. |

---

## 2. Directory Layout

```
~/.config/quickshell/plugins/
└── my-plugin/
    ├── plugin.json          ← manifest (required)
    ├── Cargo.toml           ← standalone Rust backend manifest (optional)
    ├── main.rs              ← native Rust runner source (optional)
    ├── bin/                 ← compiled backend binaries (optional, gitignored)
    │   └── my-plugin
    ├── Service.qml          ← background singleton (optional)
    ├── Settings.qml         ← inline settings view (optional)
    ├── BarWidget.qml        ← bar injection component (optional)
    ├── CCCard.qml           ← Control Center card (optional)
    ├── SettingsRow.qml      ← row injected into Settings pane (optional)
    ├── PanelView.qml        ← full Island panel (optional)
    ├── Trigger.qml          ← CC button that opens PanelView (optional)
    ├── icons/               ← SVGs or any asset (optional)
    │   └── my-icon.svg
    └── gcal.py              ← helper scripts (optional)
```

---

## 3. The Manifest — `plugin.json`

```jsonc
{
  // ── Identity ────────────────────────────────────────────────
  "id":          "my-plugin",           // unique, lowercase, kebab-case
  "name":        "My Plugin",
  "version":     "1.0.0",
  "author":      "Your Name",
  "description": "One sentence.",
  "icon":        "󰏖",                   // Nerd Font glyph shown in Plugins Menu
  "category":    "productivity",        // productivity | system | networking | ui

  // ── Feature Flags ───────────────────────────────────────────
  "enabled": false,                     // default state at first install

  // ── System Dependencies ──────────────────────────────────────
  // Binaries checked via `command -v` at scan time.
  // Missing deps trigger a notify-send on enable.
  "deps": ["python3", "gammastep"],

  // ── Settings Entry ──────────────────────────────────────────
  // Declares an inline settings pane opened inside the Plugins Menu.
  // Omit if the plugin has no user-configurable options.
  "entry": {
    "settings": "Settings.qml"
  },

  // ── Slot Extensions ─────────────────────────────────────────
  // Inject QML components into named slots across the shell.
  // See §4 for the full slot catalogue.
  "extensions": [
    {
      "slot":     "calendar.events",   // target slot name
      "source":   "CCCard.qml",        // path relative to plugin dir
      "position": "append"             // append | prepend | replace
    }
  ],

  // ── Island Panel View ────────────────────────────────────────
  // Declares a full Island panel this plugin owns.
  // Core registers it in a dynamic view registry — no hardcoding.
  // The plugin is responsible for providing a trigger (button/card)
  // via an extension slot that calls IslandController.openPluginView("<id>").
  "panel": {
    "view":    "PanelView.qml",         // the full panel component
    "trigger": "Trigger.qml"            // optional: also inject a CC button
  }
}
```

All paths in the manifest are **relative to the plugin directory**. `flui-helper plugins` resolves them to absolute paths and marks the plugin `is_valid: false` if any declared file is missing.

---

## 4. Slot Catalogue

These are the named `ExtensionSlot` injection points that exist in core. A plugin may target any combination.

### Bar Slots
| Slot | Surface | Notes |
|------|---------|-------|
| `bar.left` | Left section of pill/notch/bar | Prepend/append widgets |
| `bar.center` | Center of pill/notch/bar | Use sparingly; displaces time/weather |
| `bar.right` | Right section | Icon-sized widgets only |
| `bar.tray` | Tray icon row | Preferred slot for persistent status icons |

### Control Center Slots
| Slot | Surface |
|------|---------|
| `controlCenter.cards` | Card grid in CC panel |
| `controlCenter.header` | Above the card grid |
| `controlCenter.footer` | Below the card grid |

### Settings Pane Slots
| Slot | Surface |
|------|---------|
| `settings.rows` | Row-list area inside the Settings panel |
| `settings.nav` | Navigation button row at the bottom of Settings |

### Calendar Slots
| Slot | Surface |
|------|---------|
| `calendar.events` | Events list inside the Calendar view |
| `calendar.header` | Above the month grid |

### Notification Slots
| Slot | Surface |
|------|---------|
| `notifications.actions` | Extra action buttons on notification cards |

> **Replace mode** (`"position": "replace"`) completely swaps the slot's native content. Use only when the plugin fully owns the feature (e.g. `nightlight-curve` replacing the schedule view with a curve editor). Only one plugin may replace a given slot at a time — first registered wins.

---

## 5. Plugin-Owned Island Panel Views

A plugin can open its own full Island panel — the same visual space used by WiFi, Bluetooth, Night Light, etc. — without touching core.

### How it works

1. Plugin declares `"panel": { "view": "PanelView.qml" }` in `plugin.json`.
2. `PluginService` registers the panel dynamically under a unique mode ID at scan time (no static entries in `IslandState.qml` required).
3. The plugin provides a trigger — a button injected via any slot — that calls:
   ```js
   IslandController.openPluginView("my-plugin")
   ```
4. `IslandController` resolves the mode from the registry and transitions the Island.
5. On dismiss (Escape / outside tap), the Island returns to default — identical to any native panel.

### PanelView.qml contract

```qml
// PanelView.qml — plugin-owned Island panel
import QtQuick
import QtQuick.Layouts
import "../../styles"      // Theme tokens — use these, never hardcode colors
import "../../core"        // IslandController for navigation
import "../../config"      // ConfigStore for reading shared prefs

FocusScope {
    id: root
    implicitWidth: 380      // match other panels; can be wider (max ~600)
    implicitHeight: layout.implicitHeight + 36
    focus: true

    Component.onCompleted: forceActiveFocus()

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            IslandController.reset()     // or openControlCenter() to go back
            event.accepted = true
        }
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        // Back button + title header — match the native panel pattern
        RowLayout {
            Layout.fillWidth: true
            Rectangle {
                width: 32; height: 32; radius: 16
                color: backHover.hovered ? Theme.buttonHover : Theme.surface
                border.width: 1; border.color: Theme.border
                Text { anchors.centerIn: parent; text: "󰁍"; color: Theme.accent; font.family: Theme.iconFont; font.pixelSize: 16 }
                HoverHandler { id: backHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: IslandController.reset() }
            }
            Text { text: "My Panel"; color: Theme.textPrimary; font.pixelSize: 18; font.bold: true; Layout.fillWidth: true }
        }

        // ... your content
    }
}
```

---

## 6. Injecting into the Bar

Widgets in `bar.left`, `bar.right`, `bar.tray` are icon-scale — keep them small and reactive.

```qml
// BarWidget.qml — example tray-style icon
import QtQuick
import "../../styles"
import "../../core"

Item {
    implicitWidth: 28
    implicitHeight: 28

    Text {
        anchors.centerIn: parent
        text: "󰏖"                   // use plugin-local glyphs or Qt.resolvedUrl() for SVGs
        color: Theme.textSecondary
        font.family: Theme.iconFont
        font.pixelSize: 14
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
    TapHandler {
        // Open plugin's panel, or any native panel
        onTapped: IslandController.openPluginView("my-plugin")
    }
}
```

---

## 7. Settings View (Individual Panel within Plugins Menu)

Declare `"entry": { "settings": "Settings.qml" }` if the plugin has any user-configurable state.

### Rules of Plugin Settings:
1. **Enabled-Only Access**: An individual plugin's settings button is visible **only when that plugin is enabled**. When disabled, its settings button is hidden and inaccessible.
2. **Immediate Teardown**: If a plugin is toggled off while its settings panel is currently open, the panel unmounts instantly and the Plugins Menu drops back to the plugin list.
3. **No Shell Hotwiring**: Settings live strictly inside the Plugins Menu inline loader. They must never register dedicated Island modes, create extra windows, or touch core view files.

When enabled, the plugin's card renders an individual `󰒓 Settings` button. Tapping it smoothly transitions the Plugins Menu to that plugin's individual settings panel.

```qml
// Settings.qml — inline plugin settings
import QtQuick
import QtQuick.Layouts
import "../../styles"
import "../../config"

ColumnLayout {
    spacing: 14

    // Your settings rows here — no nav header needed (Plugins Menu owns that)
    Text { text: "API Key"; color: Theme.textSecondary; font.pixelSize: 11 }

    Rectangle {
        Layout.fillWidth: true; height: 32; radius: 6
        color: Theme.surfaceVariant; border.color: Theme.border; border.width: 1
        TextInput {
            anchors.fill: parent; anchors.margins: 8
            color: Theme.textPrimary; font.pixelSize: 12
            text: ""   // load from XDG cache, not ConfigStore
            onEditingFinished: { /* save to ~/.cache/quickshell/<id>/config.json */ }
        }
    }
}
```

> **Rule**: Settings are opened only inside the Plugins Menu. They must not create new Island modes, new windows, or new QML files in core.

---

## 8. Strict Theming Directives (Derived from Shell)

Plugins must derive **100% of their visual styling from the shell's active theme**, allowing them to automatically adapt to dynamic Matugen colors and wallpaper transitions.

* **Forbidden**: Never use hardcoded hex color strings (e.g. `#1e1e2e`, `#ffffff`).
* **Required**: Import `Theme` via `styles` and use semantic tokens exclusively:
  * **Surfaces**: `Theme.background`, `Theme.surface`, `Theme.surfaceVariant`, `Theme.card`
  * **Borders**: `Theme.border`, `Theme.borderHover`, `Theme.borderSubtle`
  * **Typography**: `Theme.textPrimary`, `Theme.textSecondary`, `Theme.textMuted`
  * **Interactions**: `Theme.accent`, `Theme.buttonBackground`, `Theme.buttonHover`, `Theme.buttonText`
  * **Icons**: `Theme.iconFont` (for general iconography) and `Theme.iconFontMono` (for mono indicators)

---

## 9. Custom Iconography & Assets

All assets live inside the plugin folder. Reference them with `Qt.resolvedUrl()` relative to the QML file:

```qml
// SVG icon
Image {
    source: Qt.resolvedUrl("icons/my-icon.svg")
    width: 20; height: 20
    sourceSize: Qt.size(20, 20)
}

// Inline Nerd Font glyph (preferred — no file needed)
Text {
    text: "󰏖"
    font.family: Theme.iconFont    // or Theme.iconFontMono
    font.pixelSize: 16
    color: Theme.accent
}
```

**Core never references plugin asset paths.** Plugins may bundle any asset they need — SVGs, PNGs, custom font files. Load custom fonts with `FontLoader { source: Qt.resolvedUrl("fonts/MyFont.ttf") }`.

---

## 9. Plugin-Side Services

A plugin may run a background `Singleton` service (`Service.qml`) declared as `"entry": { "service": "Service.qml" }`. It is loaded by `PluginService` only when the plugin is enabled.

```qml
// Service.qml
pragma Singleton
import QtQuick
import Quickshell.Io
import "../../config"

Singleton {
    id: root

    // Poll something, run a process, expose data to extension views
    property var data: []

    Timer {
        interval: 300000   // 5 min
        repeat: true; running: true; triggeredOnStart: true
        onTriggered: root.fetch()
    }

    function fetch() { /* ... */ }
}
```

> Services are loaded/unloaded by `PluginService` on toggle. Do not auto-start by importing from core.

---

## 10. Dependency Declaration

```json
"deps": ["python3", "curl", "gammastep"]
```

- Each entry is a binary name checked via `command -v`.
- `flui-helper plugins` populates `missing_deps: [...]` in the scan output.
- When the user enables a plugin with missing deps, `PluginService` fires a `notify-send` listing them.
- The plugin still enables — deps are advisory (a plugin may work partially without all deps).

---

## 11. Data & Secrets

| What | Where |
|------|-------|
| OAuth tokens | `~/.cache/quickshell/<id>/tokens.json` |
| Credentials | `~/.cache/quickshell/<id>/credentials.json` |
| Cached API data | `~/.cache/quickshell/<id>/cache.json` |
| Plugin config (non-sensitive) | `~/.cache/quickshell/<id>/config.json` |

**Never commit secrets.** Never write to the plugin source directory at runtime.

---

## 12. Checklist Before Shipping a Plugin

- [ ] `plugin.json` is valid JSON with at minimum `id`, `name`, `description`, `icon`, `category`
- [ ] All files declared in manifest exist (or `flui-helper plugins` will mark `is_valid: false`)
- [ ] Every slot target exists in the **Slot Catalogue** (§4)
- [ ] Panel views inherit `FocusScope`, handle `Escape`, use `Theme.*` tokens exclusively
- [ ] Bar widgets are icon-scale (≤32px height)
- [ ] Settings view uses `ColumnLayout` only — no nav header (Plugins Menu provides it)
- [ ] No hardcoded hex colors, pixel sizes outside 8–20px range, or layout widths >600px
- [ ] All assets in plugin folder, referenced via `Qt.resolvedUrl()`
- [ ] Runtime data/secrets in `~/.cache/quickshell/<id>/`, not in plugin folder
- [ ] `deps` declared for every external binary the plugin shells out to
- [ ] Disabling the plugin leaves every surface visually identical to stock Flui

---

## 13. What Core Provides (Read-Only from Plugins)

Plugins may **import and read** but never **modify** core singletons directly:

| Import path | Provides |
|-------------|---------|
| `../../styles` | `Theme` — all color tokens, font refs, border radii |
| `../../config` | `ConfigStore` — shared settings |
| `../../core` | `IslandController` — `reset()`, `openPluginView(id)`, `openSettings()`, `openControlCenter()` |
| `../../services/display` | `NightLightService`, `BrightnessService` |
| `../../services/notification` | `NotificationService` |
| `../../services/power` | `BatteryService`, `UPowerService` |
| `../../services/connectivity` | `NetworkService`, `BluetoothService` |
| `../../services/system` | `AudioService`, `SystemService` |
| `../../island` | `IslandState` — read mode, layout, etc. |

> Plugins must never write to `IslandState.mode` directly. Use `IslandController.openPluginView(id)` for all navigation.
