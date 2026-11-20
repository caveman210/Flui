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
pub struct PluginManifest {
    pub id: String,
    pub name: Option<String>,
    pub version: Option<String>,
    pub author: Option<String>,
    pub description: Option<String>,
    pub entry: Option<PluginEntry>,
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
                            if let Some(ref entry) = item.entry {
                                item.bar_entry = entry.bar.as_ref().map(|b| format!("{}/{}", dir_str, b));
                                item.view_entry = entry.view.as_ref().map(|v| format!("{}/{}", dir_str, v));
                                item.service_entry = entry.service.as_ref().map(|s| format!("{}/{}", dir_str, s));
                                item.settings_entry = entry.settings.as_ref().map(|t| format!("{}/{}", dir_str, t));
                            }
                            list.push(item);
                        }
                    }
                }
            }
        }
    }
    list
}
