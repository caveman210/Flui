mod sysmon;
mod plugins;
mod system;
mod wallpapers;
mod storage;
mod brightness;
mod battery;

use std::env;

fn print_usage() {
    println!("flui-helper - Native companion for Quickshell / Flui");
    println!("Usage:");
    println!("  flui-helper sysmon [--stream] [--interval <ms>]");
    println!("  flui-helper plugins [path]");
    println!("  flui-helper plugins list");
    println!("  flui-helper plugins run <plugin_id> [args...]");
    println!("  flui-helper system");
    println!("  flui-helper wallpapers [dir]");
    println!("  flui-helper storage");
    println!("  flui-helper brightness [set_pct]");
    println!("  flui-helper battery");
}

#[tokio::main(flavor = "current_thread")]
async fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        print_usage();
        return;
    }

    match args[1].as_str() {
        "sysmon" => {
            let stream = args.iter().any(|a| a == "--stream");
            let mut interval = 3000;
            for i in 0..args.len() {
                if args[i] == "--interval" && i + 1 < args.len() {
                    if let Ok(val) = args[i + 1].parse::<u64>() {
                        interval = val;
                    }
                }
            }
            sysmon::run(interval, stream);
        }
        "plugins" => {
            if args.len() > 2 && args[2] == "run" {
                if args.len() > 3 {
                    let plugin_id = &args[3];
                    let extra_args = if args.len() > 4 { &args[4..] } else { &[] };
                    plugins::run_plugin(plugin_id, extra_args);
                } else {
                    eprintln!("Usage: flui-helper plugins run <plugin_id> [args...]");
                }
            } else if args.len() > 2 && args[2] == "list" {
                plugins::list_plugins();
            } else if args.len() > 2 && !args[2].starts_with('/') && !args[2].starts_with('.') {
                let plugin_id = &args[2];
                let extra_args = if args.len() > 3 { &args[3..] } else { &[] };
                plugins::run_plugin(plugin_id, extra_args);
            } else {
                let path = if args.len() > 2 {
                    Some(args[2].clone())
                } else {
                    None
                };
                plugins::run(path);
            }
        }
        "plugin" => {
            if args.len() > 2 {
                let plugin_id = &args[2];
                let extra_args = if args.len() > 3 { &args[3..] } else { &[] };
                plugins::run_plugin(plugin_id, extra_args);
            } else {
                eprintln!("Usage: flui-helper plugins run <plugin_id> [args...]");
            }
        }
        "weather" => {
            let extra_args = if args.len() > 2 { &args[2..] } else { &[] };
            plugins::run_plugin("weather", extra_args);
        }
        "quote" => {
            let extra_args = if args.len() > 2 { &args[2..] } else { &[] };
            plugins::run_plugin("quote", extra_args);
        }
        "system" => {
            system::run();
        }
        "wallpapers" | "wallpaper" => {
            let dir = if args.len() > 2 {
                Some(args[2].clone())
            } else {
                None
            };
            wallpapers::run(dir);
        }
        "storage" => {
            storage::run();
        }
        "brightness" => {
            let target = if args.len() > 2 {
                Some(args[2].clone())
            } else {
                None
            };
            brightness::run(target);
        }
        "battery" => {
            battery::run();
        }
        _ => {
            print_usage();
        }
    }
}
