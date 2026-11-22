use std::env;
use std::fs;
use std::path::PathBuf;
use std::time::{Duration, SystemTime, UNIX_EPOCH};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct QuoteData {
    pub quote: String,
    pub author: String,
    pub date: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct HistoryEntry {
    quote: String,
    timestamp: u64,
}

#[tokio::main(flavor = "current_thread")]
async fn main() {
    run().await;
}

pub async fn run() {
    let cache_dir = get_cache_dir();
    let cache_file = cache_dir.join("quote.json");
    let history_file = cache_dir.join("quote_history.json");

    let now_ts = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();

    // 1. Load 7-day history (entries younger than 7 days)
    let seven_days_secs = 7 * 86400;
    let mut history: Vec<HistoryEntry> = if let Ok(content) = fs::read_to_string(&history_file) {
        serde_json::from_str::<Vec<HistoryEntry>>(&content)
            .unwrap_or_default()
            .into_iter()
            .filter(|e| now_ts.saturating_sub(e.timestamp) < seven_days_secs)
            .collect()
    } else {
        Vec::new()
    };

    let client = match reqwest::Client::builder()
        .timeout(Duration::from_secs(4))
        .user_agent("flui-shell/1.0 (Linux x86_64)")
        .build() {
        Ok(c) => c,
        Err(_) => {
            print_cached_or_fallback(&cache_file);
            return;
        }
    };

    // Rotating providers pool: 0 = DummyJSON, 1 = FavQs, 2 = ZenQuotes
    let start_idx = (now_ts % 3) as usize;
    let order = [start_idx % 3, (start_idx + 1) % 3, (start_idx + 2) % 3];

    let mut selected_quote: Option<QuoteData> = None;

    for &provider_id in &order {
        for _ in 0..2 {
            let res = match provider_id {
                0 => fetch_dummyjson(&client).await,
                1 => fetch_favqs(&client).await,
                _ => fetch_zenquotes(&client).await,
            };

            if let Ok(cand) = res {
                let norm = cand.quote.trim().to_lowercase();
                let already_used = history.iter().any(|h| h.quote.trim().to_lowercase() == norm);
                if !already_used {
                    selected_quote = Some(cand);
                    break;
                }
            }
        }
        if selected_quote.is_some() {
            break;
        }
    }

    if let Some(quote_data) = selected_quote {
        history.push(HistoryEntry {
            quote: quote_data.quote.clone(),
            timestamp: now_ts,
        });

        let _ = fs::create_dir_all(&cache_dir);
        let _ = fs::write(&history_file, serde_json::to_string(&history).unwrap_or_default());

        if let Ok(json) = serde_json::to_string(&quote_data) {
            let _ = fs::write(&cache_file, &json);
            println!("{}", json);
            return;
        }
    }

    print_cached_or_fallback(&cache_file);
}

fn print_cached_or_fallback(cache_file: &PathBuf) {
    if let Ok(cached) = fs::read_to_string(cache_file) {
        println!("{}", cached);
    } else {
        println!("{{\"quote\":\"Simplicity is the soul of efficiency.\",\"author\":\"Austin Freeman\",\"date\":\"\"}}");
    }
}

async fn fetch_dummyjson(client: &reqwest::Client) -> Result<QuoteData, Box<dyn std::error::Error>> {
    let resp = client.get("https://dummyjson.com/quotes/random").send().await?;
    let item: serde_json::Value = resp.json().await?;
    let q = item.get("quote").and_then(|v| v.as_str()).unwrap_or("").trim().to_string();
    let a = item.get("author").and_then(|v| v.as_str()).unwrap_or("Anonymous").trim().to_string();
    if !q.is_empty() {
        return Ok(QuoteData { quote: q, author: a, date: String::new() });
    }
    Err("dummyjson failed".into())
}

async fn fetch_favqs(client: &reqwest::Client) -> Result<QuoteData, Box<dyn std::error::Error>> {
    let resp = client.get("https://favqs.com/api/qotd").send().await?;
    let root: serde_json::Value = resp.json().await?;
    if let Some(item) = root.get("quote") {
        let q = item.get("body").and_then(|v| v.as_str()).unwrap_or("").trim().to_string();
        let a = item.get("author").and_then(|v| v.as_str()).unwrap_or("Anonymous").trim().to_string();
        if !q.is_empty() {
            return Ok(QuoteData { quote: q, author: a, date: String::new() });
        }
    }
    Err("favqs failed".into())
}

async fn fetch_zenquotes(client: &reqwest::Client) -> Result<QuoteData, Box<dyn std::error::Error>> {
    let resp = client.get("https://zenquotes.io/api/random").send().await?;
    let items: Vec<serde_json::Value> = resp.json().await?;
    if let Some(item) = items.first() {
        let q = item.get("q").and_then(|v| v.as_str()).unwrap_or("").trim().to_string();
        let a = item.get("a").and_then(|v| v.as_str()).unwrap_or("Anonymous").trim().to_string();
        if !q.is_empty() && !q.contains("Too many requests") {
            return Ok(QuoteData { quote: q, author: a, date: String::new() });
        }
    }
    Err("zenquotes failed".into())
}

fn get_cache_dir() -> PathBuf {
    let home = env::var("HOME").unwrap_or_else(|_| ".".into());
    PathBuf::from(home).join(".cache/flui")
}
