use std::fs;
use std::path::{Path, PathBuf};

pub fn run(set_val: Option<String>) {
    if let Some(target) = set_val {
        if let Ok(pct) = target.trim_end_matches('%').parse::<u32>() {
            set_brightness_pct(pct);
        }
    }

    println!("{}", get_brightness_pct());
}

fn get_backlight_dir() -> Option<PathBuf> {
    let base = Path::new("/sys/class/backlight");
    if let Ok(entries) = fs::read_dir(base) {
        for entry in entries.flatten() {
            let p = entry.path();
            if p.join("brightness").exists() && p.join("max_brightness").exists() {
                return Some(p);
            }
        }
    }
    None
}

pub fn get_brightness_pct() -> u32 {
    if let Some(dir) = get_backlight_dir() {
        if let (Ok(cur), Ok(max)) = (
            fs::read_to_string(dir.join("brightness")),
            fs::read_to_string(dir.join("max_brightness")),
        ) {
            if let (Ok(c), Ok(m)) = (cur.trim().parse::<u64>(), max.trim().parse::<u64>()) {
                if m > 0 {
                    return ((c as f64 / m as f64) * 100.0).round() as u32;
                }
            }
        }
    }
    50
}

pub fn set_brightness_pct(pct: u32) {
    if let Some(dir) = get_backlight_dir() {
        if let Ok(max_str) = fs::read_to_string(dir.join("max_brightness")) {
            if let Ok(m) = max_str.trim().parse::<u64>() {
                let clamped_pct = pct.min(100);
                let target = ((clamped_pct as f64 / 100.0) * m as f64).round() as u64;
                let _ = fs::write(dir.join("brightness"), target.to_string());
            }
        }
    }
}
