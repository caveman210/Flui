use std::env;
use std::fs;
use std::path::PathBuf;
use std::time::Duration;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct WeatherData {
    pub success: bool,
    pub temp: String,
    pub feels_like: String,
    pub temp_high: String,
    pub temp_low: String,
    pub pressure: String,
    pub uv_index: String,
    pub precip: String,
    pub humidity: String,
    pub wind: String,
    pub condition: String,
    pub icon: String,
    pub city: String,
    #[serde(rename = "providerName")]
    pub provider_name: String,
    pub provider: String,
    pub updated: String,
}

#[tokio::main(flavor = "current_thread")]
async fn main() {
    let args: Vec<String> = env::args().collect();
    let provider = if args.len() > 1 && !args[1].trim().is_empty() {
        Some(args[1].clone())
    } else {
        None
    };
    let location = if args.len() > 2 && !args[2].trim().is_empty() {
        Some(args[2].clone())
    } else {
        None
    };
    run(provider, location).await;
}

pub async fn run(provider_opt: Option<String>, location_opt: Option<String>) {
    let provider = provider_opt.unwrap_or_else(|| "aggregator".to_string());
    let location = location_opt.unwrap_or_default();
    let cache_dir = get_cache_dir();
    let cache_file = cache_dir.join("weather.json");

    let result = match provider.as_str() {
        "wttr" => fetch_wttr(&location).await,
        "openmeteo" | "open-meteo" => fetch_openmeteo(&location).await,
        "metno" => fetch_metno(&location).await,
        _ => fetch_aggregator(&location).await,
    };

    match result {
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
                println!("{{\"success\":false,\"temp\":\"--\",\"feels_like\":\"--\",\"temp_high\":\"--\",\"temp_low\":\"--\",\"pressure\":\"--\",\"uv_index\":\"--\",\"precip\":\"--\",\"humidity\":\"--\",\"wind\":\"--\",\"condition\":\"Offline\",\"icon\":\"󰖐\",\"city\":\"\",\"providerName\":\"Offline\",\"provider\":\"offline\",\"updated\":\"\"}}");
            }
        }
    }
}

async fn fetch_wttr(location: &str) -> Result<WeatherData, Box<dyn std::error::Error>> {
    let url = if location.trim().is_empty() {
        "https://wttr.in/?format=j1".to_string()
    } else {
        format!("https://wttr.in/{}?format=j1", location.trim())
    };

    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(4))
        .user_agent("flui-shell/1.0")
        .build()?;

    let resp = client.get(&url).send().await?;
    let v: serde_json::Value = resp.json().await?;

    let current = v.get("current_condition").and_then(|c| c.get(0)).ok_or("no current")?;
    let temp_c = current.get("temp_C").and_then(|t| t.as_str()).unwrap_or("0");
    let feels_c = current.get("FeelsLikeC").and_then(|f| f.as_str()).unwrap_or(temp_c);
    let humidity = current.get("humidity").and_then(|h| h.as_str()).unwrap_or("--");
    let wind_kmph = current.get("windspeedKmph").and_then(|w| w.as_str()).unwrap_or("--");
    let pressure = current.get("pressure").and_then(|p| p.as_str()).unwrap_or("1013");
    let uv_index = current.get("uvIndex").and_then(|u| u.as_str()).unwrap_or("--");
    let weather_code = current.get("weatherCode").and_then(|w| w.as_str()).unwrap_or("113");
    let desc = current.get("weatherDesc")
        .and_then(|d| d.get(0))
        .and_then(|v| v.get("value"))
        .and_then(|s| s.as_str())
        .unwrap_or("Clear");

    let city = v.get("nearest_area")
        .and_then(|a| a.get(0))
        .and_then(|area| area.get("areaName"))
        .and_then(|an| an.get(0))
        .and_then(|v| v.get("value"))
        .and_then(|s| s.as_str())
        .unwrap_or("")
        .to_string();

    let weather_day = v.get("weather").and_then(|w| w.get(0));
    let max_temp = weather_day.and_then(|w| w.get("maxtempC")).and_then(|m| m.as_str()).unwrap_or(temp_c);
    let min_temp = weather_day.and_then(|w| w.get("mintempC")).and_then(|m| m.as_str()).unwrap_or(temp_c);

    Ok(WeatherData {
        success: true,
        temp: format!("{}°C", temp_c),
        feels_like: format!("{}°C", feels_c),
        temp_high: format!("{}°C", max_temp),
        temp_low: format!("{}°C", min_temp),
        pressure: format!("{} hPa", pressure),
        uv_index: uv_index.to_string(),
        precip: "0 mm".to_string(),
        humidity: format!("{}%", humidity),
        wind: format!("{} km/h", wind_kmph),
        condition: desc.to_string(),
        icon: wttr_code_to_icon(weather_code, !is_night_time()),
        city,
        provider_name: "wttr.in".to_string(),
        provider: "wttr".to_string(),
        updated: current_time_str(),
    })
}

