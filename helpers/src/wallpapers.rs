use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct WallpaperItem {
    pub path: String,
    pub name: String,
    pub extension: String,
}

pub fn run(dir_path: Option<String>) {
    let target_dir = match dir_path {
        Some(d) => PathBuf::from(d),
        None => {
            let home = env::var("HOME").unwrap_or_else(|_| ".".into());
            PathBuf::from(home).join("Pictures/Wallpapers")
        }
    };

    let items = scan_wallpapers(&target_dir);
    if let Ok(json) = serde_json::to_string(&items) {
        println!("{}", json);
    }
}

pub fn scan_wallpapers(dir: &Path) -> Vec<WallpaperItem> {
    let mut list = Vec::new();
    if !dir.exists() || !dir.is_dir() {
        return list;
    }

    let mut stack = vec![dir.to_path_buf()];
    while let Some(current) = stack.pop() {
        if let Ok(entries) = fs::read_dir(&current) {
            for entry in entries.flatten() {
                let p = entry.path();
                if p.is_dir() {
                    stack.push(p);
                } else if is_image_file(&p) {
                    let file_name = p.file_stem()
                        .and_then(|s| s.to_str())
                        .unwrap_or("wallpaper")
                        .to_string();
                    let ext = p.extension()
                        .and_then(|s| s.to_str())
                        .unwrap_or("")
                        .to_lowercase();
                    list.push(WallpaperItem {
                        path: p.to_string_lossy().to_string(),
                        name: file_name,
                        extension: ext,
                    });
                }
            }
        }
    }

    list.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));
    list
}

fn is_image_file(path: &Path) -> bool {
    if let Some(ext) = path.extension().and_then(|s| s.to_str()) {
        matches!(
            ext.to_lowercase().as_str(),
            "jpg" | "jpeg" | "png" | "webp" | "bmp" | "gif"
        )
    } else {
        false
    }
}
