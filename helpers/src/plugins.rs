use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct PluginEntry {
    pub bar: Option<String>,
    pub view: Option<String>,
    pub service: Option<String>,
    pub settings: Option<String>,
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
    pub settings_entry: Option<String>,
    #[serde(skip_deserializing)]
    pub hooks_path: Option<String>,
    #[serde(skip_deserializing)]
    pub theme_path: Option<String>,
    #[serde(skip_deserializing)]
    pub is_valid: bool,
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
