#!/usr/bin/env python3
import sys
import json
import urllib.request
import urllib.parse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime

USER_AGENT = "quickshell-desktop/1.0 (linux; contact: user@local)"

# WMO Weather code to (icon, condition_text)
WMO_CODES = {
    0: ("󰖙", "Clear Sky"),
    1: ("󰖕", "Mainly Clear"),
    2: ("󰖕", "Partly Cloudy"),
    3: ("󰖐", "Overcast"),
    45: ("󰖑", "Fog"),
    48: ("󰖑", "Depositing Rime Fog"),
    51: ("󰖗", "Light Drizzle"),
    53: ("󰖗", "Moderate Drizzle"),
    55: ("󰖗", "Dense Drizzle"),
    56: ("󰖒", "Light Freezing Drizzle"),
    57: ("󰖒", "Dense Freezing Drizzle"),
    61: ("󰖖", "Slight Rain"),
    63: ("󰖖", "Moderate Rain"),
    65: ("󰖖", "Heavy Rain"),
    66: ("󰖒", "Light Freezing Rain"),
    67: ("󰖒", "Heavy Freezing Rain"),
    71: ("󰖘", "Slight Snow Fall"),
    73: ("󰖘", "Moderate Snow Fall"),
    75: ("󰖘", "Heavy Snow Fall"),
    77: ("󰖘", "Snow Grains"),
    80: ("󰖖", "Slight Rain Showers"),
    81: ("󰖖", "Moderate Rain Showers"),
    82: ("󰖖", "Violent Rain Showers"),
    85: ("󰖘", "Slight Snow Showers"),
    86: ("󰖘", "Heavy Snow Showers"),
    95: ("󰖓", "Thunderstorm"),
    96: ("󰖓", "Thunderstorm with Slight Hail"),
    99: ("󰖓", "Thunderstorm with Heavy Hail")
}

def get_wmo_info(code):
    return WMO_CODES.get(int(code), ("󰖐", "Overcast"))

def get_wttr_icon(code):
    code = int(code)
    if code == 113: return "󰖙"
    if code == 116: return "󰖕"
    if code in (119, 122): return "󰖐"
    if 200 <= code <= 230: return "󰖓"
    if 260 <= code <= 284: return "󰖗"
    if 293 <= code <= 314: return "󰖖"
    if 317 <= code <= 338: return "󰖘"
    if 350 <= code <= 377: return "󰖒"
    return "󰖐"

def get_metno_info(symbol_code):
    sym = symbol_code.lower()
    if "clearsky" in sym or "fair" in sym:
        return ("󰖙", "Clear")
    if "partlycloudy" in sym:
        return ("󰖕", "Partly Cloudy")
    if "cloudy" in sym:
        return ("󰖐", "Cloudy")
    if "thunder" in sym:
        return ("󰖓", "Thunderstorm")
    if "snow" in sym or "sleet" in sym:
        return ("󰖘", "Snow")
    if "rain" in sym or "drizzle" in sym:
        return ("󰖖", "Rain")
    if "fog" in sym:
        return ("󰖑", "Fog")
    return ("󰖐", sym.replace("_", " ").title())

def http_get(url, headers=None, timeout=6):
    req_headers = {"User-Agent": USER_AGENT}
    if headers:
        req_headers.update(headers)
    req = urllib.request.Request(url, headers=req_headers)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))

def detect_geo(loc_override=None):
    if loc_override and loc_override.strip():
        loc = loc_override.strip()
        url = "https://geocoding-api.open-meteo.com/v1/search?name=" + urllib.parse.quote(loc) + "&count=1&language=en&format=json"
        try:
            data = http_get(url, timeout=5)
            if data.get("results"):
                res = data["results"][0]
                return {
                    "lat": res["latitude"],
                    "lon": res["longitude"],
                    "city": res.get("name", loc),
                    "country": res.get("country", "")
                }
        except Exception:
            pass
        return {"lat": None, "lon": None, "city": loc}

    # Auto IP-based Geolocation
    try:
        data = http_get("http://ip-api.com/json/", timeout=4)
        if data.get("status") == "success":
            return {
                "lat": data["lat"],
                "lon": data["lon"],
                "city": data.get("city", ""),
                "country": data.get("country", "")
            }
    except Exception:
        pass

    try:
        data = http_get("https://wttr.in/?format=j1", timeout=5)
        if data.get("nearest_area"):
            area = data["nearest_area"][0]
            city = area.get("areaName", [{}])[0].get("value", "")
            lat = float(area.get("latitude", 0))
            lon = float(area.get("longitude", 0))
            return {"lat": lat, "lon": lon, "city": city}
    except Exception:
        pass

    return {"lat": 0.0, "lon": 0.0, "city": "Current Location"}