async fn fetch_openmeteo(location: &str) -> Result<WeatherData, Box<dyn std::error::Error>> {
    let (lat, lon, city) = resolve_coordinates(location).await?;
    let url = format!(
        "https://api.open-meteo.com/v1/forecast?latitude={}&longitude={}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,surface_pressure,pressure_msl,wind_speed_10m,is_day,uv_index&daily=temperature_2m_max,temperature_2m_min,uv_index_max&timezone=auto",
        lat, lon
    );

    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(4))
        .user_agent("flui-shell/1.0")
        .build()?;

    let resp = client.get(&url).send().await?;
    let v: serde_json::Value = resp.json().await?;

    let curr = v.get("current").ok_or("no current")?;
    let temp_val = curr.get("temperature_2m").and_then(|t| t.as_f64()).unwrap_or(0.0).round() as i32;
    let feels_val = curr.get("apparent_temperature").and_then(|t| t.as_f64()).unwrap_or(temp_val as f64).round() as i32;
    let humidity = curr.get("relative_humidity_2m").and_then(|h| h.as_f64()).unwrap_or(0.0).round() as i32;
    let wind = curr.get("wind_speed_10m").and_then(|w| w.as_f64()).unwrap_or(0.0).round() as i32;
    let pressure = curr.get("pressure_msl")
        .and_then(|p| p.as_f64())
        .or_else(|| curr.get("surface_pressure").and_then(|p| p.as_f64()))
        .unwrap_or(1013.0)
        .round() as i32;
    let uv = curr.get("uv_index").and_then(|u| u.as_f64()).unwrap_or(0.0);
    let precip = curr.get("precipitation").and_then(|p| p.as_f64()).unwrap_or(0.0);
    let code = curr.get("weather_code").and_then(|c| c.as_i64()).unwrap_or(0) as i32;
    let is_day = curr.get("is_day").and_then(|d| d.as_i64()).map(|d| d == 1).unwrap_or_else(|| !is_night_time());

    let daily = v.get("daily");
    let high = daily.and_then(|d| d.get("temperature_2m_max")).and_then(|a| a.get(0)).and_then(|t| t.as_f64()).unwrap_or(temp_val as f64).round() as i32;
    let low = daily.and_then(|d| d.get("temperature_2m_min")).and_then(|a| a.get(0)).and_then(|t| t.as_f64()).unwrap_or(temp_val as f64).round() as i32;

    let (icon, cond) = wmo_code_to_info(code, is_day);

    Ok(WeatherData {
        success: true,
        temp: format!("{}°C", temp_val),
        feels_like: format!("{}°C", feels_val),
        temp_high: format!("{}°C", high),
        temp_low: format!("{}°C", low),
        pressure: format!("{} hPa", pressure),
        uv_index: format!("{:.1}", uv),
        precip: format!("{:.1} mm", precip),
        humidity: format!("{}%", humidity),
        wind: format!("{} km/h", wind),
        condition: cond,
        icon,
        city,
        provider_name: "Open-Meteo".to_string(),
        provider: "openmeteo".to_string(),
        updated: current_time_str(),
    })
}

