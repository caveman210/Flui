use std::env;
use std::fs;
use std::path::PathBuf;
use std::time::Duration;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct QuoteData {
    pub quote: String,
    pub author: String,
    pub date: String,
}

pub async fn run() {
    let cache_dir = get_cache_dir();
    let cache_file = cache_dir.join("quote.json");

    match fetch_quote().await {
        Ok(data) => {
            if let Ok(json) = serde_json::to_string(&data) {
                let _ = fs::create_dir_all(&cache_dir);
                let _ = fs::write(&cache_file, &json);
                println!("{}", json);
            }
        }
        Err(_) => {
            if let Ok(cached) = fs::read_to_string(&cache_file) {
                println!("{}", cached);
            } else {
                println!("{{\"quote\":\"Simplicity is the soul of efficiency.\",\"author\":\"Austin Freeman\",\"date\":\"\"}}");
            }
        }
    }
}

async fn fetch_quote() -> Result<QuoteData, Box<dyn std::error::Error>> {
    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(5))
        .user_agent("flui-shell/1.0")
        .build()?;

    let resp = client.get("https://zenquotes.io/api/today").send().await?;
    let items: Vec<serde_json::Value> = resp.json().await?;

    if let Some(item) = items.first() {
        let q = item.get("q").and_then(|v| v.as_str()).unwrap_or("").trim().to_string();
        let a = item.get("a").and_then(|v| v.as_str()).unwrap_or("Anonymous").trim().to_string();
        let d = item.get("date").and_then(|v| v.as_str()).unwrap_or("").to_string();

        if !q.is_empty() {
            return Ok(QuoteData {
                quote: q,
                author: a,
                date: d,
            });
        }
    }

    Err("empty quote".into())
}

fn get_cache_dir() -> PathBuf {
    let home = env::var("HOME").unwrap_or_else(|_| ".".into());
    PathBuf::from(home).join(".cache/flui")
}