def fetch_openmeteo(geo):
    lat = geo.get("lat")
    lon = geo.get("lon")
    city = geo.get("city") or "Weather"

    if lat is None or lon is None:
        raise ValueError("Could not resolve coordinates for Open-Meteo")

    url = (
        f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}"
        "&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,surface_pressure,wind_speed_10m"
        "&daily=temperature_2m_max,temperature_2m_min,uv_index_max&timezone=auto"
    )
    data = http_get(url, timeout=5)
    curr = data["current"]
    daily = data.get("daily", {})

    temp_val = round(float(curr["temperature_2m"]))
    feels_val = round(float(curr.get("apparent_temperature", temp_val)))
    humidity = round(float(curr["relative_humidity_2m"]))
    wind_kmh = round(float(curr["wind_speed_10m"]))
    pressure = round(float(curr.get("surface_pressure", 1013)))
    precip = float(curr.get("precipitation", 0.0))
    code = int(curr["weather_code"])
    icon, condition = get_wmo_info(code)

    high_val = round(float(daily["temperature_2m_max"][0])) if daily.get("temperature_2m_max") else temp_val
    low_val = round(float(daily["temperature_2m_min"][0])) if daily.get("temperature_2m_min") else temp_val
    uv_val = round(float(daily["uv_index_max"][0]), 1) if daily.get("uv_index_max") else 0.0

    return {
        "success": True,
        "provider": "openmeteo",
        "providerName": "Open-Meteo",
        "city": city,
        "temp": f"{temp_val}°C",
        "temp_val": temp_val,
        "feels_like": f"{feels_val}°C",
        "temp_high": f"{high_val}°C",
        "temp_low": f"{low_val}°C",
        "pressure": f"{pressure} hPa",
        "uv_index": str(uv_val),
        "precip": f"{precip} mm",
        "condition": condition,
        "icon": icon,
        "humidity": f"{humidity}%",
        "wind": f"{wind_kmh} km/h",
        "updated": datetime.now().strftime("%H:%M")
    }

def fetch_wttr(loc):
    url = "https://wttr.in/" + urllib.parse.quote(loc or "") + "?format=j1"
    data = http_get(url, timeout=6)
    curr = data["current_condition"][0]
    weather = data.get("weather", [{}])[0]

    city = loc
    if (not city or not city.strip()) and data.get("nearest_area"):
        area = data["nearest_area"][0]
        city = area.get("areaName", [{}])[0].get("value", "")

    temp_val = round(float(curr["temp_C"]))
    feels_val = round(float(curr.get("FeelsLikeC", temp_val)))
    humidity = curr["humidity"]
    wind_kmh = curr["windspeedKmph"]
    pressure = curr.get("pressure", "1013")
    uv_val = curr.get("uvIndex", "0")
    precip = curr.get("precipMM", "0.0")
    condition = curr["weatherDesc"][0]["value"]
    icon = get_wttr_icon(curr["weatherCode"])

    high_val = round(float(weather.get("maxtempC", temp_val))) if weather.get("maxtempC") else temp_val
    low_val = round(float(weather.get("mintempC", temp_val))) if weather.get("mintempC") else temp_val

    return {
        "success": True,
        "provider": "wttr",
        "providerName": "wttr.in",
        "city": city or "Weather",
        "temp": f"{temp_val}°C",
        "temp_val": temp_val,
        "feels_like": f"{feels_val}°C",
        "temp_high": f"{high_val}°C",
        "temp_low": f"{low_val}°C",
        "pressure": f"{pressure} hPa",
        "uv_index": str(uv_val),
        "precip": f"{precip} mm",
        "condition": condition.strip(),
        "icon": icon,
        "humidity": f"{humidity}%",
        "wind": f"{wind_kmh} km/h",
        "updated": datetime.now().strftime("%H:%M")
    }