async fn fetch_metno(location: &str) -> Result<WeatherData, Box<dyn std::error::Error>> {
    let (lat, lon, city) = resolve_coordinates(location).await?;
    let url = format!(
        "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat={:.4}&lon={:.4}",
        lat, lon
    );

    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(4))
        .user_agent("flui-shell/1.0 github.com/user/flui")
        .build()?;

    let resp = client.get(&url).send().await?;
    let v: serde_json::Value = resp.json().await?;

    let timeseries = v.get("properties")
        .and_then(|p| p.get("timeseries"))
        .and_then(|t| t.get(0))
        .and_then(|t| t.get("data"))
        .ok_or("no metno data")?;

    let instant = timeseries.get("instant").and_then(|i| i.get("details")).ok_or("no details")?;
    let temp = instant.get("air_temperature").and_then(|t| t.as_f64()).unwrap_or(0.0).round() as i32;
    let wind = instant.get("wind_speed").and_then(|w| w.as_f64()).unwrap_or(0.0).round() as i32;
    let humidity = instant.get("relative_humidity").and_then(|h| h.as_f64()).unwrap_or(0.0).round() as i32;
    let pressure = instant.get("air_pressure_at_sea_level").and_then(|p| p.as_f64()).unwrap_or(1013.0).round() as i32;

    Ok(WeatherData {
        success: true,
        temp: format!("{}°C", temp),
        feels_like: format!("{}°C", temp),
        temp_high: format!("{}°C", temp),
        temp_low: format!("{}°C", temp),
        pressure: format!("{} hPa", pressure),
        uv_index: "--".to_string(),
        precip: "0 mm".to_string(),
        humidity: format!("{}%", humidity),
        wind: format!("{} km/h", wind * 36 / 10),
        condition: if !is_night_time() { "Fair".to_string() } else { "Clear Night".to_string() },
        icon: if !is_night_time() { "󰖙".to_string() } else { "󰖔".to_string() },
        city,
        provider_name: "MET Norway".to_string(),
        provider: "metno".to_string(),
        updated: current_time_str(),
    })
}

async fn fetch_aggregator(location: &str) -> Result<WeatherData, Box<dyn std::error::Error>> {
    let om_fut = fetch_openmeteo(location);
    let wttr_fut = fetch_wttr(location);

    let (om_res, wttr_res) = tokio::join!(om_fut, wttr_fut);

    if let (Ok(om), Ok(wt)) = (om_res, wttr_res) {
        let om_t = om.temp.trim_end_matches("°C").parse::<f64>().unwrap_or(0.0);
        let wt_t = wt.temp.trim_end_matches("°C").parse::<f64>().unwrap_or(0.0);
        let avg = ((om_t + wt_t) / 2.0).round() as i32;

        return Ok(WeatherData {
            success: true,
            temp: format!("{}°C", avg),
            feels_like: om.feels_like,
            temp_high: om.temp_high,
            temp_low: om.temp_low,
            pressure: om.pressure,
            uv_index: om.uv_index,
            precip: om.precip,
            humidity: om.humidity,
            wind: om.wind,
            condition: om.condition,
            icon: om.icon,
            city: if !om.city.is_empty() { om.city } else { wt.city },
            provider_name: "Aggregator (Consensus)".to_string(),
            provider: "aggregator".to_string(),
            updated: current_time_str(),
        });
    }

    if let Ok(om) = fetch_openmeteo(location).await {
        return Ok(om);
    }
    if let Ok(wt) = fetch_wttr(location).await {
        return Ok(wt);
    }

    Err("Aggregator failed".into())
}

async fn resolve_coordinates(location: &str) -> Result<(f64, f64, String), Box<dyn std::error::Error>> {
    if !location.trim().is_empty() {
        let url = format!("https://geocoding-api.open-meteo.com/v1/search?name={}&count=1", location.trim());
        let client = reqwest::Client::builder().timeout(Duration::from_secs(3)).build()?;
        if let Ok(resp) = client.get(&url).send().await {
            if let Ok(v) = resp.json::<serde_json::Value>().await {
                if let Some(r) = v.get("results").and_then(|a| a.get(0)) {
                    let lat = r.get("latitude").and_then(|l| l.as_f64()).unwrap_or(0.0);
                    let lon = r.get("longitude").and_then(|l| l.as_f64()).unwrap_or(0.0);
                    let name = r.get("name").and_then(|n| n.as_str()).unwrap_or(location).to_string();
                    return Ok((lat, lon, name));
                }
            }
        }
    }

    let client = reqwest::Client::builder().timeout(Duration::from_secs(3)).build()?;
    if let Ok(resp) = client.get("https://wttr.in/?format=j1").send().await {
        if let Ok(v) = resp.json::<serde_json::Value>().await {
            if let Some(area) = v.get("nearest_area").and_then(|a| a.get(0)) {
                let city = area.get("areaName").and_then(|a| a.get(0)).and_then(|v| v.get("value")).and_then(|s| s.as_str()).unwrap_or("").to_string();
                let lat = area.get("latitude").and_then(|l| l.as_str()).and_then(|s| s.parse().ok()).unwrap_or(0.0);
                let lon = area.get("longitude").and_then(|l| l.as_str()).and_then(|s| s.parse().ok()).unwrap_or(0.0);
                return Ok((lat, lon, city));
            }
        }
    }

    Ok((8.5241, 76.9366, "Thiruvananthapuram".to_string()))
}

