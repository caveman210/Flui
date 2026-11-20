use std::fs;
use std::path::{Path, PathBuf};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct StorageDevice {
    pub name: String,
    pub path: String,
    pub label: String,
    pub model: String,
    #[serde(rename = "fsType")]
    pub fs_type: String,
    pub mountpoint: String,
    pub size: u64,
    pub used: u64,
    pub free: u64,
    #[serde(rename = "usedPercent")]
    pub used_percent: f32,
    pub removable: bool,
}

pub fn run() {
    let devices = scan_storage();
    if let Ok(json) = serde_json::to_string(&devices) {
        println!("{}", json);
    }
}

pub fn scan_storage() -> Vec<StorageDevice> {
    let mut results = Vec::new();

    if let Ok(mounts) = fs::read_to_string("/proc/mounts") {
        for line in mounts.lines() {
            let parts: Vec<&str> = line.split_whitespace().collect();
            if parts.len() >= 3 {
                let dev_path = parts[0];
                let mount_point = parts[1];
                let fs_type = parts[2];

                // Only consider real physical block devices (/dev/sd*, /dev/nvme*, /dev/mapper*)
                if dev_path.starts_with("/dev/sd") || dev_path.starts_with("/dev/nvme") || dev_path.starts_with("/dev/mapper") {
                    if let Some(info) = inspect_mount(dev_path, mount_point, fs_type) {
                        results.push(info);
                    }
                }
            }
        }
    }

    results
}

fn inspect_mount(dev_path: &str, mount_point: &str, fs_type: &str) -> Option<StorageDevice> {
    unsafe {
        let mut stat: libc::statvfs = std::mem::zeroed();
        let c_mount = std::ffi::CString::new(mount_point).ok()?;
        if libc::statvfs(c_mount.as_ptr(), &mut stat) == 0 {
            let total = stat.f_blocks as u64 * stat.f_frsize as u64;
            let free = stat.f_bavail as u64 * stat.f_frsize as u64;
            if total == 0 {
                return None;
            }
            let used = total.saturating_sub(free);
            let used_percent = ((used as f64 / total as f64) * 100.0) as f32;

            let dev_name = Path::new(dev_path).file_name()?.to_string_lossy().to_string();
            let removable = is_removable(&dev_name);

            return Some(StorageDevice {
                name: dev_name,
                path: dev_path.to_string(),
                label: mount_point.to_string(),
                model: "Disk Drive".to_string(),
                fs_type: fs_type.to_string(),
                mountpoint: mount_point.to_string(),
                size: total,
                used,
                free,
                used_percent: (used_percent * 10.0).round() / 10.0,
                removable,
            });
        }
    }
    None
}

fn is_removable(dev_name: &str) -> bool {
    // Check /sys/block/<parent>/removable
    let clean = dev_name.trim_start_matches("/dev/");
    let sys_path = PathBuf::from("/sys/class/block").join(clean).join("removable");
    if let Ok(c) = fs::read_to_string(sys_path) {
        return c.trim() == "1";
    }
    false
}
