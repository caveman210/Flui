use std::fs;
use std::io::{self, Write};
use std::path::PathBuf;
use std::thread;
use std::time::Duration;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct SysMetrics {
    pub temp: i32,
    pub cpu_usage: f32,
    pub mem_used_mb: u64,
    pub mem_total_mb: u64,
    pub mem_pct: f32,
}

struct CpuSample {
    idle: u64,
    total: u64,
}

pub fn run(interval_ms: u64, stream: bool) {
    let stdout = io::stdout();
    let mut handle = stdout.lock();
    let mut prev_cpu = read_cpu_sample();

    loop {
        thread::sleep(Duration::from_millis(interval_ms));
        let curr_cpu = read_cpu_sample();
        let total_diff = curr_cpu.total.saturating_sub(prev_cpu.total);
        let idle_diff = curr_cpu.idle.saturating_sub(prev_cpu.idle);
        let cpu_usage = if total_diff > 0 {
            100.0 * (1.0 - (idle_diff as f32 / total_diff as f32))
        } else {
            0.0
        };
        prev_cpu = curr_cpu;

        let temp = read_cpu_temp();
        let (mem_used, mem_total, mem_pct) = read_mem_info();

        let metrics = SysMetrics {
            temp,
            cpu_usage: (cpu_usage * 10.0).round() / 10.0,
            mem_used_mb: mem_used,
            mem_total_mb: mem_total,
            mem_pct: (mem_pct * 10.0).round() / 10.0,
        };

        if let Ok(json) = serde_json::to_string(&metrics) {
            let _ = writeln!(handle, "{}", json);
            let _ = handle.flush();
        }

        if !stream {
            break;
        }
    }
}

pub fn read_cpu_temp() -> i32 {
    let zones = glob_paths("/sys/class/thermal/thermal_zone*/temp");
    for zone in zones {
        if let Ok(content) = fs::read_to_string(&zone) {
            if let Ok(raw) = content.trim().parse::<i64>() {
                if raw > 0 {
                    return (raw / 1000) as i32;
                }
            }
        }
    }
    let hwmon = glob_paths("/sys/class/hwmon/hwmon*/temp1_input");
    for sensor in hwmon {
        if let Ok(content) = fs::read_to_string(&sensor) {
            if let Ok(raw) = content.trim().parse::<i64>() {
                if raw > 0 {
                    return (raw / 1000) as i32;
                }
            }
        }
    }
    45
}

fn glob_paths(pattern: &str) -> Vec<PathBuf> {
    let mut results = Vec::new();
    if let Some((dir, prefix_suffix)) = pattern.rsplit_once('/') {
        if let Ok(entries) = fs::read_dir(dir.split('*').next().unwrap_or(dir)) {
            for entry in entries.flatten() {
                let path = entry.path();
                if let Some(name) = path.file_name().and_then(|n| n.to_str()) {
                    if prefix_suffix.starts_with('*') || name.starts_with("thermal_zone") || name.starts_with("hwmon") {
                        let candidate = if pattern.ends_with("/temp") {
                            path.join("temp")
                        } else if pattern.ends_with("/temp1_input") {
                            path.join("temp1_input")
                        } else {
                            path
                        };
                        if candidate.exists() {
                            results.push(candidate);
                        }
                    }
                }
            }
        }
    }
    results
}

fn read_mem_info() -> (u64, u64, f32) {
    if let Ok(meminfo) = fs::read_to_string("/proc/meminfo") {
        let mut total = 0u64;
        let mut avail = 0u64;
        for line in meminfo.lines() {
            if line.starts_with("MemTotal:") {
                total = parse_mem_kb(line);
            } else if line.starts_with("MemAvailable:") {
                avail = parse_mem_kb(line);
            }
            if total > 0 && avail > 0 {
                break;
            }
        }
        if total > 0 {
            let used = total.saturating_sub(avail);
            let total_mb = total / 1024;
            let used_mb = used / 1024;
            let pct = (used as f32 / total as f32) * 100.0;
            return (used_mb, total_mb, pct);
        }
    }
    (0, 0, 0.0)
}

fn parse_mem_kb(line: &str) -> u64 {
    line.split_whitespace()
        .nth(1)
        .and_then(|s| s.parse::<u64>().ok())
        .unwrap_or(0)
}

fn read_cpu_sample() -> CpuSample {
    if let Ok(stat) = fs::read_to_string("/proc/stat") {
        if let Some(line) = stat.lines().next() {
            let parts: Vec<u64> = line
                .split_whitespace()
                .skip(1)
                .filter_map(|s| s.parse().ok())
                .collect();
            if parts.len() >= 4 {
                let idle = parts[3] + parts.get(4).unwrap_or(&0);
                let total: u64 = parts.iter().sum();
                return CpuSample { idle, total };
            }
        }
    }
    CpuSample { idle: 0, total: 0 }
}
