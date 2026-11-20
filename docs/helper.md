# Flui Native Rust Helpers — Complete Architecture & Implementation Plan

## 1. Executive Summary & Objective

### Current State
Quickshell / Flui currently depends on periodic shell pipelines for telemetry and background tasks:
- **CPU & Thermal Monitoring:** Periodic invocation of `bash -c "cat /sys/class/thermal/... | head -n1"`.
- **Plugin Directory Discovery:** Running external Python (`python3 -c "import json, glob..."`) or `find` / `cat` shell commands to scan manifests.
- **Weather & Network Data:** Ad-hoc curl / bash requests or JavaScript timers polling remote endpoints.

### Bottleneck
Spawning a process in Linux involves `clone`/`fork`, `execve`, dynamic linking, memory allocation, and tear-down. Doing this every 2–5 seconds causes continuous CPU wakeups, context switches, and power consumption on portable laptops.

### Goal
Replace periodic shell forks with high-performance native Rust micro-services that:
1. Stay resident with negligible memory footprint (~2–4 MB RSS).
2. Utilize native kernel interfaces (`/proc`, `/sys`, `inotify`, D-Bus) without shell intermediaries.
3. Stream structured JSON to Quickshell via standard I/O pipes or local Unix sockets.
4. Consume **0% CPU** when idle by leveraging async event-driven sleep and kernel push notifications.

---

## 2. Architecture & Concurrency Model

### Threading & CPU Utilization
A common concern with background helpers is thread proliferation and CPU starvation. Rust avoids this through **M:N cooperative multitasking**:

```
+--------------------------------------------------------------------------+
|                            flui-helper Daemon                            |
|                                                                          |
|  [ Task 1: Thermals ]     [ Task 2: inotify ]     [ Task 3: IPC Server ]  |
|   Polls /sys (3s sleep)    Kernel event-driven     Async socket read/write|
|            \                       |                       /             |
|             +----------------------+----------------------+              |
|                                    |                                     |
|                       Tokio Single-Threaded Runtime                      |
|                         (1 OS Thread, 0% idle CPU)                       |
+--------------------------------------------------------------------------+
                                     │ JSON stream via Unix Socket / stdout
                                     ▼
                      [ Quickshell Engine / QML ]
```

- **Thread Count:** Running with `tokio::runtime::Builder::new_current_thread()` or `smol` confines the entire daemon to **a single OS thread**.
- **CPU Idle State:** When waiting for timers or file system events, the thread enters `epoll_wait` / `io_uring`, taking 0 CPU cycles.

---

## 3. Structural Decomposition: Binaries & Roles

The plan accommodates both **standalone modular binaries** and a **unified multicall CLI**.

```
quickshell/
├── helpers/
│   ├── Cargo.toml
│   └── src/
│       ├── main.rs            # CLI entry point (dispatch subcommands)
│       ├── sysmon/            # Thermal & hardware metrics
│       ├── plugins/           # Plugin directory scanner & inotify watcher
│       └── ipc/               # Unix domain socket server
```

### Module 1: `sysmon` (Hardware & Thermals)
- **Role:** Direct access to Linux `/sys/class/thermal/` and `/proc/stat`.
- **Execution:** Reads raw kernel memory pseudo-files directly without spawning subshells. Calculates CPU delta percentages and thermal averages.
- **Output:** Emits concise JSON lines:
  ```json
  {"temp": 46, "cpu_usage": 12.4, "mem_used_pct": 34.2}
  ```

### Module 2: `plugins` (Manifest Scanner & Inotify Watcher)
- **Role:** Watches `~/.config/quickshell/plugins/`.
- **Execution:** Registers an `inotify` watch with the kernel via the `notify` crate. Instead of rescanning on timers, the kernel notifies the process the moment a file is added, edited, or deleted.
- **Output:** Immediately yields updated plugin catalogue JSON to Quickshell.

### Module 3: `ipc` (Socket Interface)
- **Role:** Local Unix Domain Socket at `/run/user/$UID/flui.sock`.
- **Execution:** Allows Quickshell (or user scripts / keybinds) to trigger actions or query states instantaneously with sub-millisecond roundtrips.

---

## 4. Communication Specifications (QML Integration)

### Method A: Stdout Pipe Stream (Simplest, Zero Protocol Overhead)
Quickshell spawns the helper once and reads continuous line-delimited events:

```qml
// In Quickshell QML
Process {
    id: sysmonDaemon
    command: ["flui-helper", "sysmon", "--stream", "--interval", "3000"]
    running: true

    stdout: StdioCollector {
        onStreamFinished: { /* auto-restart if exited */ }
        // Each newline triggers line parsing without subshell overhead
    }
}
```

### Method B: Unix Domain Socket (`Quickshell.Io.Socket`)
For bidirectional control and multiplexed telemetry:

```qml
import Quickshell.Io

Socket {
    id: fluiSocket
    path: Quickshell.env("XDG_RUNTIME_DIR") + "/flui.sock"
    connected: true

    onMessageReceived: function(msg) {
        var event = JSON.parse(msg);
        if (event.type === "sysinfo") {
            BarState.cpuTemp = event.temp;
        } else if (event.type === "plugins_changed") {
            PluginService.reload(event.data);
        }
    }
}
```

---

## 5. Phased Implementation Roadmap

### Phase 1: Toolchain & Scaffolding
1. Enter Nix development shell:
   ```bash
   nix-shell -p cargo rustc
   ```
2. Create workspace at `~/.config/quickshell/helpers/`.
3. Configure `Cargo.toml` with `tokio`, `serde`, `serde_json`, `notify`, and `sysinfo`.

### Phase 2: Implement Core Modules
1. **`sysmon`:** Implement direct file reads from `/sys/class/thermal/thermal_zone*/temp` and package into JSON stream.
2. **`plugins`:** Implement `notify` directory watcher on `~/.config/quickshell/plugins/` to emit manifest changes on creation/deletion.

### Phase 3: Quickshell Client Integration
1. Replace shell timers in `PluginService.qml` with connection to `flui-helper plugins`.
2. Replace thermal bash subprocesses in bar widgets with subscription to `flui-helper sysmon`.

### Phase 4: Packaging & Systemd User Service
1. Compile stripped release binary (`cargo build --release`, target size < 2 MB).
2. Symlink binary to `~/.local/bin/flui-helper` or integrate into NixOS home-manager configuration.
3. (Optional) Run as systemd user unit: `~/.config/systemd/user/flui-helper.service`.

---

## 6. Benchmarking & Verification Metrics

| Metric | Current Shell/Python Implementation | Native Rust Helper Target | Improvement |
| :--- | :--- | :--- | :--- |
| **Process Spawns / min** | ~40–60 process forks | **0** (persistent process) | 100% reduction |
| **RAM Utilization** | Transient spikes + Python runtime | **~2.5 MB** stable RSS | Minimal baseline |
| **CPU Wakeups** | Continuous timer interrupts | Pure event-driven epoll | Battery life saved |
| **Lookup Latency** | 20 ms – 150 ms | **< 0.2 ms** | Instant UI updates |