fn current_time_str() -> String {
    let mut now: libc::time_t = 0;
    unsafe {
        libc::time(&mut now);
        let mut tm: libc::tm = std::mem::zeroed();
        libc::localtime_r(&now, &mut tm);
        let hour = tm.tm_hour;
        let min = tm.tm_min;
        let (h12, ampm) = if hour == 0 {
            (12, "AM")
        } else if hour < 12 {
            (hour, "AM")
        } else if hour == 12 {
            (12, "PM")
        } else {
            (hour - 12, "PM")
        };
        format!("{}:{:02} {}", h12, min, ampm)
    }
}

fn is_night_time() -> bool {
    let mut now: libc::time_t = 0;
    unsafe {
        libc::time(&mut now);
        let mut tm: libc::tm = std::mem::zeroed();
        libc::localtime_r(&now, &mut tm);
        tm.tm_hour < 6 || tm.tm_hour >= 18
    }
}

fn wmo_code_to_info(code: i32, is_day: bool) -> (String, String) {
    if !is_day {
        return match code {
            0 => ("󰖔".to_string(), "Clear Night".to_string()),
            1 | 2 => ("󰼱".to_string(), "Partly Cloudy".to_string()),
            3 => ("󰖐".to_string(), "Overcast".to_string()),
            45 | 48 => ("󰖑".to_string(), "Fog".to_string()),
            51 | 53 | 55 => ("󰖗".to_string(), "Drizzle".to_string()),
            61 | 63 | 65 | 80 | 81 | 82 => ("󰖖".to_string(), "Rain".to_string()),
            71 | 73 | 75 | 85 | 86 => ("󰖘".to_string(), "Snow".to_string()),
            95 | 96 | 99 => ("󰖓".to_string(), "Thunderstorm".to_string()),
            _ => ("󰖐".to_string(), "Overcast".to_string()),
        };
    }

    match code {
        0 => ("󰖙".to_string(), "Clear Sky".to_string()),
        1 | 2 => ("󰖕".to_string(), "Partly Cloudy".to_string()),
        3 => ("󰖐".to_string(), "Overcast".to_string()),
        45 | 48 => ("󰖑".to_string(), "Fog".to_string()),
        51 | 53 | 55 => ("󰖗".to_string(), "Drizzle".to_string()),
        61 | 63 | 65 | 80 | 81 | 82 => ("󰖖".to_string(), "Rain".to_string()),
        71 | 73 | 75 | 85 | 86 => ("󰖘".to_string(), "Snow".to_string()),
        95 | 96 | 99 => ("󰖓".to_string(), "Thunderstorm".to_string()),
        _ => ("󰖐".to_string(), "Overcast".to_string()),
    }
}

fn wttr_code_to_icon(code: &str, is_day: bool) -> String {
    match code {
        "113" => if is_day { "󰖙".to_string() } else { "󰖔".to_string() },
        "116" => if is_day { "󰖕".to_string() } else { "󰼱".to_string() },
        "119" | "122" => "󰖐".to_string(),
        "143" | "248" | "260" => "󰖑".to_string(),
        "176" | "263" | "266" | "293" | "296" | "299" | "302" | "305" | "308" => "󰖖".to_string(),
        "200" | "386" | "389" | "392" | "395" => "󰖓".to_string(),
        "227" | "230" | "323" | "326" | "329" | "332" | "335" | "338" => "󰖘".to_string(),
        _ => "󰖐".to_string(),
    }
}

fn get_cache_dir() -> PathBuf {
    let home = env::var("HOME").unwrap_or_else(|_| ".".into());
    PathBuf::from(home).join(".cache/flui")
}