def fetch_metno(geo):
    lat = geo.get("lat")
    lon = geo.get("lon")
    city = geo.get("city") or "Weather"

    if lat is None or lon is None:
        raise ValueError("Could not resolve coordinates for MET Norway")

    url = f"https://api.met.no/weatherapi/locationforecast/2.0/compact?lat={round(lat, 2)}&lon={round(lon, 2)}"
    data = http_get(url, timeout=6)
    timeseries = data["properties"]["timeseries"]
    latest = timeseries[0]["data"]
    instant = latest["instant"]["details"]

    temp_val = round(float(instant["air_temperature"]))
    humidity = round(float(instant.get("relative_humidity", 0)))
    wind_kmh = round(float(instant.get("wind_speed", 0)) * 3.6)
    pressure = round(float(instant.get("air_pressure_at_sea_level", 1013)))

    precip_val = 0.0
    if "next_1_hours" in latest and "details" in latest["next_1_hours"]:
        precip_val = latest["next_1_hours"]["details"].get("precipitation_amount", 0.0)

    # Calculate day's high and low from the next 24 hours
    temps_24h = [t["data"]["instant"]["details"]["air_temperature"] for t in timeseries[:24] if "instant" in t["data"]]
    high_val = round(max(temps_24h)) if temps_24h else temp_val
    low_val = round(min(temps_24h)) if temps_24h else temp_val

    symbol = ""
    for k in ("next_1_hours", "next_6_hours", "next_12_hours"):
        if k in latest and "summary" in latest[k]:
            symbol = latest[k]["summary"].get("symbol_code", "")
            if symbol:
                break

    icon, condition = get_metno_info(symbol or "clearsky_day")

    return {
        "success": True,
        "provider": "metno",
        "providerName": "MET Norway",
        "city": city,
        "temp": f"{temp_val}°C",
        "temp_val": temp_val,
        "feels_like": f"{temp_val}°C",
        "temp_high": f"{high_val}°C",
        "temp_low": f"{low_val}°C",
        "pressure": f"{pressure} hPa",
        "uv_index": "--",
        "precip": f"{precip_val} mm",
        "condition": condition,
        "icon": icon,
        "humidity": f"{humidity}%",
        "wind": f"{wind_kmh} km/h",
        "updated": datetime.now().strftime("%H:%M")
    }

def fetch_aggregator(loc, geo):
    results = []
    with ThreadPoolExecutor(max_workers=2) as executor:
        f_om = executor.submit(lambda: fetch_openmeteo(geo))
        f_wttr = executor.submit(lambda: fetch_wttr(loc))

        for f in (f_om, f_wttr):
            try:
                res = f.result(timeout=6)
                if res and res.get("success"):
                    results.append(res)
            except Exception:
                pass

    if not results:
        raise RuntimeError("All providers in aggregator failed")

    if len(results) == 1:
        single = results[0]
        single["provider"] = "aggregator"
        single["providerName"] = f"Aggregator ({single['providerName']})"
        return single

    # Consensus average
    t1 = results[0]["temp_val"]
    t2 = results[1]["temp_val"]
    avg_temp = round((t1 + t2) / 2)

    primary = results[0] # Open-Meteo
    secondary = results[1] # wttr

    return {
        "success": True,
        "provider": "aggregator",
        "providerName": "Aggregator",
        "city": primary["city"],
        "temp": f"{avg_temp}°C",
        "temp_val": avg_temp,
        "feels_like": primary.get("feels_like", secondary.get("feels_like", f"{avg_temp}°C")),
        "temp_high": primary.get("temp_high", secondary.get("temp_high", f"{avg_temp}°C")),
        "temp_low": primary.get("temp_low", secondary.get("temp_low", f"{avg_temp}°C")),
        "pressure": primary.get("pressure", secondary.get("pressure", "1013 hPa")),
        "uv_index": primary.get("uv_index", secondary.get("uv_index", "--")),
        "precip": primary.get("precip", secondary.get("precip", "0 mm")),
        "condition": primary["condition"],
        "icon": primary["icon"],
        "humidity": primary["humidity"],
        "wind": primary["wind"],
        "updated": datetime.now().strftime("%H:%M")
    }

def main():
    provider = sys.argv[1].lower() if len(sys.argv) > 1 else "openmeteo"
    location = sys.argv[2] if len(sys.argv) > 2 else ""

    geo = None
    if provider in ("openmeteo", "metno", "aggregator"):
        geo = detect_geo(location)

    try:
        if provider == "openmeteo":
            result = fetch_openmeteo(geo)
        elif provider == "wttr":
            result = fetch_wttr(location)
        elif provider == "metno":
            result = fetch_metno(geo)
        elif provider == "aggregator":
            result = fetch_aggregator(location, geo)
        else:
            result = fetch_openmeteo(geo)
        print(json.dumps(result))
    except Exception as e:
        # Fallback to wttr if openmeteo failed, or openmeteo if wttr failed
        try:
            if provider != "wttr":
                fallback = fetch_wttr(location)
                fallback["providerName"] = f"{fallback['providerName']} (Fallback)"
                print(json.dumps(fallback))
                return
        except Exception:
            pass

        print(json.dumps({
            "success": False,
            "error": str(e),
            "provider": provider
        }))

if __name__ == "__main__":
    main()
