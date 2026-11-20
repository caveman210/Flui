use std::fs;
use std::path::Path;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct SystemInfo {
    pub os: String,
    pub host: String,
    pub kernel: String,
    pub uptime: String,
    pub cpu: String,
    pub gpu: String,
    pub memory: String,
    pub disk: String,
}

pub fn get_info() -> SystemInfo {
    SystemInfo {
        os: read_os_name(),
        host: read_hostname(),
        kernel: read_kernel(),
        uptime: read_uptime(),
        cpu: read_cpu_model(),
        gpu: read_gpu_info(),
        memory: read_memory_summary(),
        disk: read_disk_summary("/"),
    }
}

fn read_os_name() -> String {
    if let Ok(c) = fs::read_to_string("/etc/os-release") {
        for line in c.lines() {
            if line.starts_with("PRETTY_NAME=") {
                return line.trim_start_matches("PRETTY_NAME=").trim_matches('"').to_string();
            }
        }
    }
    "Linux".to_string()
}

fn read_hostname() -> String {
    fs::read_to_string("/etc/hostname")
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|_| "nixpad".to_string())
}

fn read_kernel() -> String {
    fs::read_to_string("/proc/sys/kernel/osrelease")
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|_| "Linux".to_string())
}

fn read_uptime() -> String {
    if let Ok(c) = fs::read_to_string("/proc/uptime") {
        if let Some(sec_str) = c.split_whitespace().next() {
            if let Ok(secs) = sec_str.parse::<f64>() {
                let total_mins = (secs / 60.0) as u64;
                let hours = total_mins / 60;
                let mins = total_mins % 60;
                if hours > 0 {
                    return format!("{}h {}m", hours, mins);
                } else {
                    return format!("{}m", mins);
                }
            }
        }
    }
    "0m".to_string()
}

fn read_cpu_model() -> String {
    if let Ok(c) = fs::read_to_string("/proc/cpuinfo") {
        for line in c.lines() {
            if line.starts_with("model name") {
                if let Some((_, model)) = line.split_once(':') {
                    return model.trim().to_string();
                }
            }
        }
    }
    "CPU".to_string()
}

fn read_gpu_info() -> String {
    let pci_dir = Path::new("/sys/bus/pci/devices");
    if let Ok(entries) = fs::read_dir(pci_dir) {
        for entry in entries.flatten() {
            let class_file = entry.path().join("class");
            if let Ok(class) = fs::read_to_string(class_file) {
                if class.trim().starts_with("0x03") { // PCI Display controller class
                    return "AMD Radeon Graphics".to_string();
                }
            }
        }
    }
    "Integrated Graphics".to_string()
}

fn read_memory_summary() -> String {
    if let Ok(meminfo) = fs::read_to_string("/proc/meminfo") {
        let mut total = 0u64;
        let mut avail = 0u64;
        for line in meminfo.lines() {
            if line.starts_with("MemTotal:") {
                total = parse_kb(line);
            } else if line.starts_with("MemAvailable:") {
                avail = parse_kb(line);
            }
        }
        if total > 0 {
            let used = total.saturating_sub(avail);
            return format!("{:.1} / {:.1} GiB", used as f64 / 1048576.0, total as f64 / 1048576.0);
        }
    }
    "-- / -- GiB".to_string()
}

fn read_disk_summary(mount_point: &str) -> String {
    unsafe {
        let mut stat: libc::statvfs = std::mem::zeroed();
        let c_path = std::ffi::CString::new(mount_point).unwrap();
        if libc::statvfs(c_path.as_ptr(), &mut stat) == 0 {
            let total_bytes = stat.f_blocks as u64 * stat.f_frsize as u64;
            let free_bytes = stat.f_bavail as u64 * stat.f_frsize as u64;
            let used_bytes = total_bytes.saturating_sub(free_bytes);
            let used_gb = used_bytes as f64 / 1_073_741_824.0;
            let total_gb = total_bytes as f64 / 1_073_741_824.0;
            let pct = if total_bytes > 0 { (used_bytes as f64 / total_bytes as f64) * 100.0 } else { 0.0 };
            return format!("{:.1} / {:.1} GiB ({:.0}%)", used_gb, total_gb, pct);
        }
    }
    "-- / -- GiB".to_string()
}

fn parse_kb(line: &str) -> u64 {
    line.split_whitespace()
        .nth(1)
        .and_then(|s| s.parse().ok())
        .unwrap_or(0)
}

pub fn run() {
    let info = get_info();
    if let Ok(json) = serde_json::to_string(&info) {
        println!("{}", json);
    }
}
