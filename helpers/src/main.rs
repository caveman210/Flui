mod sysmon;
mod plugins;
mod weather;
mod system;
mod wallpapers;
mod quote;
mod storage;
mod brightness;

use std::env;

fn print_usage() {
    println!("flui-helper - Native companion for Quickshell / Flui");
    println!("Usage:");
    println!("  flui-helper sysmon [--stream] [--interval <ms>]");
    println!("  flui-helper plugins [path]");
    println!("  flui-helper weather [provider] [location]");
    println!("  flui-helper system");
    println!("  flui-helper wallpapers [dir]");
    println!("  flui-helper quote");
    println!("  flui-helper storage");
    println!("  flui-helper brightness [set_pct]");
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
            let path = if args.len() > 2 {
                Some(args[2].clone())
            } else {
                None
            };
            plugins::run(path);
        }
        "weather" => {
            let provider = if args.len() > 2 {
                Some(args[2].clone())
            } else {
                None
            };
            let location = if args.len() > 3 {
                Some(args[3].clone())
            } else {
                None
            };
            weather::run(provider, location).await;
        }
        "system" => {
            system::run();
        }
        "wallpapers" => {
            let dir = if args.len() > 2 {
                Some(args[2].clone())
            } else {
                None
            };
            wallpapers::run(dir);
        }
        "quote" => {
            quote::run().await;
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
        _ => {
            print_usage();
        }
    }
}
