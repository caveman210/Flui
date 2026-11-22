use std::fs;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct BatteryLimitInfo {
    pub limit: u32,
    pub has_limit: bool,
    pub mode_name: String,
}

pub fn run() {
    let info = detect_battery_limit();
    if let Ok(json) = serde_json::to_string(&info) {
        println!("{}", json);
    }
}

pub fn detect_battery_limit() -> BatteryLimitInfo {
    // 1. Direct standard kernel charge threshold: /sys/class/power_supply/BAT*/charge_control_end_threshold
    let bat_paths = ["/sys/class/power_supply/BAT0/charge_control_end_threshold",
                     "/sys/class/power_supply/BAT1/charge_control_end_threshold",
                     "/sys/class/power_supply/BATT/charge_control_end_threshold"];
    for p in bat_paths {
        if let Ok(c) = fs::read_to_string(p) {
            if let Ok(val) = c.trim().parse::<u32>() {
                if val > 0 && val <= 100 {
                    return BatteryLimitInfo {
                        limit: val,
                        has_limit: true,
                        mode_name: "Charge Threshold".to_string(),
                    };
                }
            }
        }
    }

    // 2. Lenovo IdeaPad / ThinkPad conservation_mode
    let ideapad_paths = [
        "/sys/devices/pci0000:00/0000:00:14.3/PNP0C09:00/VPC2004:00/conservation_mode",
        "/sys/devices/platform/ideapad_acpi/conservation_mode",
        "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode",
    ];
    for p in ideapad_paths {
        if let Ok(c) = fs::read_to_string(p) {
            if c.trim() == "1" {
                return BatteryLimitInfo {
                    limit: 80,
                    has_limit: true,
                    mode_name: "Lenovo Conservation Mode (80%)".to_string(),
                };
            }
        }
    }

    // 3. Asus battery charge limit: /sys/class/power_supply/BAT*/charge_control_limit_max
    if let Ok(c) = fs::read_to_string("/sys/class/power_supply/BAT0/charge_control_limit_max") {
        if let Ok(val) = c.trim().parse::<u32>() {
            if val > 0 && val <= 100 {
                return BatteryLimitInfo {
                    limit: val,
                    has_limit: true,
                    mode_name: "Asus Battery Limit".to_string(),
                };
            }
        }
    }

    // Default fallback: 100% (no threshold active)
    BatteryLimitInfo {
        limit: 100,
        has_limit: false,
        mode_name: "Full Charge".to_string(),
    }
}
