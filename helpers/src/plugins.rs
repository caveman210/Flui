use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct PluginEntry {
    pub bar: Option<String>,
    pub view: Option<String>,
    pub service: Option<String>,
    pub settings: Option<String>,
    pub backend: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct PluginPanel {
    pub view: Option<String>,
    pub trigger: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct PluginExtension {
    pub slot: String,
    pub source: String,
    pub position: Option<String>, // "append", "prepend", "replace"
    #[serde(skip_deserializing)]
    pub resolved_source: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct PluginManifest {
    pub id: String,
    pub name: Option<String>,
    pub version: Option<String>,
    pub author: Option<String>,
    pub description: Option<String>,
    pub icon: Option<String>,
    pub category: Option<String>,
    pub entry: Option<PluginEntry>,
    pub extensions: Option<Vec<PluginExtension>>,
    pub hooks: Option<String>, // path to hooks.js
    pub theme: Option<String>, // path to theme.json
    pub deps: Option<Vec<String>>, // system binaries/commands required
    pub panel: Option<PluginPanel>,
    pub enabled: Option<bool>,
    #[serde(skip_deserializing)]
    pub dir: Option<String>,
    #[serde(skip_deserializing)]
    pub bar_entry: Option<String>,
    #[serde(skip_deserializing)]
    pub view_entry: Option<String>,
    #[serde(skip_deserializing)]
    pub service_entry: Option<String>,
    #[serde(skip_deserializing)]
    pub backend_entry: Option<String>,
    #[serde(skip_deserializing)]
    pub settings_entry: Option<String>,
    #[serde(skip_deserializing)]
    pub hooks_path: Option<String>,
    #[serde(skip_deserializing)]
    pub theme_path: Option<String>,
    #[serde(skip_deserializing)]
    pub is_valid: bool,
    #[serde(skip_deserializing)]
    pub missing_deps: Vec<String>,
}

pub fn run(dir_path: Option<String>) {
    let base_dir = match dir_path {
        Some(d) => PathBuf::from(d),
        None => {
            let home = env::var("HOME").unwrap_or_else(|_| ".".into());
            PathBuf::from(home).join(".config/quickshell/plugins")
        }
    };

    let plugins = scan_plugins_dir(&base_dir);
    if let Ok(json) = serde_json::to_string(&plugins) {
        println!("{}", json);
    }
}

pub fn scan_plugins_dir(dir: &Path) -> Vec<PluginManifest> {
    let mut list = Vec::new();
    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.flatten() {
            let p = entry.path();
            if p.is_dir() {
                let manifest_path = p.join("plugin.json");
                if manifest_path.exists() {
                    if let Ok(content) = fs::read_to_string(&manifest_path) {
                        if let Ok(mut item) = serde_json::from_str::<PluginManifest>(&content) {
                            let dir_str = p.to_string_lossy().to_string();
                            item.dir = Some(dir_str.clone());

                            // Validate and resolve entrypoints
                            let mut valid = true;
                            if let Some(ref entry) = item.entry {
                                if let Some(ref b) = entry.bar {
                                    let full = p.join(b);
                                    if full.exists() {
                                        item.bar_entry = Some(full.to_string_lossy().to_string());
                                    } else {
                                        valid = false;
                                    }
                                }
                                if let Some(ref v) = entry.view {
                                    let full = p.join(v);
                                    if full.exists() {
                                        item.view_entry = Some(full.to_string_lossy().to_string());
                                    } else {
                                        valid = false;
                                    }
                                }
                                if let Some(ref s) = entry.service {
                                    let full = p.join(s);
                                    if full.exists() {
                                        item.service_entry = Some(full.to_string_lossy().to_string());
                                    } else {
                                        valid = false;
                                    }
                                }
                                if let Some(ref t) = entry.settings {
                                    let full = p.join(t);
                                    if full.exists() {
                                        item.settings_entry = Some(full.to_string_lossy().to_string());
                                    } else {
                                        valid = false;
                                    }
                                }
                            }

                            // Validate and resolve panel view if declared
                            if let Some(ref panel) = item.panel {
                                if let Some(ref v) = panel.view {
                                    let full = p.join(v);
                                    if full.exists() {
                                        item.view_entry = Some(full.to_string_lossy().to_string());
                                    } else {
                                        valid = false;
                                    }
                                }
                            }

                            // Validate and resolve extensions
                            if let Some(ref mut exts) = item.extensions {
                                for ext in exts.iter_mut() {
                                    let ext_full = p.join(&ext.source);
                                    if ext_full.exists() {
                                        ext.resolved_source = Some(ext_full.to_string_lossy().to_string());
                                    } else {
                                        valid = false;
                                    }
                                }
                            }

                            // Auto-detect Service.qml if service_entry was not explicitly declared
                            if item.service_entry.is_none() {
                                let service_qml = p.join("Service.qml");
                                if service_qml.exists() {
                                    item.service_entry = Some(service_qml.to_string_lossy().to_string());
                                }
                            }

                            // Detect backend runner (binary, python, shell, lua, js, ts, etc.)
                            if let Some(ref entry) = item.entry {
                                if let Some(ref b) = entry.backend {
                                    let full = p.join(b);
                                    if full.exists() {
                                        item.backend_entry = Some(full.to_string_lossy().to_string());
                                    }
                                }
                            }
                            if item.backend_entry.is_none() {
                                let probes = [
                                    p.join("bin").join(&item.id),
                                    p.join(&item.id),
                                    p.join("main.rs"),
                                    p.join(format!("{}.py", item.id)),
                                    p.join("main.py"),
                                    p.join("gcal.py"),
                                    p.join(format!("{}.sh", item.id)),
                                    p.join("main.sh"),
                                    p.join(format!("{}.lua", item.id)),
                                    p.join("main.lua"),
                                    p.join(format!("{}.js", item.id)),
                                    p.join("main.js"),
                                    p.join("index.js"),
                                    p.join(format!("{}.ts", item.id)),
                                    p.join("main.ts"),
                                    p.join("index.ts"),
                                    p.join(format!("{}.go", item.id)),
                                    p.join("main.go"),
                                ];
                                for probe in &probes {
                                    if probe.exists() {
                                        item.backend_entry = Some(probe.to_string_lossy().to_string());
                                        break;
                                    }
                                }
                            }

                            // Hooks & Theme paths
                            if let Some(ref h) = item.hooks {
                                let h_full = p.join(h);
                                if h_full.exists() {
                                    item.hooks_path = Some(h_full.to_string_lossy().to_string());
                                }
                            }
                            if let Some(ref t) = item.theme {
                                let t_full = p.join(t);
                                if t_full.exists() {
                                    item.theme_path = Some(t_full.to_string_lossy().to_string());
                                }
                            }

                            // Check for missing system dependencies
                            if let Some(ref dep_list) = item.deps {
                                for dep in dep_list {
                                    let found = Command::new("sh")
                                        .args(["-c", &format!("command -v {} > /dev/null 2>&1", dep)])
                                        .status()
                                        .map(|s| s.success())
                                        .unwrap_or(false);
                                    if !found {
                                        item.missing_deps.push(dep.clone());
                                    }
                                }
                            }

                            item.is_valid = valid;
                            list.push(item);
                        }
                    }
                }
            }
        }
    }
    list
}

pub fn list_plugins() {
    let home = env::var("HOME").unwrap_or_else(|_| ".".into());
    let base_dir = PathBuf::from(home).join(".config/quickshell/plugins");
    let plugins = scan_plugins_dir(&base_dir);
    println!("{:<20} {:<10} {:<14} {}", "ID", "VERSION", "CATEGORY", "BACKEND / SERVICE");
    println!("{}", "-".repeat(70));
    for p in plugins {
        let backend = p.backend_entry.as_deref().map(|s| s.split('/').last().unwrap_or(s)).unwrap_or("-");
        let service = p.service_entry.as_deref().map(|s| s.split('/').last().unwrap_or(s)).unwrap_or("-");
        println!("{:<20} {:<10} {:<14} backend: {}, service: {}",
            p.id,
            p.version.as_deref().unwrap_or("?"),
            p.category.as_deref().unwrap_or("general"),
            backend,
            service
        );
    }
}

pub fn run_plugin(plugin_id: &str, args: &[String]) {
    let home = env::var("HOME").unwrap_or_else(|_| ".".into());
    let plugin_dir = PathBuf::from(&home).join(".config/quickshell/plugins").join(plugin_id);

    if !plugin_dir.exists() {
        eprintln!("Plugin '{}' not found at {:?}", plugin_id, plugin_dir);
        std::process::exit(1);
    }

    // 1. Check if plugin.json specifies entry.backend
    let mut backend_target: Option<PathBuf> = None;
    let manifest_path = plugin_dir.join("plugin.json");
    if manifest_path.exists() {
        if let Ok(content) = fs::read_to_string(&manifest_path) {
            if let Ok(item) = serde_json::from_str::<PluginManifest>(&content) {
                if let Some(entry) = item.entry {
                    if let Some(b) = entry.backend {
                        let full = plugin_dir.join(b);
                        if full.exists() {
                            backend_target = Some(full);
                        }
                    }
                }
            }
        }
    }

    // 2. If not specified in manifest, probe filesystem
    if backend_target.is_none() {
        let bin_path = plugin_dir.join("bin").join(plugin_id);
        if bin_path.exists() {
            backend_target = Some(bin_path);
        } else {
            let target_bin = plugin_dir.join("target/release").join(plugin_id);
            if target_bin.exists() {
                backend_target = Some(target_bin);
            }
        }
    }

    if backend_target.is_none() {
        let probes = [
            format!("{}.py", plugin_id), "main.py".to_string(), "gcal.py".to_string(),
            format!("{}.sh", plugin_id), "main.sh".to_string(),
            format!("{}.lua", plugin_id), "main.lua".to_string(),
            format!("{}.js", plugin_id), "main.js".to_string(), "index.js".to_string(),
            format!("{}.ts", plugin_id), "main.ts".to_string(), "index.ts".to_string(),
            format!("{}.go", plugin_id), "main.go".to_string(),
            plugin_id.to_string(),
        ];
        for probe in &probes {
            let p = plugin_dir.join(probe);
            if p.exists() {
                backend_target = Some(p);
                break;
            }
        }
    }

    // If a Cargo.toml exists, fallback to cargo run
    if backend_target.is_none() && plugin_dir.join("Cargo.toml").exists() {
        let status = Command::new("cargo")
            .arg("run")
            .arg("--release")
            .arg("--manifest-path")
            .arg(plugin_dir.join("Cargo.toml"))
            .arg("--")
            .args(args)
            .status();
        match status {
            Ok(s) => {
                if let Some(code) = s.code() {
                    std::process::exit(code);
                }
                return;
            }
            Err(e) => {
                eprintln!("Failed to cargo run plugin '{}': {}", plugin_id, e);
                std::process::exit(1);
            }
        }
    }

    let target = match backend_target {
        Some(t) => t,
        None => {
            eprintln!("No runnable backend found for plugin '{}'", plugin_id);
            std::process::exit(1);
        }
    };

    let ext = target.extension().and_then(|e| e.to_str()).unwrap_or("");
    let mut cmd = match ext {
        "py" => {
            let mut c = Command::new("python3");
            c.arg(&target);
            c
        }
        "sh" => {
            let mut c = Command::new("bash");
            c.arg(&target);
            c
        }
        "lua" => {
            let mut c = Command::new("lua");
            c.arg(&target);
            c
        }
        "js" => {
            let mut c = Command::new("node");
            c.arg(&target);
            c
        }
        "ts" => {
            let runner = if Command::new("sh").args(["-c", "command -v bun >/dev/null 2>&1"]).status().map(|s| s.success()).unwrap_or(false) {
                "bun"
            } else if Command::new("sh").args(["-c", "command -v deno >/dev/null 2>&1"]).status().map(|s| s.success()).unwrap_or(false) {
                "deno"
            } else {
                "node"
            };
            let mut c = Command::new(runner);
            if runner == "deno" {
                c.arg("run");
            }
            c.arg(&target);
            c
        }
        "go" => {
            let mut c = Command::new("go");
            c.arg("run").arg(&target);
            c
        }
        _ => {
            Command::new(&target)
        }
    };

    cmd.args(args);

    match cmd.status() {
        Ok(status) => {
            if let Some(code) = status.code() {
                std::process::exit(code);
            }
        }
        Err(e) => {
            eprintln!("Failed to execute plugin backend {:?}: {}", target, e);
            std::process::exit(1);
        }
    }
}
